from std import os
from std.collections.dict import DictEntry
from std.collections.list import _ListIter

from prism._flag_group import (
    validate_mutually_exclusive_flag_group,
    validate_one_required_flag_group,
    validate_required_flag_group,
)
from prism._flag_parser import FlagParser, _is_flag
from prism.flag import Flag, FlagActionFn, Annotation
from prism.opt_type import OptType
from prism.suggest import suggest_name
from prism.value import FromValue, LIST_SEPARATOR


comptime FlagVisitorFn = def (Flag) thin -> None
"""Function perform some action while visiting all flags."""
comptime FlagVisitorRaisingFn = def (Flag) raises thin -> None
"""Function perform some action while visiting all flags. Can raise."""


@fieldwise_init
struct ParserState(TrivialRegisterPassable, Writable, Equatable):
    """State of the parser when parsing flags from the command line."""
    var value: UInt8
    """Internal value representing the state of the parser."""
    comptime FIND_FLAG = Self(0)
    """State when the parser is trying to find the next flag in the arguments."""
    comptime PARSE_FLAG = Self(1)
    """State when the parser is trying to parse a flag that starts with '--' and is in the format of either '--flag=value' or '--flag value'."""
    comptime PARSE_SHORTHAND_FLAG = Self(2)
    """State when the parser is trying to parse a shorthand flag that starts with '-' and can be in the format of either '-f=value', '-f value', or a combination of multiple bool shorthand flags like '-abc' which is equivalent to '-a -b -c'."""


def _set_flag_value(mut flag: Flag, value: StringSpan) -> None:
    """Sets a flag parsed from the command line.

    Args:
        flag: The flag to set. The parser returns its index, so it is reached without a lookup.
        value: The value to set.
    """
    if not flag.changed:
        flag.set(value)
    elif flag.type.takes_multiple_values():
        # Repeating a list or array flag accumulates: `-H "A: 1" -H "B: 2"` is a two-element list.
        flag.value.value().write(LIST_SEPARATOR, value)
    else:
        # Repeating a scalar flag replaces. Appending would turn `--name a --name b` into
        # the single value "a b" rather than letting the last one win.
        flag.set(value)

def _split_environment_value(flag: Flag, text: StringSpan) -> String:
    """Splits a value from an environment variable into list elements.

    Args:
        flag: The flag the value is for.
        text: The value.

    Returns:
        The value with its elements joined by `LIST_SEPARATOR`, or unchanged when the flag has no
        `value_separator`.

    #### Notes:
    - Empty elements are dropped, so a trailing or doubled separator adds nothing.
    """
    if not flag.value_separator:
        return String(text)

    ref separator = flag.value_separator.value()
    var elements = List[String]()
    for part in text.split(separator):
        var element = String(part)
        if element:
            elements.append(element^)
    return LIST_SEPARATOR.join(elements)


