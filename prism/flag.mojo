from memory._arc import Arc
from collections.optional import Optional
from .vector import to_string
from .command import ArgValidator


fn string_to_bool(value: String) -> Bool:
    """Converts a string to a boolean.

    Args:
        value: The string to convert to a boolean.

    Returns:
        The boolean equivalent of the string.
    """
    var truthy = List[String]("true", "True", "1")
    for t in truthy:
        if value == t[]:
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
        raise Error("Failed to convert " + s + " to a float.")


@value
struct FlagSet(Stringable, Sized):
    var flags: List[Arc[Flag]]

    fn __init__(inout self) -> None:
        self.flags = List[Arc[Flag]]()

    fn __init__(inout self, flag_set: Self) -> None:
        self = flag_set

    fn __str__(self) -> String:
        var result = String("Flags: [")
        for i in range(self.flags.size):
            var f = self.flags[i]
            result += f[]
            if i != self.flags.size - 1:
                result += String(", ")
        result += String("]")
        return result

    fn __len__(self) -> Int:
        return self.flags.size

    fn __contains__(self, value: Flag) -> Bool:
        for flag in self.flags:
            if flag[][] == value:
                return True
        return False

    fn __eq__(self, other: Self) -> Bool:
        if len(self.flags) != len(other.flags):
            return False

        for i in range(len(self.flags)):
            var f = self.flags[i]
            var other_f = other.flags[i]
            if f[] != other_f[]:
                return False
        return True

    fn __ne__(self, other: Self) -> Bool:
        return not self == other

    fn __add__(inout self, other: Self) -> Self:
        var new = FlagSet(self)
        for flag in other.flags:
            new.flags.append(flag[])
        return new

    fn __iadd__(inout self, other: Self):
        for flag in other.flags:
            self.flags.append(flag[])

    fn get_flag(self, name: String) raises -> Arc[Flag]:
        """Returns a reference to a Flag with the given name.

        Args:
            name: The name of the flag to return.
        """
        for flag in self.flags:
            if flag[][].name == name:
                return flag[]

        raise Error("FlagNotFound: Could not find flag with name: " + name)

    fn get_flag_of_type(self, name: String, type: String) raises -> Arc[Flag]:
        """Returns a reference to a Flag with the given name and type.

        Args:
            name: The name of the flag to return.
            type: The type of the flag to return.

        Returns:
            ARC pointer to the Flag.
        """
        for flag in self.flags:
            if flag[][].name == name and flag[][].type == type:
                return flag[]

        raise Error("FlagNotFound: Could not find flag with name: " + name)

    fn get_as_string(self, name: String) -> Optional[String]:
        """Returns the value of a flag as a String. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        try:
            var flag = self.get_flag_of_type(name, "String")[]
            if not flag.value:
                return flag.default

            return flag.value
        except e:
            return None

    fn get_as_bool(self, name: String) -> Optional[Bool]:
        """Returns the value of a flag as a Bool. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        try:
            var flag = self.get_flag_of_type(name, "Bool")[]
            if not flag.value:
                return string_to_bool(flag.default)

            return string_to_bool(flag.value.value())
        except:
            return None

    fn get_as_int(self, name: String) -> Optional[Int]:
        """Returns the value of a flag as an Int. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        try:
            var flag = self.get_flag_of_type(name, "Int")[]
            if not flag.value:
                return atol(flag.default)

            return atol(flag.value.value())
        except:
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

        return Float16(value.value())

    fn get_as_float32(self, name: String) -> Optional[Float32]:
        """Returns the value of a flag as a Float64. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        var value = self.get_as_float64(name)
        if not value:
            return None

        return Float32(value.value())

    fn get_as_float64(self, name: String) -> Optional[Float64]:
        """Returns the value of a flag as a Float64. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        try:
            var flag = self.get_flag_of_type(name, "Float64")[]
            if not flag.value:
                return string_to_float(flag.default)

            return string_to_float(flag.value.value())
        except e:
            return None

    fn get_flags_with_values(self) -> List[Arc[Flag]]:
        """Returns a list of references to all flags in the flag set that have values set."""
        var result = List[Arc[Flag]]()
        for flag in self.flags:
            if flag[][].value.value() != "":
                result.append(flag[])
        return result

    fn get_names(self) -> List[String]:
        """Returns a list of names of all flags in the flag set."""
        var result = List[String]()
        for flag in self.flags:
            result.append(flag[][].name)
        return result

    fn get_shorthands(self) -> List[String]:
        """Returns a list of shorthands of all flags in the flag set."""
        var result = List[String]()
        for flag in self.flags:
            result.append(flag[][].shorthand)
        return result

    fn lookup_name(self, shorthand: String) -> Optional[String]:
        """Returns the name of a flag given its shorthand.

        Args:
            shorthand: The shorthand of the flag to lookup.
        """
        for flag in self.flags:
            if flag[][].shorthand == shorthand:
                return flag[][].name
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
        var flag = Flag(name=name, shorthand=shorthand, usage=usage, value=None, default=default, type=type)
        self.flags.append(Arc(flag))

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
        self._add_flag(name, usage, default, "String", shorthand)

    fn add_int_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int = 0) -> None:
        """Adds an Int flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, default, "Int", shorthand)

    fn add_int8_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int8 = 0) -> None:
        """Adds an Int8 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, default, "Int8", shorthand)

    fn add_int16_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int16 = 0) -> None:
        """Adds an Int16 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, default, "Int16", shorthand)

    fn add_int32_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int32 = 0) -> None:
        """Adds an Int32 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, default, "Int32", shorthand)

    fn add_int64_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int64 = 0) -> None:
        """Adds an Int64 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, default, "Int64", shorthand)

    fn add_uint8_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt8 = 0) -> None:
        """Adds a UInt8 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, default, "UInt8", shorthand)

    fn add_uint16_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt16 = 0) -> None:
        """Adds a UInt16 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, default, "UInt16", shorthand)

    fn add_uint32_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt32 = 0) -> None:
        """Adds a UInt32 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, default, "UInt32", shorthand)

    fn add_uint64_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt64 = 0) -> None:
        """Adds a UInt64 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, default, "UInt64", shorthand)

    fn add_float16_flag(inout self, name: String, usage: String, shorthand: String = "", default: Float16 = 0) -> None:
        """Adds a Float16 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, default, "Float16", shorthand)

    fn add_float32_flag(inout self, name: String, usage: String, shorthand: String = "", default: Float32 = 0) -> None:
        """Adds a Float32 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, default, "Float32", shorthand)

    fn add_float64_flag(inout self, name: String, usage: String, shorthand: String = "", default: Float64 = 0) -> None:
        """Adds a Float64 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, usage, default, "Float64", shorthand)


@value
struct Flag(CollectionElement, Stringable):
    """Represents a flag that can be passed via the command line.
    Flags are passed in via --name or -shorthand and can have a value associated with them.
    """

    var name: String
    var shorthand: String
    var usage: String
    var value: Optional[String]
    var default: String
    var type: String

    fn __init__(
        inout self,
        name: String,
        shorthand: String,
        usage: String,
        value: Optional[String],
        default: String,
        type: String,
    ) -> None:
        """Initializes a new Flag.

        Args:
            name: The name of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            value: The value of the flag.
            default: The default value of the flag.
            type: The type of the flag.
        """
        self.name = name
        self.shorthand = shorthand
        self.usage = usage
        self.value = value
        self.default = default
        self.type = type

    fn __str__(self) -> String:
        return (
            String("(Name: ")
            + self.name
            + String(", Shorthand: ")
            + self.shorthand
            + String(", Usage: ")
            + self.usage
            + String(")")
        )

    fn __repr__(self) -> String:
        return str(self)

    fn __eq__(self, other: Self) -> Bool:
        return (
            self.name == other.name
            and self.shorthand == other.shorthand
            and self.usage == other.usage
            and self.value.value() == other.value.value()
            and self.default == other.default
        )

    fn __ne__(self, other: Self) -> Bool:
        return not self == other


fn parse_flag(
    i: Int, argument: String, arguments: List[String], flags: Arc[FlagSet]
) raises -> Tuple[String, String, Int]:
    """Parses a flag and returns the name, value, and the index to increment by.

    Args:
        i: The current index in the arguments list.
        argument: The argument to parse.
        arguments: The list of arguments passed via the command line.
        flags: The flags passed via the command line.
    """
    # Flag with value set like "--flag=<value>"
    if argument.find("=") != -1:
        var flag = argument.split("=")
        var name = flag[0][2:]
        var value = flag[1]

        if name not in flags[]:
            raise Error("Command does not accept the flag supplied: " + name)

        return name, value, 1

    # Flag with value set like "--flag <value>"
    var name = argument[2:]
    if name not in flags[]:
        raise Error("Command does not accept the flag supplied: " + name)

    # If it's a bool flag, set it to True and only increment the index by 1 (one arg used).
    if flags[].get_as_bool(name):
        return name, String("True"), 1

    if i + 1 >= len(arguments):
        raise Error("Flag " + name + " requires a value to be set but reached the end of arguments.")

    if arguments[i + 1].startswith("-", 0, 1):
        raise Error("Flag " + name + " requires a value to be set but found another flag instead.")

    # Increment index by 2 because 2 args were used (one for name and value).
    return name, arguments[i + 1], 2


fn parse_shorthand_flag(
    i: Int, argument: String, arguments: List[String], flags: Arc[FlagSet]
) raises -> Tuple[String, String, Int]:
    """Parses a shorthand flag and returns the name, value, and the index to increment by.

    Args:
        i: The current index in the arguments list.
        argument: The argument to parse.
        arguments: The list of arguments passed via the command line.
        flags: The flags passed via the command line.
    """
    # Flag with value set like "-f=<value>"
    if argument.find("=") != -1:
        var flag = argument.split("=")
        var shorthand = flag[0][1:]
        var value = flag[1]
        var name = flags[].lookup_name(shorthand).value()

        if name not in flags[]:
            raise Error("Command does not accept the flag supplied: " + name)

        return name, value, 1

    # Flag with value set like "-f <value>"
    var shorthand = argument[1:]
    var result = flags[].lookup_name(shorthand)
    if not result:
        raise Error("Did not find name for shorthand: " + shorthand)
    var name = result.value()

    # If it's a bool flag, set it to True and only increment the index by 1 (one arg used).
    if flags[].get_as_bool(name):
        return name, String("True"), 1

    if i + 1 >= len(arguments):
        raise Error("Flag " + name + " requires a value to be set but reached the end of arguments.")

    if arguments[i + 1].startswith("-", 0, 1):
        raise Error("Flag " + name + " requires a value to be set but found another flag instead.")

    # Increment index by 2 because 2 args were used (one for name and value).
    return name, arguments[i + 1], 2


# TODO: This parsing is dirty atm, will come back around and clean it up.
fn get_flags(inout flags: Arc[FlagSet], arguments: List[String]) -> (List[String], Error):
    """Parses flags and args from the args passed via the command line and adds them to their appropriate collections.

    Args:
        flags: The flags passed via the command line.
        arguments: The arguments passed via the command line.
    """
    var remaining_args = List[String]()
    var i = 0
    while i < len(arguments):
        var argument = arguments[i]

        # Positional argument
        if not argument.startswith("-", 0, 1):
            remaining_args.append(argument)
            i += 1
            continue

        var name: String = ""
        var value: String = ""
        var increment_by: Int = 0

        try:
            # Full flag
            if argument.startswith("--", 0, 2):
                name, value, increment_by = parse_flag(i, argument, arguments, flags)

            # Shorthand flag
            elif argument.startswith("-", 0, 1):
                name, value, increment_by = parse_shorthand_flag(i, argument, arguments, flags)

            # Set the value of the flag directly, no more set_value function.
            flags[].get_flag(name)[].value = value
        except e:
            return remaining_args, e

        i += increment_by

    return remaining_args, Error()
