from collections import Optional, Dict, InlineList
from gojo.builtins import panic
import gojo.fmt
from .flag import Flag


alias FlagVisitorFn = fn (Flag) capturing -> None
"""Function perform some action while visiting all flags."""


fn string_to_bool(value: String) -> Bool:
    """Converts a string to a boolean.

    Args:
        value: The string to convert to a boolean.

    Returns:
        The boolean equivalent of the string.
    """
    alias truthy = InlineList[String, 3]("true", "True", "1")
    for i in range(len(truthy)):
        if value == truthy[i]:
            return True
    return False


fn string_to_float(s: String) raises -> Float64:
    try:
        # locate decimal point
        var dot_pos = s.find(".")
        # grab the integer part of the number
        var int_str = s[0:dot_pos]
        # grab the decimal part of the number
        var num_str = s[dot_pos + 1 : len(s)]
        # set the numerator to be the integer equivalent
        var numerator = atol(num_str)
        # construct denom_str to be "1" + "0"s for the length of the fraction
        var denom_str = String()
        for _ in range(len(num_str)):
            denom_str += "0"
        var denominator = atol("1" + denom_str)
        # school-level maths here :)
        var frac = numerator / denominator

        # return the number as a Float64
        var result: Float64 = atol(int_str) + frac
        return result
    except:
        raise Error("string_to_float: Failed to convert " + s + " to a float.")


