from std import os
from std.collections.dict import DictEntry
from std.collections.list import _ListIter

from prism._flag_group import (
    validate_mutually_exclusive_flag_group,
    validate_one_required_flag_group,
    validate_required_flag_group,
)
from prism._flag_parser import FlagParser
from prism.flag import Flag, FlagActionFn, Annotation
from prism.opt_type import OptType
from prism.value import FromValue


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
                t"FlagSet.set_annotation: Failed to set flag, {name}, with the following annotation: {annotation}, because the flag could not be found."
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
        @parameter
        def set_flag_value(mut flags: FlagSet, name: ImmStringSpan, value: StringSpan) raises -> None:
            # Set the value of the flag.
            var flag = flags.lookup(name)
            if not flag:
                raise Error(
                    t"FlagSet.from_args: Failed to set flag, {name}, with value: {value}. Flag could not be found."
                )
            if not flag.value()[].changed:
                flag.value()[].set(value)
            elif flag.value()[].type == OptType.List:
                # Repeating a list flag accumulates: `--tags a --tags b` is a two-element list.
                flag.value()[].value.value().write(" ", value)
            else:
                # Repeating a scalar flag replaces. Appending would turn `--name a --name b` into
                # the single value "a b" rather than letting the last one win.
                flag.value()[].set(value)

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

                # Positional argument
                if not argument.startswith("-", 0, 1):
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
                set_flag_value(self, result.name, result.value)
                parser.index += result.increment
                state = ParserState.FIND_FLAG

            # Parse out shorthand flag(s) and set the value on the flag(s).
            elif state == ParserState.PARSE_SHORTHAND_FLAG:
                var result = parser.parse_shorthand_flag(argument, self)
                for name in result.names:
                    set_flag_value(self, name, result.value)
                parser.index += result.increment
                state = ParserState.FIND_FLAG

        # If flags are not set, check if they can be set from an environment variable or from a file.
        # Set it from that value if there is one available.
        for ref flag in self:
            if not flag.value:
                if flag.environment_variable:
                    var value = os.getenv(flag.environment_variable.value())
                    if value != "":
                        flag.set(value)
                elif flag.file_path:
                    with open(os.path.expanduser(flag.file_path.value()), "r") as f:
                        flag.set(f.read())

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
        var missing_flag_names = List[String]()
        for flag in self:
            if flag.required and not flag.changed:
                missing_flag_names.append(flag.name)

        if len(missing_flag_names) > 0:
            raise Error(t"Required flag(s): {missing_flag_names} not set.")

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

    def lookup[type: OptType](ref self, name: ImmStringSpan) -> Optional[Pointer[Flag, origin_of(self.flags)]]:
        """Returns an mutable or immutable Pointer to a Flag with the given name.
        Mutable if FlagSet is mutable, immutable if FlagSet is immutable.

        Parameters:
            type: The type of the Flag to lookup.

        Args:
            name: The name of the Flag to lookup.

        Returns:
            Optional Pointer to the Flag.
        """
        for ref flag in self.flags:
            if flag.name == name and flag.type == type:
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

    def lookup_shorthand[type: OptType](ref self, name: ImmStringSpan) -> Optional[Pointer[Flag, origin_of(self.flags)]]:
        """Returns an mutable or immutable Pointer to a Flag with the given name.
        Mutable if FlagSet is mutable, immutable if FlagSet is immutable.

        Parameters:
            type: The type of the Flag to lookup.

        Args:
            name: The shorthand name of the Flag to lookup.

        Returns:
            Optional Pointer to the Flag.
        """
        for ref flag in self.flags:
            if flag.shorthand == name and flag.type == type:
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
        annotation: Annotation
    ](self, flag: Flag, mut group_status: Dict[String, Dict[String, Bool]]) raises -> None:
        """Processes a flag for a group annotation.

        Parameters:
            annotation: The annotation to check for.

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
                var entry: Dict[String, Bool] = {}
                for var name in flag_names^:
                    entry[name^] = False
                group_status[group] = entry^

            # If flag.changed = True, then it had a value set on it.
            try:
                group_status[group][flag.name] = flag.changed
            except e:
                raise Error(
                    t"process_group_annotations: Failed to set group status for annotation {annotation.value}: ", e
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

        for flag in self.flags:
            self.process_group_annotations[Annotation.REQUIRED_AS_GROUP](flag, group_status)
            self.process_group_annotations[Annotation.ONE_REQUIRED](flag, one_required_group_status)
            self.process_group_annotations[Annotation.MUTUALLY_EXCLUSIVE](flag, mutually_exclusive_group_status)

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
        comptime assert conforms_to(T, FromValue), String(t"{reflect[T].name()} does not implement `FromValue`.")
        comptime opt_type = OptType(reflect[T].name())
        var flag = self.lookup[opt_type](name)
        if not flag:
            return None

        var result = flag.value()[].value_or_default()
        if not result:
            return None

        return T.from_value(result.value())
