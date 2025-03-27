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


@value
@register_passable("trivial")
struct ParserState:
    var value: UInt8
    alias FIND_FLAG = Self(0)
    alias PARSE_FLAG = Self(1)
    alias PARSE_SHORTHAND_FLAG = Self(2)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value
    
    fn __ne__(self, other: Self) -> Bool:
        return self.value != other.value


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
        var flag = self.lookup(name)
        if not flag:
            raise Error("FlagSet.set_annotation: Failed to set flag, {}, with the following annotation: {}".format(name, annotation.value))
        
        try:
            flag.value()[].annotations[annotation.value].append(value)
        except:
            flag.value()[].annotations[annotation.value] = List[String](value)

    fn from_args[origin: Origin](mut self, arguments: Span[StaticString, origin]) raises -> List[StaticString]:
        """Parses flags and args from the args passed via the command line and adds them to their appropriate collections.

        Args:
            arguments: The arguments passed via the command line.

        Returns:
            The remaining arguments after parsing out flags.

        Raises:
            Error: If a flag is not recognized.
        """
        @parameter
        fn set_flag_value(name: String, value: String) raises -> None:
            # Set the value of the flag.
            var flag = self.lookup(name)
            if not flag:
                raise Error("FlagSet.from_args: Failed to set flag, {}, with value: {}. Flag could not be found.".format(name, value))
            if not flag.value()[].changed:
                flag.value()[].set(value)
            else:
                flag.value()[].value.value().write(" ", value)

        var remaining_args = List[StaticString](capacity=len(arguments))
        var state = ParserState.FIND_FLAG
        var parser = FlagParser()
        while parser.index < len(arguments):
            var argument = arguments[parser.index]

            # Find the next flag in the set of arguments.
            if state == ParserState.FIND_FLAG:
                # Positional argument
                if not argument.startswith("-", 0, 1):
                    remaining_args.append(argument)
                    parser.index += 1
                    continue

                if argument.startswith("--", 0, 2):
                    state = ParserState.PARSE_FLAG
                else:
                    state = ParserState.PARSE_SHORTHAND_FLAG
            
            # Parse out a flag and set the value on the flag.
            elif state == ParserState.PARSE_FLAG:
                name, value, increment_by = parser.parse_flag(argument, arguments, self)
                set_flag_value(name, value)
                parser.index += increment_by
                state = ParserState.FIND_FLAG

            # Parse out shorthand flag(s) and set the value on the flag(s).
            elif state == ParserState.PARSE_SHORTHAND_FLAG:
                names, value, increment_by = parser.parse_shorthand_flag(argument, arguments, self)
                for name in names:
                    set_flag_value(name[], value)
                parser.index += increment_by
                state = ParserState.FIND_FLAG

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

        return remaining_args^

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

    fn lookup(ref self, name: StringSlice) -> Optional[Pointer[Flag, __origin_of(self.flags)]]:
        """Returns an mutable or immutable Pointer to a Flag with the given name.
        Mutable if FlagSet is mutable, immutable if FlagSet is immutable.

        Args:
            name: The name of the Flag to lookup.

        Returns:
            Optional Pointer to the Flag.
        """
        for flag in self.flags:
            if flag[].name.as_string_slice() == name:
                return Pointer.address_of(flag[])

        return None

    fn lookup[type: FType](ref self, name: StringSlice) -> Optional[Pointer[Flag, __origin_of(self.flags)]]:
        """Returns an mutable or immutable Pointer to a Flag with the given name.
        Mutable if FlagSet is mutable, immutable if FlagSet is immutable.

        Parameters:
            type: The type of the Flag to lookup.

        Args:
            name: The name of the Flag to lookup.

        Returns:
            Optional Pointer to the Flag.
        """
        for flag in self.flags:
            if flag[].name.as_string_slice() == name and flag[].type == type:
                return Pointer.address_of(flag[])

        return None
    
    fn lookup_shorthand(ref self, name: StringSlice) -> Optional[Pointer[Flag, __origin_of(self.flags)]]:
        """Returns an mutable or immutable Pointer to a Flag with the given name.
        Mutable if FlagSet is mutable, immutable if FlagSet is immutable.

        Args:
            name: The shorthand name of the Flag to lookup.

        Returns:
            Optional Pointer to the Flag.
        """
        for flag in self.flags:
            if flag[].shorthand.as_string_slice() == name:
                return Pointer.address_of(flag[])

        return None

    fn lookup_shorthand[type: FType](ref self, name: StringSlice) -> Optional[Pointer[Flag, __origin_of(self.flags)]]:
        """Returns an mutable or immutable Pointer to a Flag with the given name.
        Mutable if FlagSet is mutable, immutable if FlagSet is immutable.

        Parameters:
            type: The type of the Flag to lookup.

        Args:
            name: The shorthand name of the Flag to lookup.

        Returns:
            Optional Pointer to the Flag.
        """
        for flag in self.flags:
            if flag[].shorthand.as_string_slice() == name and flag[].type == type:
                return Pointer.address_of(flag[])

        return None

    fn lookup_name(self, shorthand: StringSlice) -> Optional[String]:
        """Returns the name of a flag given its shorthand.

        Args:
            shorthand: The shorthand of the flag to lookup.

        Returns:
            The name of the flag.
        """
        for flag in self.flags:
            if flag[].shorthand and flag[].shorthand.as_string_slice() == shorthand:
                return flag[].name
        
        return None

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
    
    fn get_string(self, name: String) -> Optional[String]:
        """Returns the value of a flag as a `String`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `String`.
        """
        var flag = self.lookup[FType.String](name)
        if not flag:
            return None
        
        return flag.value()[].value_or_default()

    fn get_bool(self, name: String) raises -> Optional[Bool]:
        """Returns the value of a flag as a `Bool`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Bool`.

        Raises:
            Error: If the flag is not found.
        """
        var flag = self.lookup[FType.Bool](name)
        if not flag:
            return None

        var result = flag.value()[].value_or_default()
        if not result:
            return None
        
        return string_to_bool(result.value())

    fn get_int[type: FType = FType.Int](self, name: String) raises -> Optional[Int]:
        """Returns the value of a flag as an `Int`. If it isn't set, then return the default value.

        Parameters:
            type: The type of the flag.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as an `Int`.

        Raises:
            Error: If the flag is not found.
        """
        constrained[
            type.is_int_type(),
            "type must be one of `Int`, `Int8`, `Int16`, `Int32`, `Int64`, `UInt`, `UInt8`, `UInt16`, `UInt32`, or `UInt64`. Received: " + type.value
        ]()
        var flag = self.lookup[type](name)
        if not flag:
            return None
        
        var result = flag.value()[].value_or_default()
        if not result:
            return None
        return atol(result.value())

    fn get_int8(self, name: String) raises -> Optional[Int8]:
        """Returns the value of a flag as a `Int8`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Int8`.

        Raises:
            Error: If the flag is not found.
        """
        var result = self.get_int[FType.Int8](name)
        if not result:
            return None
        return Int8(result.value())

    fn get_int16(self, name: String) raises -> Optional[Int16]:
        """Returns the value of a flag as a `Int16`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Int16`.

        Raises:
            Error: If the flag is not found.
        """
        var result = self.get_int[FType.Int16](name)
        if not result:
            return None
        return Int16(result.value())

    fn get_int32(self, name: String) raises -> Optional[Int32]:
        """Returns the value of a flag as a `Int32`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Int32`.

        Raises:
            Error: If the flag is not found.
        """
        var result = self.get_int[FType.Int32](name)
        if not result:
            return None
        return Int32(result.value())

    fn get_int64(self, name: String) raises -> Optional[Int64]:
        """Returns the value of a flag as a `Int64`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Int64`.

        Raises:
            Error: If the flag is not found.
        """
        var result = self.get_int[FType.Int64](name)
        if not result:
            return None
        return Int64(result.value())

    fn get_uint(self, name: String) raises -> Optional[UInt]:
        """Returns the value of a flag as a `UInt`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `UInt`.

        Raises:
            Error: If the flag is not found.
        """
        var result = self.get_int[FType.UInt](name)
        if not result:
            return None
        return UInt(result.value())

    fn get_uint8(self, name: String) raises -> Optional[UInt8]:
        """Returns the value of a flag as a `UInt8`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `UInt8`.

        Raises:
            Error: If the flag is not found.
        """
        var result = self.get_int[FType.UInt8](name)
        if not result:
            return None
        return UInt8(result.value())

    fn get_uint16(self, name: String) raises -> Optional[UInt16]:
        """Returns the value of a flag as a `UInt16`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `UInt16`.

        Raises:
            Error: If the flag is not found.
        """
        var result = self.get_int[FType.UInt16](name)
        if not result:
            return None
        return UInt16(result.value())

    fn get_uint32(self, name: String) raises -> Optional[UInt32]:
        """Returns the value of a flag as a `UInt32`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `UInt32`.

        Raises:
            Error: If the flag is not found.
        """
        var result = self.get_int[FType.UInt32](name)
        if not result:
            return None
        return UInt32(result.value())

    fn get_uint64(self, name: String) raises -> Optional[UInt64]:
        """Returns the value of a flag as a `UInt64`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `UInt64`.

        Raises:
            Error: If the flag is not found.
        """
        var result = self.get_int[FType.UInt64](name)
        if not result:
            return None
        return UInt64(result.value())
    
    fn get_float[type: FType](self, name: String) raises -> Optional[Float64]:
        """Returns the value of a flag as a `Float64`. If it isn't set, then return the default value.

        Parameters:
            type: The type of the flag.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Float64`.

        Raises:
            Error: If the flag is not found.
        """
        constrained[
            type.is_float_type(),
            "type must be one of `Float16`, `Float32`, `Float64`. Received: " + type.value
        ]()
        var flag = self.lookup[type](name)
        if not flag:
            return None

        var result = flag.value()[].value_or_default()
        if not result:
            return None
        return atof(result.value())

    fn get_float16(self, name: String) raises -> Optional[Float16]:
        """Returns the value of a flag as a `Float16`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Float16`.

        Raises:
            Error: If the flag is not found.
        """
        var result = self.get_float[FType.Float16](name)
        if not result:
            return None
        return result.value().cast[DType.float16]()

    fn get_float32(self, name: String) raises -> Optional[Float32]:
        """Returns the value of a flag as a `Float32`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Float32`.

        Raises:
            Error: If the flag is not found.
        """
        var result = self.get_float[FType.Float32](name)
        if not result:
            return None
        return result.value().cast[DType.float32]()

    fn get_float64(self, name: String) raises -> Optional[Float64]:
        """Returns the value of a flag as a `Float64`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Float64`.
            
        Raises:
            Error: If the flag is not found.
        """
        var result = self.get_float[FType.Float64](name)
        if not result:
            return None
        return result.value()

    fn _get_list[type: FType](self, name: String) raises -> Optional[List[String]]:
        """Returns the value of a flag as a `List[String]`. If it isn't set, then return the default value.

        Parameters:
            type: The type of the flag.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `List[String]`.

        Raises:
            Error: If the flag is not found.
        """
        constrained[
            type.is_list_type(),
            "type must be one of `StringList`, `IntList`, or `Float64List`. Received: " + type.value
        ]()
        var flag = self.lookup[type](name)
        if not flag:
            return None
        
        var result = flag.value()[].value_or_default()
        if not result:
            return None
        return result.value().split(sep=" ")

    fn get_string_list(self, name: String) raises -> Optional[List[String]]:
        """Returns the value of a flag as a `List[String]`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `List[String]`.

        Raises:
            Error: If the flag is not found.
        """
        var result = self._get_list[FType.StringList](name)
        if not result:
            return None
        return result.value()

    fn get_int_list(self, name: String) raises -> Optional[List[Int]]:
        """Returns the value of a flag as a `List[Int]`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `List[Int]`.

        Raises:
            Error: If the flag is not found.
        """
        var result = self._get_list[FType.IntList](name)
        if not result:
            return None
        
        var ints = List[Int](capacity=len(result.value()))
        for value in result.value():
            ints.append(atol(value[]))
        return ints^

    fn get_float64_list(self, name: String) raises -> Optional[List[Float64]]:
        """Returns the value of a flag as a `List[Float64]`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `List[Float64]`.

        Raises:
            Error: If the flag is not found.
        """
        var result = self._get_list[FType.Float64List](name)
        if not result:
            return None
        
        var floats = List[Float64](capacity=len(result.value()))
        for value in result.value():
            floats.append(atof(value[]))
        return floats^