@value
struct FlagSet(Stringable, Sized, Boolable, EqualityComparable):
    var flags: List[Flag]

    fn __init__(inout self) -> None:
        self.flags = List[Flag]()

    fn __init__(inout self, other: FlagSet) -> None:
        self.flags = other.flags

    fn __str__(self) -> String:
        var result = String("Flags: [")
        for i in range(self.flags.size):
            var f = self.flags[i]
            result += str(f)
            if i != self.flags.size - 1:
                result += String(", ")
        result += String("]")
        return result

    fn __len__(self) -> Int:
        return self.flags.size

    fn __bool__(self) -> Bool:
        return self.flags.__bool__()

    fn __contains__(self, value: Flag) -> Bool:
        for flag in self.flags:
            if flag[] == value:
                return True
        return False

    fn __eq__(self, other: Self) -> Bool:
        if len(self.flags) != len(other.flags):
            return False

        for i in range(len(self.flags)):
            var f = self.flags[i]
            var other_f = other.flags[i]
            if f != other_f:
                return False
        return True

    fn __ne__(self, other: Self) -> Bool:
        return not self == other

    fn __add__(inout self, other: Self) -> Self:
        var new = Self(self)
        for flag in other.flags:
            new.flags.append(flag[])
        return new

    fn __iadd__(inout self, other: Self):
        self.add_flag_set(other)

    fn lookup(ref [_]self, name: String) -> Optional[Reference[Flag, __lifetime_of(self.flags)]]:
        """Returns an mutable or immutable reference to a Flag with the given name.
        Mutable if FlagSet is mutable, immutable if FlagSet is immutable.

        Args:
            name: The name of the flag to return.

        Returns:
            Optional Reference to the Flag.
        """
        for i in range(len(self.flags)):
            if self.flags[i].name == name:
                return Reference(self.flags[i])

        return None

    fn lookup_with_type(
        ref [_]self, name: String, type: String
    ) -> Optional[Reference[Flag, __lifetime_of(self.flags)]]:
        """Returns an mutable or immutable reference to a Flag with the given name.
        Mutable if FlagSet is mutable, immutable if FlagSet is immutable.

        Args:
            name: The name of the flag to return.
            type: The type of the flag to return.

        Returns:
            Optional Reference to the Flag.
        """
        for i in range(len(self.flags)):
            if self.flags[i].name == name and self.flags[i].type == type:
                return Reference(self.flags[i])

        return None

    fn get_as_string(self, name: String) -> Optional[String]:
        """Returns the value of a flag as a String. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        var result = self.lookup_with_type(name, "String")
        if not result:
            return None

        var flag = result.value()
        if not flag[].value:
            return flag[].default

        return flag[].value

    fn get_as_bool(self, name: String) -> Optional[Bool]:
        """Returns the value of a flag as a Bool. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        var result = self.lookup_with_type(name, "Bool")
        if not result:
            return None

        var flag = result.value()
        if not flag[].value:
            return string_to_bool(flag[].default)

        return string_to_bool(flag[].value.value())

    fn get_as_int(self, name: String) -> Optional[Int]:
        """Returns the value of a flag as an Int. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        var result = self.lookup_with_type(name, "Int")
        if not result:
            return None

        var flag = result.value()

        # TODO: I don't like this swallowing up a failure to convert to int. Maybe return a tuple of optional and error?
        try:
            if not flag[].value:
                return atol(flag[].default)

            return atol(flag[].value.value())
        except e:
            return None

    fn get_as_int8(self, name: String) -> Optional[Int8]:
        """Returns the value of a flag as a Int8. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        var value = self.get_as_int(name)
        if not value:
            return None

        return Int8(value.value())

    fn get_as_int16(self, name: String) -> Optional[Int16]:
        """Returns the value of a flag as a Int16. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        var value = self.get_as_int(name)
        if not value:
            return None

        return Int16(value.value())

    fn get_as_int32(self, name: String) -> Optional[Int32]:
        """Returns the value of a flag as a Int32. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        var value = self.get_as_int(name)
        if not value:
            return None

        return Int32(value.value())

    fn get_as_int64(self, name: String) -> Optional[Int64]:
        """Returns the value of a flag as a Int64. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        var value = self.get_as_int(name)
        if not value:
            return None

        return Int64(value.value())

    fn get_as_uint8(self, name: String) -> Optional[UInt8]:
        """Returns the value of a flag as a UInt8. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        var value = self.get_as_int(name)
        if not value:
            return None

        return UInt8(value.value())

    fn get_as_uint16(self, name: String) -> Optional[UInt16]:
        """Returns the value of a flag as a UInt16. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        var value = self.get_as_int(name)
        if not value:
            return None

        return UInt16(value.value())

    fn get_as_uint32(self, name: String) -> Optional[UInt32]:
        """Returns the value of a flag as a UInt32. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        var value = self.get_as_int(name)
        if not value:
            return None

        return UInt32(value.value())

    fn get_as_uint64(self, name: String) -> Optional[UInt64]:
        """Returns the value of a flag as a UInt64. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        var value = self.get_as_int(name)
        if not value:
            return None

        return UInt64(value.value())

    fn get_as_float16(self, name: String) -> Optional[Float16]:
        """Returns the value of a flag as a Float64. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        var value = self.get_as_float64(name)
        if not value:
            return None

        return value.value().cast[DType.float16]()

    fn get_as_float32(self, name: String) -> Optional[Float32]:
        """Returns the value of a flag as a Float64. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        var value = self.get_as_float64(name)
        if not value:
            return None

        return value.value().cast[DType.float32]()

    fn get_as_float64(self, name: String) -> Optional[Float64]:
        """Returns the value of a flag as a Float64. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        var result = self.lookup_with_type(name, "Float64")
        if not result:
            return None

        var flag = result.value()

        # TODO: I don't like this swallowing up a failure to convert to int. Maybe return a tuple of optional and error?
        try:
            if not flag[].value:
                return string_to_float(flag[].default)

            return string_to_float(flag[].value.value())
        except e:
            return None

    # fn get_flags_with_values(self) -> List[Reference[Flag, i1_0, __lifetime_of(self)]]:
    #     """Returns a list of immutable references to all flags in the flag set that have values set."""
    #     var result = List[Reference[Flag, i1_0, __lifetime_of(self)]]()
    #     for flag in self.flags:
    #         if flag[].value.value()[] != "":
    #             result.append(flag)
    #     return result

    fn get_names(self) -> List[String]:
        """Returns a list of names of all flags in the flag set."""
        var result = List[String]()
        for flag in self.flags:
            result.append(flag[].name)
        return result

    fn get_shorthands(self) -> List[String]:
        """Returns a list of shorthands of all flags in the flag set."""
        var result = List[String]()
        for flag in self.flags:
            result.append(flag[].shorthand)
        return result

    fn lookup_name(self, shorthand: String) -> Optional[String]:
        """Returns the name of a flag given its shorthand.

        Args:
            shorthand: The shorthand of the flag to lookup.
        """
        for flag in self.flags:
            if flag[].shorthand == shorthand:
                return flag[].name
        return None

    fn _add_flag(
        inout self, name: String, usage: String, default: String, type: String, shorthand: String = ""
    ) -> None:
        """Adds a flag to the flag set.
        Valid type values: [String, Bool, Int, Int8, Int16, Int32, Int64,
        UInt8, UInt16, UInt32, UInt64, Float16, Float32, Float64]

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            default: The default value of the flag.
            type: The type of the flag.
            shorthand: The shorthand of the flag.
        """
        # Use var to set the mutability of flag, then add it to the list
        var flag = Flag(name=name, shorthand=shorthand, usage=usage, value=None, default=str(default), type=type)
        self.flags.append(flag)

    fn add_bool_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: Bool = False,
    ) -> None:
        """Adds a Bool flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, str(default), "Bool", shorthand)

    fn add_string_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: String = "",
    ) -> None:
        """Adds a String flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, str(default), "String", shorthand)

    fn add_int_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int = 0) -> None:
        """Adds an Int flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, str(default), "Int", shorthand)

    fn add_int8_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int8 = 0) -> None:
        """Adds an Int8 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, str(default), "Int8", shorthand)

    fn add_int16_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int16 = 0) -> None:
        """Adds an Int16 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, str(default), "Int16", shorthand)

    fn add_int32_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int32 = 0) -> None:
        """Adds an Int32 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, str(default), "Int32", shorthand)

    fn add_int64_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int64 = 0) -> None:
        """Adds an Int64 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, str(default), "Int64", shorthand)

    fn add_uint8_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt8 = 0) -> None:
        """Adds a UInt8 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, str(default), "UInt8", shorthand)

    fn add_uint16_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt16 = 0) -> None:
        """Adds a UInt16 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, str(default), "UInt16", shorthand)

    fn add_uint32_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt32 = 0) -> None:
        """Adds a UInt32 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, str(default), "UInt32", shorthand)

    fn add_uint64_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt64 = 0) -> None:
        """Adds a UInt64 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, str(default), "UInt64", shorthand)

    fn add_float16_flag(inout self, name: String, usage: String, shorthand: String = "", default: Float16 = 0) -> None:
        """Adds a Float16 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, str(default), "Float16", shorthand)

    fn add_float32_flag(inout self, name: String, usage: String, shorthand: String = "", default: Float32 = 0) -> None:
        """Adds a Float32 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, str(default), "Float32", shorthand)

    fn add_float64_flag(inout self, name: String, usage: String, shorthand: String = "", default: Float64 = 0) -> None:
        """Adds a Float64 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, str(default), "Float64", shorthand)

    fn set_annotation(inout self, name: String, key: String, values: List[String]) -> Error:
        """Sets an annotation for a flag.

        Args:
            name: The name of the flag to set the annotation for.
            key: The key of the annotation.
            values: The values of the annotation.
        """
        var result = self.lookup(name)
        if not result:
            return Error("FlagSet.set_annotation: Could not find flag with name: " + name)

        result.value()[].annotations[key] = values
        return Error()

    fn visit_all[visitor: FlagVisitorFn](self) -> None:
        """Visits all flags in the flag set.

        Params:
            visitor: The visitor function to call for each flag.
        """
        for flag in self.flags:
            visitor(flag[])

    fn add_flag_set(inout self, new_set: Self) -> None:
        """Adds flags from another FlagSet. If a flag is already present, the flag from the new set is ignored.

        Args:
            new_set: The flag set to add.
        """

        @always_inline
        fn add_flag(flag: Flag) capturing -> None:
            if not self.lookup(flag.name):
                self.flags.append(flag)

        new_set.visit_all[add_flag]()


