from collections import Optional, Dict, InlineList
from utils import Variant
import gojo.fmt
from .flag import Flag
from .util import panic, string_to_bool, string_to_float, split
from .flag_parser import FlagParser
from .transform import (
    get_string,
    get_bool,
    get_int,
    get_int8,
    get_int16,
    get_int32,
    get_int64,
    get_uint8,
    get_uint16,
    get_uint32,
    get_uint64,
    as_float16,
    as_float32,
    as_float64,
)

alias FlagVisitorFn = fn (Flag) capturing -> None
"""Function perform some action while visiting all flags."""
alias FlagVisitorRaisingFn = fn (Flag) capturing raises -> None
"""Function perform some action while visiting all flags. Can raise."""

# Individual flag annotations
alias REQUIRED = "REQUIRED"

# Flag Group annotations
alias REQUIRED_AS_GROUP = "REQUIRED_AS_GROUP"
alias ONE_REQUIRED = "ONE_REQUIRED"
alias MUTUALLY_EXCLUSIVE = "MUTUALLY_EXCLUSIVE"

alias FLAG_TYPES = ["String", "Bool", "Int", "Int8", "Int16", "Int32", "Int64", "UInt8", "UInt16", "UInt32", "UInt64", "Float16", "Float32", "Float64"]

@value
struct FlagSet(CollectionElement, Stringable, Sized, Boolable, EqualityComparable):
    var flags: List[Flag]

    fn __init__(inout self) -> None:
        self.flags = List[Flag]()

    fn __init__(inout self, other: FlagSet) -> None:
        self.flags = other.flags

    fn __str__(self) -> String:
        var output = String()
        var writer = output._unsafe_to_formatter()
        self.format_to(writer)
        return output

    fn format_to(self, inout writer: Formatter):
        writer.write("Flags: [")
        for i in range(self.flags.size):
            self.flags[i].format_to(writer)
            if i != self.flags.size - 1:
                writer.write(", ")
        writer.write("]")

    fn __len__(self) -> Int:
        return self.flags.size

    fn __bool__(self) -> Bool:
        return self.flags.__bool__()

    fn __contains__(self, value: Flag) -> Bool:
        return value in self.flags

    fn __eq__(self, other: Self) -> Bool:
        return self.flags == other.flags

    fn __ne__(self, other: Self) -> Bool:
        return self.flags != other.flags

    fn __add__(inout self, other: Self) -> Self:
        var new = Self(self)
        for flag in other.flags:
            new.flags.append(flag[])
        return new

    fn __iadd__(inout self, other: Self):
        self.merge(other)

    fn lookup(
        ref [_] self, name: String, type: String = ""
    ) -> Optional[Reference[Flag, __lifetime_of(self.flags)]]:
        """Returns an mutable or immutable reference to a Flag with the given name.
        Mutable if FlagSet is mutable, immutable if FlagSet is immutable.

        Args:
            name: The name of the Flag to lookup.
            type: The type of the Flag to lookup.

        Returns:
            Optional Reference to the Flag.
        """
        if type == "":
            for i in range(len(self.flags)):
                if self.flags[i].name == name:
                    return Reference(self.flags[i])
        else:        
            for i in range(len(self.flags)):
                if self.flags[i].name == name and self.flags[i].type == type:
                    return Reference(self.flags[i])
        return None
    
    fn lookup_name(self, shorthand: String) -> Optional[String]:
        """Returns the name of a flag given its shorthand.

        Args:
            shorthand: The shorthand of the flag to lookup.
        """
        for flag in self.flags:
            if flag[].shorthand and flag[].shorthand == shorthand:
                return flag[].name
        return None

    fn get_as[
        R: CollectionElement, transform: fn (flag_set: FlagSet, name: String) -> Optional[R]
    ](self, name: String) -> Optional[R]:
        return transform(self, name)

    fn get_string(self, name: String) -> Optional[String]:
        """Returns the value of a flag as a String. If it isn't set, then return the default value."""
        return self.get_as[R=String, transform=get_string](name)

    fn get_bool(self, name: String) -> Optional[Bool]:
        """Returns the value of a flag as a Bool. If it isn't set, then return the default value."""
        return self.get_as[R=Bool, transform=get_bool](name)

    fn get_int(self, name: String) -> Optional[Int]:
        """Returns the value of a flag as an Int. If it isn't set, then return the default value."""
        return self.get_as[R=Int, transform=get_int](name)

    fn get_int8(self, name: String) -> Optional[Int8]:
        """Returns the value of a flag as a Int8. If it isn't set, then return the default value."""
        return self.get_as[R=Int8, transform=get_int8](name)

    fn get_int16(self, name: String) -> Optional[Int16]:
        """Returns the value of a flag as a Int16. If it isn't set, then return the default value."""
        return self.get_as[R=Int16, transform=get_int16](name)

    fn get_int32(self, name: String) -> Optional[Int32]:
        """Returns the value of a flag as a Int32. If it isn't set, then return the default value."""
        return self.get_as[R=Int32, transform=get_int32](name)

    fn get_int64(self, name: String) -> Optional[Int64]:
        """Returns the value of a flag as a Int64. If it isn't set, then return the default value."""
        return self.get_as[R=Int64, transform=get_int64](name)

    fn get_uint8(self, name: String) -> Optional[UInt8]:
        """Returns the value of a flag as a UInt8. If it isn't set, then return the default value."""
        return self.get_as[R=UInt8, transform=get_uint8](name)

    fn get_uint16(self, name: String) -> Optional[UInt16]:
        """Returns the value of a flag as a UInt16. If it isn't set, then return the default value."""
        return self.get_as[R=UInt16, transform=get_uint16](name)

    fn get_uint32(self, name: String) -> Optional[UInt32]:
        """Returns the value of a flag as a UInt32. If it isn't set, then return the default value."""
        return self.get_as[R=UInt32, transform=get_uint32](name)

    fn get_uint64(self, name: String) -> Optional[UInt64]:
        """Returns the value of a flag as a UInt64. If it isn't set, then return the default value."""
        return self.get_as[R=UInt64, transform=get_uint64](name)

    fn as_float16(self, name: String) -> Optional[Float16]:
        """Returns the value of a flag as a Float64. If it isn't set, then return the default value."""
        return self.get_as[R=Float16, transform=as_float16](name)

    fn as_float32(self, name: String) -> Optional[Float32]:
        """Returns the value of a flag as a Float64. If it isn't set, then return the default value."""
        return self.get_as[R=Float32, transform=as_float32](name)

    fn as_float64(self, name: String) -> Optional[Float64]:
        """Returns the value of a flag as a Float64. If it isn't set, then return the default value."""
        return self.get_as[R=Float64, transform=as_float64](name)

    fn names(self) -> List[String]:
        """Returns a list of names of all flags in the flag set."""
        var result = List[String](capacity=len(self.flags))
        for flag in self.flags:
            result.append(flag[].name)
        return result

    fn shorthands(self) -> List[String]:
        """Returns a list of shorthands of all flags in the flag set."""
        var result = List[String](capacity=len(self.flags))
        for flag in self.flags:
            if flag[].shorthand:
                result.append(flag[].shorthand)
        return result

    fn bool_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: Bool = False,
    ) -> None:
        """Adds a `Bool` flag to the flag set."""
        self.flags.append(Flag(name=name, shorthand=shorthand, usage=usage, value=None, default=str(default), type="Bool"))

    fn string_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: String = "",
    ) -> None:
        """Adds a `String` flag to the flag set."""
        self.flags.append(Flag(name=name, shorthand=shorthand, usage=usage, value=None, default=str(default), type="String"))

    fn int_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int = 0) -> None:
        """Adds an `Int` flag to the flag set."""
        self.flags.append(Flag(name=name, shorthand=shorthand, usage=usage, value=None, default=str(default), type="Int"))

    fn int8_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int8 = 0) -> None:
        """Adds an `Int8` flag to the flag set."""
        self.flags.append(Flag(name=name, shorthand=shorthand, usage=usage, value=None, default=str(default), type="Int8"))

    fn int16_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int16 = 0) -> None:
        """Adds an `Int16` flag to the flag set."""
        self.flags.append(Flag(name=name, shorthand=shorthand, usage=usage, value=None, default=str(default), type="Int16"))

    fn int32_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int32 = 0) -> None:
        """Adds an `Int32` flag to the flag set."""
        self.flags.append(Flag(name=name, shorthand=shorthand, usage=usage, value=None, default=str(default), type="Int32"))

    fn int64_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int64 = 0) -> None:
        """Adds an `Int64` flag to the flag set."""
        self.flags.append(Flag(name=name, shorthand=shorthand, usage=usage, value=None, default=str(default), type="Int64"))

    fn uint8_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt8 = 0) -> None:
        """Adds a `UInt8` flag to the flag set."""
        self.flags.append(Flag(name=name, shorthand=shorthand, usage=usage, value=None, default=str(default), type="UInt8"))

    fn uint16_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt16 = 0) -> None:
        """Adds a `UInt16` flag to the flag set."""
        self.flags.append(Flag(name=name, shorthand=shorthand, usage=usage, value=None, default=str(default), type="UInt16"))

    fn uint32_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt32 = 0) -> None:
        """Adds a `UInt32` flag to the flag set."""
        self.flags.append(Flag(name=name, shorthand=shorthand, usage=usage, value=None, default=str(default), type="UInt32"))

    fn uint64_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt64 = 0) -> None:
        """Adds a `UInt64` flag to the flag set."""
        self.flags.append(Flag(name=name, shorthand=shorthand, usage=usage, value=None, default=str(default), type="UInt64"))

    fn float16_flag(inout self, name: String, usage: String, shorthand: String = "", default: Float16 = 0) -> None:
        """Adds a `Float16` flag to the flag set."""
        self.flags.append(Flag(name=name, shorthand=shorthand, usage=usage, value=None, default=str(default), type="Float16"))

    fn float32_flag(inout self, name: String, usage: String, shorthand: String = "", default: Float32 = 0) -> None:
        """Adds a `Float32` flag to the flag set."""
        self.flags.append(Flag(name=name, shorthand=shorthand, usage=usage, value=None, default=str(default), type="Float32"))

    fn float64_flag(inout self, name: String, usage: String, shorthand: String = "", default: Float64 = 0) -> None:
        """Adds a `Float64` flag to the flag set."""
        self.flags.append(Flag(name=name, shorthand=shorthand, usage=usage, value=None, default=str(default), type="Float64"))

    fn set_annotation(inout self, name: String, key: String, values: String) raises -> None:
        """Sets an annotation for a flag.

        Args:
            name: The name of the flag to set the annotation for.
            key: The key of the annotation.
            values: The values of the annotation.
        """
        var result = self.lookup(name)
        if not result:
            raise Error(String("FlagSet.set_annotation: Failed to find flag: {}.").format(name))

        # Annotation value can be a concatenated string of values.
        # Why? Because we can have multiple required groups of flags for example.
        # So each value of the list for the annotation can be a group of flag names.
        if not result.value()[].annotations.get(key):
            result.value()[].annotations[key] = List[String](values)
        else:
            result.value()[].annotations[key].extend(values)

    fn set_required(inout self, name: String) raises -> None:
        """Sets a flag as required or not.

        Args:
            name: The name of the flag to set as required.
        """
        try:
            self.set_annotation(name, REQUIRED, "true")
        except e:
            print(String("FlagSet.set_required: Failed to set flag, {}, to required.").format(name), file=2)
            raise e

    fn set_as[annotation_type: String](inout self, name: String, names: String) raises -> None:
        constrained[
            annotation_type not in [REQUIRED_AS_GROUP, ONE_REQUIRED, MUTUALLY_EXCLUSIVE],
            "annotation_type must be one of REQUIRED_AS_GROUP, ONE_REQUIRED, or MUTUALLY_EXCLUSIVE.",
        ]()
        try:
            self.set_annotation(name, annotation_type, names)
        except e:
            print(
                String(
                    "FlagSet.set_as: Failed to set flag, {}, with the following annotation: {}"
                ).format(name, annotation_type),
                file=2,
            )
            raise e

    fn visit_all[visitor: FlagVisitorFn](self) -> None:
        """Visits all flags in the flag set.

        Params:
            visitor: The visitor function to call for each flag.
        """
        for flag in self.flags:
            visitor(flag[])

    fn visit_all[visitor: FlagVisitorRaisingFn](self) raises -> None:
        """Visits all flags in the flag set.

        Params:
            visitor: The visitor function to call for each flag.
        """
        for flag in self.flags:
            visitor(flag[])

    fn merge(inout self, new_set: Self) -> None:
        """Adds flags from another FlagSet. If a flag is already present, the flag from the new set is ignored.

        Args:
            new_set: The flag set to add.
        """

        @always_inline
        fn add_flag(flag: Flag) capturing -> None:
            if not self.lookup(flag.name):
                self.flags.append(flag)

        new_set.visit_all[add_flag]()

    fn from_args(inout self, arguments: List[String]) raises -> List[String]:
        """Parses flags and args from the args passed via the command line and adds them to their appropriate collections.

        Args:
            arguments: The arguments passed via the command line.

        Returns:
            The remaining arguments after parsing out flags.
        """
        var parser = FlagParser()
        return parser.parse(self, arguments)


fn validate_required_flags(flags: FlagSet) raises -> None:
    """Validates all required flags are present and returns an error otherwise."""
    var missing_flag_names = List[String]()

    @parameter
    fn check_required_flag(flag: Flag) -> None:
        var required_annotation = flag.annotations.get(REQUIRED, List[String]())
        if required_annotation:
            if required_annotation[0] == "true" and not flag.changed:
                missing_flag_names.append(flag.name)

    flags.visit_all[check_required_flag]()

    if len(missing_flag_names) > 0:
        raise Error("required flag(s) " + missing_flag_names.__str__() + " not set")