@fieldwise_init
struct _FlagSetIter[mut: Bool, //, origin: Origin[mut=mut]](Copyable, Iterator):
    comptime Element = Flag
    comptime IteratorType[
        iterable_mut: Bool, //, iterable_origin: Origin[mut=iterable_mut]
    ]: Iterator = Self
    var iter: _ListIter[Flag, Self.origin]

    def __iter__(ref self) -> Self.IteratorType[origin_of(self)]:
        return self.copy()

    def __next__(mut self) raises StopIteration -> ref[Self.origin] Self.Element:
        return self.iter.__next__()

    @always_inline
    def bounds(self) -> Tuple[Int, Optional[Int]]:
        return self.iter.bounds()



struct FlagSet(Boolable, Copyable, Sized, Writable, Iterable):
    """A set of flags."""

    comptime Element = Flag
    comptime IteratorType[
        iterable_mut: Bool, //, iterable_origin: Origin[mut=iterable_mut]
    ]: Iterator = _ListIter[Flag, iterable_origin, True]

    var flags: List[Flag]
    """The flags in the set."""

    @implicit
    def __init__(out self, var flags: List[Flag] = List[Flag]()):
        """Initializes a new FlagSet.

        Args:
            flags: The flags to initialize the flag set with. Defaults to an empty list.
        """
        self.flags = flags^

    @always_inline
    def __init__(out self, var *values: Flag, __list_literal__: NoneType):
        """Constructs a list from the given values.

        Args:
            values: The values to populate the list with.
            __list_literal__: Tell Mojo to use this method for list literals.
        """
        self.flags = List[Flag](*values^, __list_literal__=__list_literal__)

    def __bool__(self) -> Bool:
        return Bool(self.flags)

    def __len__(self) -> Int:
        return len(self.flags)

    def __iter__(ref self) -> Self.IteratorType[origin_of(self)]:
        # TODO: Fix up the origins here.
        return rebind[Self.IteratorType[origin_of(self)]](iter(self.flags))

    def append(mut self, var flag: Flag):
        """Adds a flag to the flag set.

        Args:
            flag: The flag to add to the flag set.

        """
        self.flags.append(flag^)

    def extend(mut self, deinit other: FlagSet):
        """Adds a flag to the flag set.

        Args:
            other: The flag to add to the flag set.
        """
        self.flags.extend(other.flags^)

    def write_to(self, mut writer: Some[Writer]) -> None:
        """Writes the flag set to a writer.

        Args:
            writer: The writer to write the flag set to.
        """
        writer.write(self.flags)

    def set_annotation[annotation: Annotation](mut self, name: ImmStringSpan, var value: String) raises -> None:
        """Sets an annotation for a flag.

        Parameters:
            annotation: The annotation to set for the flag.

        Args:
            name: The name of the flag to set the annotation for.
            value: The value of the annotation.

        Raises:
            Error: If setting the value for the annotation fails.
        """
        # Annotation value can be a concatenated string of values.
        # Why? Because we can have multiple required groups of flags for example.
        # So each value of the list for the annotation can be a group of flag names.
        var flag = self.lookup(name)
        if not flag:
            raise Error(
                t"Cannot mark `--{name}` as {annotation}: the flag is not defined."
            )

        try:
            flag.value()[].annotations[annotation].append(value^)
        except:
            flag.value()[].annotations[annotation] = [value^]

    def from_args[origin: ImmOrigin, //](mut self, arguments: Span[String, origin]) raises -> List[String]:
        """Parses flags and args from the args passed via the command line and adds them to their appropriate collections.

        Args:
            arguments: The arguments passed via the command line.

        Returns:
            The remaining arguments after parsing out flags.

        Raises:
            Error: If a flag is not recognized.
        """
        var remaining_args = List[String](capacity=len(arguments))
        var state = ParserState.FIND_FLAG
        var parser = FlagParser(arguments)
        while parser.index < len(arguments):
            ref argument = arguments[parser.index]

            # Find the next flag in the set of arguments.
            if state == ParserState.FIND_FLAG:
                # A bare `--` ends flag parsing. Everything after it is positional, even when it
                # looks like a flag, which is how a value such as `--weird` is passed through.
                if argument == "--":
                    parser.index += 1
                    while parser.index < len(arguments):
                        remaining_args.append(arguments[parser.index])
                        parser.index += 1
                    break

                # Positional argument, including a bare `-` and negative numbers.
                if not _is_flag(argument, self):
                    parser.index += 1
                    remaining_args.append(argument)
                    continue

                if argument.startswith("--", 0, 2):
                    state = ParserState.PARSE_FLAG
                else:
                    state = ParserState.PARSE_SHORTHAND_FLAG

            # Parse out a flag and set the value on the flag.
            elif state == ParserState.PARSE_FLAG:
                var result = parser.parse_flag(argument, self)
                _set_flag_value(self.flags[result.index], result.value)
                parser.index += result.increment
                state = ParserState.FIND_FLAG

            # Parse out shorthand flag(s) and set the value on the flag(s).
            elif state == ParserState.PARSE_SHORTHAND_FLAG:
                var result = parser.parse_shorthand_flag(argument, self)
                for i in range(len(result.indices)):
                    _set_flag_value(self.flags[result.indices[i]], result.values[i])
                parser.index += result.increment
                state = ParserState.FIND_FLAG

        # Fill flags not passed on the command line from their environment variable.
        for ref flag in self:
            if flag.value or not flag.environment_variable:
                continue

            var value = os.getenv(flag.environment_variable.value())
            if value != "":
                flag.set(_split_environment_value(flag, value))
                flag.from_environment = True

        return remaining_args^

    def names(self) -> List[String]:
        """Returns a list of names of all flags in the flag set.

        Returns:
            A list of names of all flags in the flag set.
        """
        return [ flag.name for flag in self.flags ]

    def shorthands(self) -> List[String]:
        """Returns a list of shorthands of all flags in the flag set.

        Returns:
            A list of shorthands of all flags in the flag set.
        """
        return [ flag.shorthand for flag in self.flags if flag.shorthand ]

    def visit_all[visitor: FlagVisitorFn](self) -> None:
        """Visits all flags in the flag set.

        Parameters:
            visitor: The visitor function to call for each flag.
        """
        for flag in self.flags:
            visitor(flag)

    def visit_all[visitor: FlagVisitorRaisingFn](self) raises -> None:
        """Visits all flags in the flag set.

        Parameters:
            visitor: The visitor function to call for each flag.

        Raises:
            Error: If the visitor raises an error.
        """
        for flag in self.flags:
            visitor(flag)

    def validate_required_flags(self) raises -> None:
        """Validates all required flags are present and returns an error otherwise.

        Raises:
            Error: If a required flag is not set.
        """
        var missing = List[String]()
        for flag in self:
            if flag.required and not flag.changed:
                missing.append(String(t"--{flag.name}"))

        if missing:
            raise Error(t"Missing required flag(s): {', '.join(missing)}.")

    def validate_flag_values(self) raises -> None:
        """Validates that every flag given a value can be read as its declared type.

        Raises:
            Error: Naming the first flag whose value does not parse.

        #### Notes:
        - Without this, `--port abc` parsed cleanly and only failed when `run` called `get`, after
          the pre-run hooks had already had their side effects, and without naming the flag.
        - Defaults are not checked. `Flag.new` renders them from a typed value, so they parse.
        """
        for flag in self.flags:
            if not flag.value:
                continue

            try:
                flag.parse_check(flag.value.value())
            except e:
                raise Error(t"Invalid value for flag `--{flag.name}`: {e}")

    def _index(self, name: ImmStringSpan) -> Int:
        """Returns the index of the flag with the given name.

        Args:
            name: The name of the flag.

        Returns:
            The flag's index in `flags`, or -1 if no flag has that name.

        #### Notes:
        - The parser hands this index back so the value can be set without scanning again.
        """
        for i in range(len(self.flags)):
            if self.flags[i].name == name:
                return i
        return -1

    def _shorthand_index(self, shorthand: ImmStringSpan) -> Int:
        """Returns the index of the flag with the given shorthand.

        Args:
            shorthand: The shorthand of the flag.

        Returns:
            The flag's index in `flags`, or -1 if no flag has that shorthand.
        """
        for i in range(len(self.flags)):
            if self.flags[i].shorthand == shorthand:
                return i
        return -1

    def _longest_shorthand_length(self) -> Int:
        """Returns the length of the longest shorthand defined, in codepoints.

        Returns:
            The length, or 0 when no flag has a shorthand.
        """
        var longest = 0
        for flag in self.flags:
            if flag.shorthand:
                longest = max(longest, flag.shorthand.count_codepoints())
        return longest

    def lookup(ref self, name: ImmStringSpan) -> Optional[Pointer[Flag, origin_of(self.flags)]]:
        """Returns an mutable or immutable Pointer to a Flag with the given name.
        Mutable if FlagSet is mutable, immutable if FlagSet is immutable.

        Args:
            name: The name of the Flag to lookup.

        Returns:
            Optional Pointer to the Flag.
        """
        for ref flag in self.flags:
            if flag.name == name:
                return Pointer(to=flag)

        return None

    def lookup[T: AnyType](ref self, name: ImmStringSpan) -> Optional[Pointer[Flag, origin_of(self.flags)]]:
        """Returns an mutable or immutable Pointer to a Flag with the given name.
        Mutable if FlagSet is mutable, immutable if FlagSet is immutable.

        Parameters:
            T: The type of the Flag to lookup.

        Args:
            name: The name of the Flag to lookup.

        Returns:
            Optional Pointer to the Flag.
        """
        comptime assert conforms_to(T, FromValue), t"{reflect[T].name()} does not implement `FromValue`."
        comptime opt_type = OptType(reflect[T].name())
        for ref flag in self.flags:
            if flag.name == name and flag.type == opt_type:
                return Pointer(to=flag)

        return None

    def lookup_shorthand(ref self, name: ImmStringSpan) -> Optional[Pointer[Flag, origin_of(self.flags)]]:
        """Returns an mutable or immutable Pointer to a Flag with the given name.
        Mutable if FlagSet is mutable, immutable if FlagSet is immutable.

        Args:
            name: The shorthand name of the Flag to lookup.

        Returns:
            Optional Pointer to the Flag.
        """
        for ref flag in self.flags:
            if flag.shorthand == name:
                return Pointer(to=flag)

        return None

    def lookup_shorthand[T: AnyType](ref self, name: ImmStringSpan) -> Optional[Pointer[Flag, origin_of(self.flags)]]:
        """Returns an mutable or immutable Pointer to a Flag with the given name.
        Mutable if FlagSet is mutable, immutable if FlagSet is immutable.

        Parameters:
            T: The type of the Flag to lookup.

        Args:
            name: The shorthand name of the Flag to lookup.

        Returns:
            Optional Pointer to the Flag.
        """
        comptime assert conforms_to(T, FromValue), t"{reflect[T].name()} does not implement `FromValue`."
        comptime opt_type = OptType(reflect[T].name())
        for ref flag in self.flags:
            if flag.shorthand == name and flag.type == opt_type:
                return Pointer(to=flag)

        return None

    def lookup_name(self, shorthand: ImmStringSpan) -> Optional[String]:
        """Returns the name of a flag given its shorthand.

        Args:
            shorthand: The shorthand of the flag to lookup.

        Returns:
            The name of the flag.
        """
        for flag in self.flags:
            if flag.shorthand and flag.shorthand == shorthand:
                return flag.name

        return None

    def has_all_flags[origin: ImmOrigin, //](self, flag_names: Span[String, origin]) -> Bool:
        """Checks if all flags are defined in the flag set.

        Args:
            flag_names: The names of the flags to check for.

        Returns:
            True if all flags are defined, False otherwise.
        """
        # `lookup` scans without allocating; `self.names()` copies every flag name into a new list,
        # and this runs once per flag group.
        for name in flag_names:
            if not self.lookup(name):
                return False
        return True

    def process_group_annotations[
        annotation: Annotation, *, command_line_only: Bool = False
    ](self, flag: Flag, mut group_status: Dict[String, Dict[String, Bool]]) raises -> None:
        """Processes a flag for a group annotation.

        Parameters:
            annotation: The annotation to check for.
            command_line_only: Count a flag as set only when its value came from the command line,
                not from its environment variable.

        Args:
            flag: The flag to process.
            group_status: The status of the flag groups.

        Raises:
            Error: If an error occurred while processing the flag.
        """
        var fg_annotations = flag.annotations.get(annotation, [])
        if not fg_annotations:
            return

        for group in fg_annotations:
            if len(group_status.get(group, {})) == 0:
                var flag_names = [String(name) for name in group.split(sep=" ")]

                # Only consider this flag group at all if all the flags are defined.
                if not self.has_all_flags(flag_names):
                    continue

                # Seed every member of the group as unset in one dict. Building a fresh dict per
                # name and assigning it each time leaves only the last name seeded, so a member
                # that carries the annotation but is never itself visited goes unaccounted for.
                group_status[group] = {name^: False for var name in flag_names^}

            # If flag.changed = True, then it had a value set on it.
            try:
                group_status[group][flag.name] = flag.changed and not (
                    command_line_only and flag.from_environment
                )
            except e:
                raise Error(
                    t"Failed to check the {annotation} group containing `--{flag.name}`: ", e
                )

    def validate_flag_groups(self) raises -> None:
        """Validates the status of flag groups.
        Checks for flags annotated with the `REQUIRED_AS_GROUP`, `ONE_REQUIRED`, or `MUTUALLY_EXCLUSIVE` annotations.
        Then validates if the flags in the group are set correctly to satisfy the annotation.

        Raises:
            Error: If an error occurred while validating the flag groups.
        """
        var group_status = Dict[String, Dict[String, Bool]]()
        var one_required_group_status = Dict[String, Dict[String, Bool]]()
        var mutually_exclusive_group_status = Dict[String, Dict[String, Bool]]()
        var mutually_exclusive_command_line_status = Dict[String, Dict[String, Bool]]()

        for flag in self.flags:
            self.process_group_annotations[Annotation.REQUIRED_AS_GROUP](flag, group_status)
            self.process_group_annotations[Annotation.ONE_REQUIRED](flag, one_required_group_status)
            self.process_group_annotations[Annotation.MUTUALLY_EXCLUSIVE](flag, mutually_exclusive_group_status)
            self.process_group_annotations[Annotation.MUTUALLY_EXCLUSIVE, command_line_only=True](
                flag, mutually_exclusive_command_line_status
            )

        # The command line overrides the environment. When a member of a mutually exclusive group
        # was passed on the command line, only command line values count, so `--password x` is not
        # rejected because a `TOKEN` variable happens to be set. With none passed, values from the
        # environment still conflict with each other.
        for entry in mutually_exclusive_command_line_status.items():
            for member in entry.value.values():
                if member:
                    mutually_exclusive_group_status[entry.key] = entry.value.copy()
                    break

        # Validate required flag groups
        validate_required_flag_group(group_status)
        validate_one_required_flag_group(one_required_group_status)
        validate_mutually_exclusive_flag_group(mutually_exclusive_group_status)

    def get[T: AnyType](self, name: ImmStringSpan) raises -> Optional[T]:
        """Returns the value of a flag as a `T`. If it isn't set, then return the default value.

        Parameters:
            T: The type to read the flag as. Must conform to `FromValue`.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `T`, or `None` if no flag of that name *and type* is defined,
            or it has neither a value nor a default.

        Raises:
            Error: If the flag's value cannot be read as a `T`.

        #### Notes:
        - `T` is matched against the flag's declared `OptType`, so asking for the wrong type reads
          as `None` rather than as a parse failure. `get[Int]("region")` on a `String` flag finds
          nothing, the same as asking for a name that was never declared.
        """
        comptime assert conforms_to(T, FromValue), t"{reflect[T].name()} does not implement `FromValue`."
        var flag = self.lookup[T](name)
        if not flag:
            return None

        # Parse straight from the stored text. `value_or_default` returns a copy of it, which cost an
        # allocation on every call.
        ref found = flag.value()[]
        if found.value:
            return T.from_value(found.value.value())
        if found.default:
            return T.from_value(found.default.value())
        return None

    def require[T: AnyType](self, name: ImmStringSpan) raises -> T:
        """Returns the value of a flag as a `T`, raising where `get` would return `None`.

        ```mojo
        var port = flags.require[Int]("port")
        ```

        Parameters:
            T: The type to read the flag as. Must conform to `FromValue`.

        Args:
            name: The name of the flag.

        Returns:
            The flag's value, or its default when it was not set.

        Raises:
            Error: If no flag has that name, the flag holds a different type, it has neither a
                value nor a default, or its value cannot be read as a `T`.

        #### Notes:
        - `get` reads a misspelled name, or the wrong type, as `None`, the same as a flag that was
          simply not passed, so the mistake surfaces far from its cause if at all. `require` names
          it, and suggests the closest flag name for a misspelling.
        """
        comptime assert conforms_to(T, FromValue), t"{reflect[T].name()} does not implement `FromValue`."
        var index = self._index(name)
        if index == -1:
            var message = String(t"No flag named `--{name}` is defined.")
            var suggestion = suggest_name(Span(self.names()), name)
            if suggestion:
                message.write(t" Did you mean `--{suggestion}`?")
            raise Error(message)

        ref flag = self.flags[index]
        comptime expected = OptType(reflect[T].name())
        if flag.type != expected:
            raise Error(t"Flag `--{name}` holds {flag.type.display_name()}, not {expected.display_name()}.")

        if flag.value:
            return T.from_value(flag.value.value())
        if flag.default:
            return T.from_value(flag.default.value())
        raise Error(t"Flag `--{name}` was not set and has no default.")