fn process_flag_for_group_annotation(
    flags: FlagSet,
    flag: Reference[Flag],
    annotation: String,
    inout group_status: Dict[String, Dict[String, Bool]],
) -> Error:
    var group_info = flag[].annotations.get(annotation, List[String]())
    if group_info:
        for group in group_info:
            var group_name = group[]
            if len(group_status.get(group_name, Dict[String, Bool]())) == 0:
                var flag_names = List[String]()
                try:
                    flag_names = group_name.split(sep=" ")
                except e:
                    return Error("process_flag_for_group_annotation: Failed to split group names: " + str(e))

                # Only consider this flag group at all if all the flags are defined.
                if not has_all_flags(flags, flag_names):
                    continue

                for name in flag_names:
                    var entry = Dict[String, Bool]()
                    entry[name[]] = False
                    group_status[group[]] = entry

            # If flag.changed = True, then it had a value set on it.
            try:
                group_status[group[]][flag[].name] = flag[].changed
            except e:
                return Error("process_flag_for_group_annotation: Failed to set group status: " + str(e))

    return Error()


fn has_all_flags(flags: FlagSet, flag_names: List[String]) -> Bool:
    for name in flag_names:
        if not flags.lookup(name[]):
            return False
    return True


fn validate_required_flag_group(data: Dict[String, Dict[String, Bool]]) -> None:
    """Validates that all flags in a group are set if any are set.
    This is for flags that are marked as required via `Command().mark_flags_required_together()`.

    Args:
        data: The dictionary of flag groups to validate.
    """
    # Within each group, is a Dict of flag name and if they're set.
    # If it's unset then add to a list to check the condition of all required flags being set.
    for pair in data.items():
        var unset = List[String]()
        for flag in pair[].value.items():
            if not flag[].value:
                unset.append(flag[].key)

        if len(unset) == len(pair[].value) or len(unset) == 0:
            continue

        # Sort values, so they can be tested/scripted against consistently.
        # unset.sort()
        var keys = List[String]()
        for key in pair[].value.keys():
            keys.append(key[])

        panic(
            fmt.sprintf(
                "if any flags in the group, %s, are set they must all be set; missing %s",
                keys.__str__(),
                unset.__str__(),
            )
        )


