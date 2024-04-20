from collections.dict import Dict, KeyElement
from memory._arc import Arc
from collections.optional import Optional
from .vector import to_string
from .command import ArgValidator


trait StringableCollectionElement(Stringable, CollectionElement):
    ...


@value
struct StringKey(KeyElement):
    var s: String

    fn __init__(inout self, owned s: String):
        self.s = s^

    fn __init__(inout self, s: StringLiteral):
        self.s = String(s)

    fn __hash__(self) -> Int:
        return hash(self.s)

    fn __eq__(self, other: Self) -> Bool:
        return self.s == other.s

    fn __ne__(self, other: Self) -> Bool:
        return self.s != other.s

    fn __str__(self) -> String:
        return self.s


fn string_to_bool(value: String) -> Bool:
    if value == "True":
        return True
    return False


fn str_to_float(s: String) raises -> Float64:
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
    var flags: List[Flag]

    fn __init__(
        inout self,
        flags: List[Flag] = List[Flag](),
    ) -> None:
        self.flags = flags

    fn __str__(self) -> String:
        var result = String("Flags: [")
        for i in range(self.flags.size):
            result += self.flags[i]
            if i != self.flags.size - 1:
                result += String(", ")
        result += String("]")
        return result

    fn __len__(self) -> Int:
        return self.flags.size

    fn __contains__(self, value: Flag) -> Bool:
        for flag in self.flags:
            if flag[] == value:
                return True
        return False

    fn __eq__(self, other: Self) -> Bool:
        if len(self.flags) != len(other.flags):
            return False

        for i in range(len(self.flags)):
            if self.flags[i] != other.flags[i]:
                return False
        return True

    fn __ne__(self, other: Self) -> Bool:
        return not self == other

    fn get_flag(self, name: String) raises -> Arc[Flag]:
        """Returns a reference to a Flag with the given name.

        Args:
            name: The name of the flag to return.
        """
        for flag in self.flags:
            if flag[].name == name:
                return Arc(flag[])

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
            if flag[].name == name and flag[].type == type:
                return Arc(flag[])

        raise Error("FlagNotFound: Could not find flag with name: " + name)

    fn get_as_string(self, name: String) -> Optional[String]:
        """Returns the value of a flag as a String. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        try:
            var flag = self.get_flag_of_type(name, "String")[]
            if not flag.value.value() and flag.default != "":
                return flag.default

            return flag.value
        except e:
            print(e)
            return None

    fn get_as_bool(self, name: String) -> Optional[Bool]:
        """Returns the value of a flag as a Bool. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        try:
            var flag = self.get_flag_of_type(name, "Bool")[]
            if not flag.value.value() and flag.default != "False":
                return string_to_bool(flag.default)

            return string_to_bool(flag.value.value())
        except e:
            print(e)
            return None

    fn get_as_int(self, name: String) raises -> Optional[Int]:
        """Returns the value of a flag as an Int. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        try:
            var flag = self.get_flag_of_type(name, "Int")[]
            if not flag.value.value() and flag.default != "0":
                return atol(flag.default)

            return atol(flag.value.value())
        except e:
            print(e)
            return None

    fn get_as_int8(self, name: String) raises -> Optional[Int8]:
        var value = self.get_as_int(name)
        if not value:
            return None

        return Int8(value.value())

    fn get_as_int16(self, name: String) raises -> Optional[Int16]:
        var value = self.get_as_int(name)
        if not value:
            return None

        return Int16(value.value())

    fn get_as_int32(self, name: String) raises -> Optional[Int32]:
        var value = self.get_as_int(name)
        if not value:
            return None

        return Int32(value.value())

    fn get_as_int64(self, name: String) raises -> Optional[Int64]:
        var value = self.get_as_int(name)
        if not value:
            return None

        return Int64(value.value())

    fn get_as_uint8(self, name: String) raises -> Optional[UInt8]:
        var value = self.get_as_int(name)
        if not value:
            return None

        return UInt8(value.value())

    fn get_as_uint16(self, name: String) raises -> Optional[UInt16]:
        var value = self.get_as_int(name)
        if not value:
            return None

        return UInt16(value.value())

    fn get_as_uint32(self, name: String) raises -> Optional[UInt32]:
        var value = self.get_as_int(name)
        if not value:
            return None

        return UInt32(value.value())

    fn get_as_uint64(self, name: String) raises -> Optional[UInt64]:
        var value = self.get_as_int(name)
        if not value:
            return None

        return UInt64(value.value())

    fn get_as_float16(self, name: String) raises -> Optional[Float16]:
        """Returns the value of a flag as a Float64. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        var value = self.get_as_float64(name)
        if not value:
            return None

        return Float16(value.value())

    fn get_as_float32(self, name: String) raises -> Optional[Float32]:
        """Returns the value of a flag as a Float64. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        var value = self.get_as_float64(name)
        if not value:
            return None

        return Float32(value.value())

    fn get_as_float64(self, name: String) raises -> Optional[Float64]:
        """Returns the value of a flag as a Float64. If it isn't set, then return the default value.

        Args:
            name: The name of the flag to return.
        """
        try:
            var flag = self.get_flag_of_type(name, "Float64")[]
            if not flag.value.value() and flag.default != "0":
                return str_to_float(flag.default)

            return str_to_float(flag.value.value())
        except e:
            print(e)
            return None

    fn get_flags(self) -> List[Arc[Flag]]:
        """Returns a list of references to all flags in the flag set."""
        var result = List[Arc[Flag]]()
        for flag in self.flags:
            result.append(Arc(flag[]))
        return result

    fn get_flags_with_values(self) -> List[Arc[Flag]]:
        """Returns a list of references to all flags in the flag set that have values set."""
        var result = List[Arc[Flag]]()
        for flag in self.flags:
            if flag[].value.value() != "":
                result.append(Arc(flag[]))
        return result

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

    fn _add_flag[
        T: StringableCollectionElement
    ](
        inout self, name: String, shorthand: String, usage: String, value: Optional[T], default: String, type: String
    ) -> None:
        """Adds a flag to the flag set.

        Args:
            name: The name of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            value: The value of the flag.
            default: The default value of the flag.
            type: The type of the flag.
        """
        if value:
            self.flags.append(Flag(name, shorthand, usage, str(value.value()), default, type))
            return

        self.flags.append(Flag(name, shorthand, usage, None, default, type))

    fn add_bool_flag(
        inout self,
        name: String,
        shorthand: String,
        usage: String,
        value: Optional[Bool] = None,
        default: Bool = False,
    ) -> None:
        """Adds a Bool flag to the flag set.

        Args:
            name: The name of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            value: The value of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, shorthand, usage, value, str(default), "Bool")

    fn add_string_flag(
        inout self,
        name: String,
        shorthand: String,
        usage: String,
        value: Optional[String] = None,
        default: String = "",
    ) -> None:
        """Adds a String flag to the flag set.

        Args:
            name: The name of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            value: The value of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, shorthand, usage, value, default, "String")

    fn add_int_flag(
        inout self,
        name: String,
        shorthand: String,
        usage: String,
        value: Optional[Int] = None,
        default: Int = 0,
    ) -> None:
        """Adds an Int flag to the flag set.

        Args:
            name: The name of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            value: The value of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, shorthand, usage, value, default, "Int")

    fn add_int8_flag(
        inout self,
        name: String,
        shorthand: String,
        usage: String,
        value: Optional[Int8] = None,
        default: Int8 = 0,
    ) -> None:
        """Adds an Int8 flag to the flag set.

        Args:
            name: The name of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            value: The value of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, shorthand, usage, value, default, "Int8")

    fn add_int16_flag(
        inout self,
        name: String,
        shorthand: String,
        usage: String,
        value: Optional[Int16] = None,
        default: Int16 = 0,
    ) -> None:
        """Adds an Int16 flag to the flag set.

        Args:
            name: The name of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            value: The value of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, shorthand, usage, value, default, "Int16")

    fn add_int32_flag(
        inout self,
        name: String,
        shorthand: String,
        usage: String,
        value: Optional[Int32] = None,
        default: Int32 = 0,
    ) -> None:
        """Adds an Int32 flag to the flag set.

        Args:
            name: The name of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            value: The value of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, shorthand, usage, value, default, "Int32")

    fn add_int64_flag(
        inout self,
        name: String,
        shorthand: String,
        usage: String,
        value: Optional[Int64] = None,
        default: Int64 = 0,
    ) -> None:
        """Adds an Int64 flag to the flag set.

        Args:
            name: The name of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            value: The value of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, shorthand, usage, value, default, "Int64")

    fn add_uint8_flag(
        inout self,
        name: String,
        shorthand: String,
        usage: String,
        value: Optional[UInt8] = None,
        default: UInt8 = 0,
    ) -> None:
        """Adds a UInt8 flag to the flag set.

        Args:
            name: The name of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            value: The value of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, shorthand, usage, value, default, "UInt8")

    fn add_uint16_flag(
        inout self,
        name: String,
        shorthand: String,
        usage: String,
        value: Optional[UInt16] = None,
        default: UInt16 = 0,
    ) -> None:
        """Adds a UInt16 flag to the flag set.

        Args:
            name: The name of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            value: The value of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, shorthand, usage, value, default, "UInt16")

    fn add_uint32_flag(
        inout self,
        name: String,
        shorthand: String,
        usage: String,
        value: Optional[UInt32] = None,
        default: UInt32 = 0,
    ) -> None:
        """Adds a UInt32 flag to the flag set.

        Args:
            name: The name of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            value: The value of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, shorthand, usage, value, default, "UInt32")

    fn add_uint64_flag(
        inout self,
        name: String,
        shorthand: String,
        usage: String,
        value: Optional[UInt64] = None,
        default: UInt64 = 0,
    ) -> None:
        """Adds a UInt64 flag to the flag set.

        Args:
            name: The name of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            value: The value of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, shorthand, usage, value, default, "UInt64")

    fn add_float16_flag(
        inout self,
        name: String,
        shorthand: String,
        usage: String,
        value: Optional[Float16] = None,
        default: Float16 = 0,
    ) -> None:
        """Adds a Float16 flag to the flag set.

        Args:
            name: The name of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            value: The value of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, shorthand, usage, value, default, "Float16")

    fn add_float32_flag(
        inout self,
        name: String,
        shorthand: String,
        usage: String,
        value: Optional[Float32] = None,
        default: Float32 = 0,
    ) -> None:
        """Adds a Float32 flag to the flag set.

        Args:
            name: The name of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            value: The value of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, shorthand, usage, value, default, "Float32")

    fn add_float64_flag(
        inout self,
        name: String,
        shorthand: String,
        usage: String,
        value: Optional[Float64] = None,
        default: Float64 = 0,
    ) -> None:
        """Adds a Float64 flag to the flag set.

        Args:
            name: The name of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            value: The value of the flag.
            default: The default value of the flag.
        """
        self._add_flag(name, shorthand, usage, value, default, "Float64")

    # TODO: This is temporary until I figure out how to return a mutable reference to a flag inside the list.
    # Calling get_flag, dereferencing, and then setting the value does not persist.
    fn _set_flag_value(inout self, name: String, value: String) raises -> None:
        """Sets the value of a flag with the given name.

        Args:
            name: The name of the flag to set the value of.
            value: The value to set the flag to.
        """
        for i in range(len(self.flags)):
            if self.flags[i].name == name or self.flags[i].shorthand == name:
                self.flags[i].value = value
                return

        raise Error("FlagNotFound: Could not find flag with name: " + name)


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


