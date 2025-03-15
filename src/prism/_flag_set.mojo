from collections import Optional
from collections.list import _ListIter
from collections.dict import Dict, DictEntry
from collections.string import StaticString, StringSlice
from utils import Variant
from memory import Pointer, Span
import os
from prism.flag import Flag, FlagActionFn, FType
from prism._util import string_to_bool, split
from prism._flag_parser import FlagParser
from prism._flag_group import validate_required_flag_group, validate_one_required_flag_group, validate_mutually_exclusive_flag_group


alias FlagVisitorFn = fn (Flag) capturing -> None
"""Function perform some action while visiting all flags."""
alias FlagVisitorRaisingFn = fn (Flag) capturing raises -> None
"""Function perform some action while visiting all flags. Can raise."""


# Flag Group annotations
@value
struct Annotation:
    var value: String

    # Individual flag annotations
    alias REQUIRED = Self("REQUIRED")

    # Flag Group annotations
    alias REQUIRED_AS_GROUP = Self("REQUIRED_AS_GROUP")
    alias ONE_REQUIRED = Self("ONE_REQUIRED")
    alias MUTUALLY_EXCLUSIVE = Self("MUTUALLY_EXCLUSIVE")

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    
    fn __ne__(self, other: Self) -> Bool:
        return self.value != other.value