fn validate_one_required_flag_group(data: Dict[String, Dict[String, Bool]]) -> None:
    """Validates that at least one flag in a group is set.
    This is for flags that are marked as required via `Command().mark_flag_required()`.

    Args:
        data: The dictionary of flag groups to validate.
    """
    # Check if at least one key is set.
    for pair in data.items():
        var set = List[String]()
        for flag in pair[].value.items():
            if flag[].value:
                set.append(flag[].key)

        if len(set) >= 1:
            continue

        # Sort values, so they can be tested/scripted against consistently.
        # unset.sort()
        var keys = List[String]()
        for key in pair[].value.keys():
            keys.append(key[])

        panic(fmt.sprintf("at least one of the flags in the group %s is required", keys.__str__()))


fn validate_mutually_exclusive_flag_group(data: Dict[String, Dict[String, Bool]]) -> None:
    """Validates that only one flag in a group is set.
    This is for flags that are marked as required via `Command().mark_flags_mutually_exclusive()`.

    Args:
        data: The dictionary of flag groups to validate.
    """
    # Check if more than one mutually exclusive flag is set.
    for pair in data.items():
        var set = List[String]()
        for flag in pair[].value.items():
            if flag[].value:
                set.append(flag[].key)

        if len(set) == 0 or len(set) == 1:
            continue

        # Sort values, so they can be tested/scripted against consistently.
        # unset.sort()
        var keys = List[String]()
        for key in pair[].value.keys():
            keys.append(key[])

        panic(
            fmt.sprintf(
                "if any flags in the group %s are set none of the others can be; %s were all set",
                keys.__str__(),
                set.__str__(),
            )
        )


fn validate_flag_groups(
    group_status: Dict[String, Dict[String, Bool]],
    one_required_group_status: Dict[String, Dict[String, Bool]],
    mutually_exclusive_group_status: Dict[String, Dict[String, Bool]],
) -> None:
    """Validates the status of flag groups.
    Checks for flag groups that are required together, at least one required, and mutually exclusive.
    Status is a map of maps containing the flag name and if it's been set.

    Args:
        group_status: The status of flag groups that are required together.
        one_required_group_status: The status of flag groups that require at least one flag to be set.
        mutually_exclusive_group_status: The status of flag groups that are mutually exclusive.
    """
    validate_required_flag_group(group_status)
    validate_one_required_flag_group(one_required_group_status)
    validate_mutually_exclusive_flag_group(mutually_exclusive_group_status)