# TODO: This parsing is dirty atm, will come back around and clean it up.
fn get_flags(inout flags: FlagSet, arguments: List[String]) raises -> List[String]:
    """Parses flags and args from the args passed via the command line and adds them to their appropriate collections.

    Args:
        flags: The flags passed via the command line.
        arguments: The arguments passed via the command line.
    """
    var remaining_args = List[String]()
    for i in range(len(arguments)):
        # while True:
        var argument = String(arguments[i])
        if argument.startswith("--", 0, 2):
            if argument.find("=") != -1:
                var flag = argument.split("=")
                var name = flag[0][2:]
                var value = flag[1]

                if name not in flags:
                    raise Error("Command does not accept the flag supplied: " + name)

                try:
                    flags._set_flag_value(name, value)

                except e:
                    raise Error("Command does not accept the flag supplied: " + name + "; " + e)
        elif argument.startswith("-", 0, 1):
            if argument.find("=") != -1:
                var flag = argument.split("=")
                var shorthand = flag[0][1:]
                var value = flag[1]

                var shorthands = flags.get_shorthands()
                for i in range(len(shorthands)):
                    if shorthands[i] == shorthand:
                        break
                    elif i == len(shorthands) - 1:
                        raise Error("Command does not accept the shorthand flag supplied: " + shorthand)

                try:
                    flags._set_flag_value(shorthand, value)
                except e:
                    raise Error("Command does not accept the flag supplied: " + shorthand + "; " + e)
        else:
            remaining_args.append(argument)

    return remaining_args