@value
struct FlagSet(Writable, Stringable, Boolable):
    """A set of flags."""

    var flags: List[Flag]
    """The flags in the set."""

    @implicit
    fn __init__(out self, flags: List[Flag] = List[Flag]()):
        """Initializes a new FlagSet."""
        self.flags = flags
    
    fn __bool__(self) -> Bool:
        return Bool(self.flags)
    
    fn __len__(self) -> Int:
        return len(self.flags)
    
    fn __iter__(ref self) -> _ListIter[Flag, False, __origin_of(self.flags)]:
        return self.flags.__iter__()
    
    fn append(mut self, flag: Flag):
        """Adds a flag to the flag set.

        Args:
            flag: The flag to add to the flag set.

        """
        self.flags.append(flag)
    
    fn extend(mut self, other: FlagSet):
        """Adds a flag to the flag set.

        Args:
            other: The flag to add to the flag set.

        """
        self.flags.extend(other.flags)
    
    fn __str__(self) -> String:
        return String.write(self)
    
    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        """Writes the flag set to a writer.

        Args:
            writer: The writer to write the flag set to.
        """
        writer.write(self.flags.__str__())

    fn set_annotation[annotation: Annotation](mut self, name: String, value: String) raises -> None:
        """Sets an annotation for a flag.

        Args:
            name: The name of the flag to set the annotation for.
            value: The value of the annotation.

        Raises:
            Error: If setting the value for the annotation fails.
        """
        # Annotation value can be a concatenated string of values.
        # Why? Because we can have multiple required groups of flags for example.
        # So each value of the list for the annotation can be a group of flag names.
        var flag: Pointer[Flag, __origin_of(self.flags)]
        try:
            flag = self.lookup(name)
        except e:
            print(e, file=2)
            raise Error("FlagSet.set_annotation: Failed to set flag, {}, with the following annotation: {}".format(name, annotation.value))
        
        try:
            flag[].annotations[annotation.value].append(value)
        except:
            flag[].annotations[annotation.value] = List[String](value)

    fn from_args[origin: Origin](mut self, arguments: Span[StaticString, origin]) raises -> Span[StaticString, origin]:
        """Parses flags and args from the args passed via the command line and adds them to their appropriate collections.

        Args:
            arguments: The arguments passed via the command line.

        Returns:
            The remaining arguments after parsing out flags.

        Raises:
            Error: If a flag is not recognized.
        """
        var parser = FlagParser()
        # var remaining_args = List[StaticString](capacity=len(arguments))
        while parser.index < len(arguments):
            var argument = arguments[parser.index]

            # Positional argument
            if not argument.startswith("-", 0, 1):
                # remaining_args.append(argument)
                parser.index += 1
                continue

            var name: String
            var value: String
            var increment_by = 0

            # Full flag
            if argument.startswith("--", 0, 2):
                name, value, increment_by = parser.parse_flag(argument, arguments, self)
            # Shorthand flag
            elif argument.startswith("-", 0, 1):
                name, value, increment_by = parser.parse_shorthand_flag(argument, arguments, self)
            else:
                raise Error("Expected a flag but found: ", argument)

            # Set the value of the flag.
            var flag = self.lookup(name)
            if not flag[].changed:
                flag[].set(value)
            else:
                flag[].value.value().write(" ", value)
            parser.index += increment_by

        # If flags are not set, check if they can be set from an environment variable or from a file.
        # Set it from that value if there is one available.
        for flag in self:
            if not flag[].value:
                if flag[].environment_variable:
                    value = os.getenv(flag[].environment_variable.value())
                    if value != "":
                        flag[].set(value)
                elif flag[].file_path:
                    with open(os.path.expanduser(flag[].file_path.value()), "r") as f:
                        flag[].set(f.read())

        return arguments[parser.index:]

    fn names(self) -> List[String]:
        """Returns a list of names of all flags in the flag set.

        Returns:
            A list of names of all flags in the flag set.
        """
        var result = List[String](capacity=len(self.flags))
        for flag in self.flags:
            result.append(flag[].name)
        return result^

    fn shorthands(self) -> List[String]:
        """Returns a list of shorthands of all flags in the flag set.

        Returns:
            A list of shorthands of all flags in the flag set.
        """
        var result = List[String](capacity=len(self.flags))
        for flag in self.flags:
            if flag[].shorthand:
                result.append(flag[].shorthand)
        return result^

    fn visit_all[visitor: FlagVisitorFn](self) -> None:
        """Visits all flags in the flag set.

        Parameters:
            visitor: The visitor function to call for each flag.
        """
        for flag in self.flags:
            visitor(flag[])

    fn visit_all[visitor: FlagVisitorRaisingFn](self) raises -> None:
        """Visits all flags in the flag set.

        Parameters:
            visitor: The visitor function to call for each flag.

        Raises:
            Error: If the visitor raises an error.
        """
        for flag in self.flags:
            visitor(flag[])

    fn validate_required_flags(self) raises -> None:
        """Validates all required flags are present and returns an error otherwise.

        Raises:
            Error: If a required flag is not set.
        """
        var missing_flag_names = List[String]()

        @parameter
        fn check_required_flag(flag: Flag) -> None:
            if flag.required and not flag.changed:
                missing_flag_names.append(flag.name)

        self.visit_all[check_required_flag]()
        if len(missing_flag_names) > 0:
            raise Error("Required flag(s): " + missing_flag_names.__str__() + " not set.")

    fn lookup(ref self, name: String) raises -> Pointer[Flag, __origin_of(self.flags)]:
        """Returns an mutable or immutable Pointer to a Flag with the given name.
        Mutable if FlagSet is mutable, immutable if FlagSet is immutable.

        Args:
            name: The name of the Flag to lookup.

        Returns:
            Optional Pointer to the Flag.

        Raises:
            Error: If the Flag is not found.
        """
        for flag in self.flags:
            if flag[].name == name:
                return Pointer.address_of(flag[])

        raise Error("FlagNotFoundError: Could not find the following flag: ", name)

    fn lookup[type: FType](ref self, name: String) raises -> Pointer[Flag, __origin_of(self.flags)]:
        """Returns an mutable or immutable Pointer to a Flag with the given name.
        Mutable if FlagSet is mutable, immutable if FlagSet is immutable.

        Parameters:
            type: The type of the Flag to lookup.

        Args:
            name: The name of the Flag to lookup.

        Returns:
            Optional Pointer to the Flag.

        Raises:
            Error: If the Flag is not found.
        """
        for flag in self.flags:
            if flag[].name == name and flag[].type == type:
                return Pointer.address_of(flag[])

        raise Error("FlagNotFoundError: Could not find the following flag: ", name)

    fn lookup_name(self, shorthand: StringSlice) raises -> String:
        """Returns the name of a flag given its shorthand.

        Args:
            shorthand: The shorthand of the flag to lookup.

        Returns:
            The name of the flag.

        Raises:
            Error: If the flag is not found.
        """
        for flag in self.flags:
            if flag[].shorthand and flag[].shorthand.as_string_slice() == shorthand:
                return flag[].name

        raise Error("FlagNotFoundError: Could not find the following flag shorthand: ", shorthand)

    fn has_all_flags(self, flag_names: List[String]) -> Bool:
        """Checks if all flags are defined in the flag set.

        Args:
            flag_names: The names of the flags to check for.

        Returns:
            True if all flags are defined, False otherwise.
        """
        var names = self.names()
        for name in flag_names:
            if name[] not in names:
                return False
        return True

    fn process_group_annotations[annotation: Annotation](
        self,
        flag: Flag,
        mut group_status: Dict[String, Dict[String, Bool]],
    ) raises -> None:
        """Processes a flag for a group annotation.

        Parameters:
            annotation: The annotation to check for.

        Args:
            flag: The flag to process.
            group_status: The status of the flag groups.

        Raises:
            Error: If an error occurred while processing the flag.
        """
        var fg_annotations = flag.annotations.get(annotation.value, List[String]())
        if not fg_annotations:
            return

        for group in fg_annotations:
            if len(group_status.get(group[], Dict[String, Bool]())) == 0:
                var flag_names = group[].split(sep=" ")

                # Only consider this flag group at all if all the flags are defined.
                if not self.has_all_flags(flag_names):
                    continue

                for name in flag_names:
                    var entry = Dict[String, Bool]()
                    entry[name[]] = False
                    group_status[group[]] = entry

            # If flag.changed = True, then it had a value set on it.
            try:
                group_status[group[]][flag.name] = flag.changed
            except e:
                raise Error(
                    "process_group_annotations: Failed to set group status for annotation {}: {}.".format(
                        annotation.value, e
                    )
                )

    fn validate_flag_groups(self) raises -> None:
        """Validates the status of flag groups.
        Checks for flags annotated with the `REQUIRED_AS_GROUP`, `ONE_REQUIRED`, or `MUTUALLY_EXCLUSIVE` annotations.
        Then validates if the flags in the group are set correctly to satisfy the annotation.

        Raises:
            Error: If an error occurred while validating the flag groups.
        """
        var group_status = Dict[String, Dict[String, Bool]]()
        var one_required_group_status = Dict[String, Dict[String, Bool]]()
        var mutually_exclusive_group_status = Dict[String, Dict[String, Bool]]()

        @parameter
        fn flag_checker(flag: Flag) raises -> None:
            self.process_group_annotations[Annotation.REQUIRED_AS_GROUP](flag, group_status)
            self.process_group_annotations[Annotation.ONE_REQUIRED](flag, one_required_group_status)
            self.process_group_annotations[Annotation.MUTUALLY_EXCLUSIVE](flag, mutually_exclusive_group_status)

        self.visit_all[flag_checker]()

        # Validate required flag groups
        validate_required_flag_group(group_status)
        validate_one_required_flag_group(one_required_group_status)
        validate_mutually_exclusive_flag_group(mutually_exclusive_group_status)