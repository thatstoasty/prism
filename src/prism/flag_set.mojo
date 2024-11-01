from collections import Optional, Dict, InlineList
from utils import Variant
from memory import Reference
import gojo.fmt
from .flag import Flag, FlagActionFn
from .util import string_to_bool, string_to_float, split
from .flag_parser import FlagParser


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


@value
struct FlagSet(CollectionElement, Stringable, Sized, Boolable, EqualityComparable):
    var flags: List[Flag]

    fn __init__(inout self) -> None:
        self.flags = List[Flag]()

    fn __init__(inout self, other: FlagSet) -> None:
        self.flags = other.flags

    fn __str__(self) -> String:
        output = String()
        writer = output._unsafe_to_formatter()
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
        new = Self(self)
        for flag in other.flags:
            new.flags.append(flag[])
        return new

    fn __iadd__(inout self, other: Self):
        self.merge(other)

    fn lookup(ref [_]self, name: String, type: String = "") raises -> Reference[Flag, __lifetime_of(self.flags)]:
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
                    return self.flags[i]
        else:
            for i in range(len(self.flags)):
                if self.flags[i].name == name and self.flags[i].type == type:
                    return self.flags[i]

        raise Error("FlagNotFoundError: Could not find the following flag: " + name)

    fn lookup_name(self, shorthand: String) raises -> String:
        """Returns the name of a flag given its shorthand.

        Args:
            shorthand: The shorthand of the flag to lookup.
        """
        for flag in self.flags:
            if flag[].shorthand and flag[].shorthand == shorthand:
                return flag[].name

        raise Error("FlagNotFoundError: Could not find the following flag shorthand: " + shorthand)

    fn get_as[
        R: CollectionElement, transform: fn (flag_set: FlagSet, name: String) raises -> R
    ](self, name: String) raises -> R:
        return transform(self, name)

    fn get_string(self, name: String) raises -> String:
        """Returns the value of a flag as a String. If it isn't set, then return the default value."""
        return self.lookup(name, "String")[].value_or_default()

    fn get_bool(self, name: String) raises -> Bool:
        """Returns the value of a flag as a Bool. If it isn't set, then return the default value."""
        return string_to_bool(self.lookup(name, "Bool")[].value_or_default())

    fn get_int(self, name: String, type: String = "Int") raises -> Int:
        """Returns the value of a flag as an Int. If it isn't set, then return the default value."""
        return atol(self.lookup(name, type)[].value_or_default())

    fn get_int8(self, name: String) raises -> Int8:
        """Returns the value of a flag as a Int8. If it isn't set, then return the default value."""
        return Int8(self.get_int(name, "Int8"))

    fn get_int16(self, name: String) raises -> Int16:
        """Returns the value of a flag as a Int16. If it isn't set, then return the default value."""
        return Int16(self.get_int(name, "Int16"))

    fn get_int32(self, name: String) raises -> Int32:
        """Returns the value of a flag as a Int32. If it isn't set, then return the default value."""
        return Int32(self.get_int(name, "Int32"))

    fn get_int64(self, name: String) raises -> Int64:
        """Returns the value of a flag as a Int64. If it isn't set, then return the default value."""
        return Int64(self.get_int(name, "Int64"))

    fn get_uint8(self, name: String) raises -> UInt8:
        """Returns the value of a flag as a UInt8. If it isn't set, then return the default value."""
        return UInt8(self.get_int(name, "UInt8"))

    fn get_uint16(self, name: String) raises -> UInt16:
        """Returns the value of a flag as a UInt16. If it isn't set, then return the default value."""
        return UInt16(self.get_int(name, "UInt16"))

    fn get_uint32(self, name: String) raises -> UInt32:
        """Returns the value of a flag as a UInt32. If it isn't set, then return the default value."""
        return UInt32(self.get_int(name, "UInt32"))

    fn get_uint64(self, name: String) raises -> UInt64:
        """Returns the value of a flag as a UInt64. If it isn't set, then return the default value."""
        return UInt64(self.get_int(name, "UInt64"))

    fn get_float16(self, name: String) raises -> Float16:
        """Returns the value of a flag as a Float64. If it isn't set, then return the default value."""
        return self.get_float64(name).cast[DType.float16]()

    fn get_float32(self, name: String) raises -> Float32:
        """Returns the value of a flag as a Float64. If it isn't set, then return the default value."""
        return self.get_float64(name).cast[DType.float32]()

    fn get_float64(self, name: String) raises -> Float64:
        """Returns the value of a flag as a Float64. If it isn't set, then return the default value."""
        return string_to_float(self.lookup(name, "Float64")[].value_or_default())
    
    fn get_string_list(self, name: String) raises -> List[String]:
        """Returns the value of a flag as a List[String]. If it isn't set, then return the default value."""
        return self.lookup(name, "StringList")[].value_or_default().split(sep=" ")

    fn names(self) -> List[String]:
        """Returns a list of names of all flags in the flag set."""
        result = List[String](capacity=len(self.flags))
        for flag in self.flags:
            result.append(flag[].name)
        return result

    fn shorthands(self) -> List[String]:
        """Returns a list of shorthands of all flags in the flag set."""
        result = List[String](capacity=len(self.flags))
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
        environment_variable: Optional[StringLiteral] = None,
        file_path: Optional[StringLiteral] = None,
        action: Optional[FlagActionFn] = None,
    ) -> None:
        """Adds a `Bool` flag to the flag set."""
        self.flags.append(
            Flag(
                name=name,
                shorthand=shorthand,
                usage=usage,
                default=str(default),
                type="Bool",
                environment_variable=environment_variable,
                file_path=file_path,
                action=action,
            )
        )

    fn string_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: String = "",
        environment_variable: Optional[StringLiteral] = None,
        file_path: Optional[StringLiteral] = None,
        action: Optional[FlagActionFn] = None,
    ) -> None:
        """Adds a `String` flag to the flag set."""
        self.flags.append(
            Flag(
                name=name,
                shorthand=shorthand,
                usage=usage,
                default=str(default),
                type="String",
                environment_variable=environment_variable,
                file_path=file_path,
                action=action,
            )
        )

    fn int_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: Int = 0,
        environment_variable: Optional[StringLiteral] = None,
        file_path: Optional[StringLiteral] = None,
        action: Optional[FlagActionFn] = None,
    ) -> None:
        """Adds an `Int` flag to the flag set."""
        self.flags.append(
            Flag(
                name=name,
                shorthand=shorthand,
                usage=usage,
                default=str(default),
                type="Int",
                environment_variable=environment_variable,
                file_path=file_path,
                action=action,
            )
        )

    fn int8_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: Int8 = 0,
        environment_variable: Optional[StringLiteral] = None,
        file_path: Optional[StringLiteral] = None,
        action: Optional[FlagActionFn] = None,
    ) -> None:
        """Adds an `Int8` flag to the flag set."""
        self.flags.append(
            Flag(
                name=name,
                shorthand=shorthand,
                usage=usage,
                default=str(default),
                type="Int8",
                environment_variable=environment_variable,
                file_path=file_path,
                action=action,
            )
        )

    fn int16_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: Int16 = 0,
        environment_variable: Optional[StringLiteral] = None,
        file_path: Optional[StringLiteral] = None,
        action: Optional[FlagActionFn] = None,
    ) -> None:
        """Adds an `Int16` flag to the flag set."""
        self.flags.append(
            Flag(
                name=name,
                shorthand=shorthand,
                usage=usage,
                default=str(default),
                type="Int16",
                environment_variable=environment_variable,
                file_path=file_path,
                action=action,
            )
        )

    fn int32_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: Int32 = 0,
        environment_variable: Optional[StringLiteral] = None,
        file_path: Optional[StringLiteral] = None,
        action: Optional[FlagActionFn] = None,
    ) -> None:
        """Adds an `Int32` flag to the flag set."""
        self.flags.append(
            Flag(
                name=name,
                shorthand=shorthand,
                usage=usage,
                default=str(default),
                type="Int32",
                environment_variable=environment_variable,
                file_path=file_path,
                action=action,
            )
        )

    fn int64_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: Int64 = 0,
        environment_variable: Optional[StringLiteral] = None,
        file_path: Optional[StringLiteral] = None,
        action: Optional[FlagActionFn] = None,
    ) -> None:
        """Adds an `Int64` flag to the flag set."""
        self.flags.append(
            Flag(
                name=name,
                shorthand=shorthand,
                usage=usage,
                default=str(default),
                type="Int64",
                environment_variable=environment_variable,
                file_path=file_path,
                action=action,
            )
        )

    fn uint8_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: UInt8 = 0,
        environment_variable: Optional[StringLiteral] = None,
        file_path: Optional[StringLiteral] = None,
        action: Optional[FlagActionFn] = None,
    ) -> None:
        """Adds a `UInt8` flag to the flag set."""
        self.flags.append(
            Flag(
                name=name,
                shorthand=shorthand,
                usage=usage,
                default=str(default),
                type="UInt8",
                environment_variable=environment_variable,
                file_path=file_path,
                action=action,
            )
        )

    fn uint16_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: UInt16 = 0,
        environment_variable: Optional[StringLiteral] = None,
        file_path: Optional[StringLiteral] = None,
        action: Optional[FlagActionFn] = None,
    ) -> None:
        """Adds a `UInt16` flag to the flag set."""
        self.flags.append(
            Flag(
                name=name,
                shorthand=shorthand,
                usage=usage,
                default=str(default),
                type="UInt16",
                environment_variable=environment_variable,
                file_path=file_path,
                action=action,
            )
        )

    fn uint32_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: UInt32 = 0,
        environment_variable: Optional[StringLiteral] = None,
        file_path: Optional[StringLiteral] = None,
        action: Optional[FlagActionFn] = None,
    ) -> None:
        """Adds a `UInt32` flag to the flag set."""
        self.flags.append(
            Flag(
                name=name,
                shorthand=shorthand,
                usage=usage,
                default=str(default),
                type="UInt32",
                environment_variable=environment_variable,
                file_path=file_path,
                action=action,
            )
        )

    fn uint64_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: UInt64 = 0,
        environment_variable: Optional[StringLiteral] = None,
        file_path: Optional[StringLiteral] = None,
        action: Optional[FlagActionFn] = None,
    ) -> None:
        """Adds a `UInt64` flag to the flag set."""
        self.flags.append(
            Flag(
                name=name,
                shorthand=shorthand,
                usage=usage,
                default=str(default),
                type="UInt64",
                environment_variable=environment_variable,
                file_path=file_path,
                action=action,
            )
        )

    fn float16_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: Float16 = 0,
        environment_variable: Optional[StringLiteral] = None,
        file_path: Optional[StringLiteral] = None,
        action: Optional[FlagActionFn] = None,
    ) -> None:
        """Adds a `Float16` flag to the flag set."""
        self.flags.append(
            Flag(
                name=name,
                shorthand=shorthand,
                usage=usage,
                default=str(default),
                type="Float16",
                environment_variable=environment_variable,
                file_path=file_path,
                action=action,
            )
        )

    fn float32_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: Float32 = 0,
        environment_variable: Optional[StringLiteral] = None,
        file_path: Optional[StringLiteral] = None,
        action: Optional[FlagActionFn] = None,
    ) -> None:
        """Adds a `Float32` flag to the flag set."""
        self.flags.append(
            Flag(
                name=name,
                shorthand=shorthand,
                usage=usage,
                default=str(default),
                type="Float32",
                environment_variable=environment_variable,
                file_path=file_path,
                action=action,
            )
        )

    fn float64_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: Float64 = 0,
        environment_variable: Optional[StringLiteral] = None,
        file_path: Optional[StringLiteral] = None,
        action: Optional[FlagActionFn] = None,
    ) -> None:
        """Adds a `Float64` flag to the flag set."""
        self.flags.append(
            Flag(
                name=name,
                shorthand=shorthand,
                usage=usage,
                default=str(default),
                type="Float64",
                environment_variable=environment_variable,
                file_path=file_path,
                action=action,
            )
        )
    
    fn string_list_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: List[String] = List[String](),
        environment_variable: Optional[StringLiteral] = None,
        file_path: Optional[StringLiteral] = None,
        action: Optional[FlagActionFn] = None,
    ) -> None:
        """Adds a `StringList` flag to the flag set."""
        self.flags.append(
            Flag(
                name=name,
                shorthand=shorthand,
                usage=usage,
                default=" ".join(default),
                type="StringList",
                environment_variable=environment_variable,
                file_path=file_path,
                action=action,
            )
        )

    fn set_annotation(inout self, name: String, key: String, values: String) raises -> None:
        """Sets an annotation for a flag.

        Args:
            name: The name of the flag to set the annotation for.
            key: The key of the annotation.
            values: The values of the annotation.
        """
        # Annotation value can be a concatenated string of values.
        # Why? Because we can have multiple required groups of flags for example.
        # So each value of the list for the annotation can be a group of flag names.
        try:
            # TODO: remove running 2 lookups when ref can return a reference
            # we can store as a without copying the result.
            self.lookup(name)[].annotations[key].extend(values)
        except:
            self.lookup(name)[].annotations[key] = List[String](values)

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
                String("FlagSet.set_as: Failed to set flag, {}, with the following annotation: {}").format(
                    name, annotation_type
                ),
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
            try:
                _ = self.lookup(flag.name)
            except e:
                if str(e).find("FlagNotFoundError") != -1:
                    self.flags.append(flag)

        new_set.visit_all[add_flag]()

    fn from_args(inout self, arguments: List[String]) raises -> List[String]:
        """Parses flags and args from the args passed via the command line and adds them to their appropriate collections.

        Args:
            arguments: The arguments passed via the command line.

        Returns:
            The remaining arguments after parsing out flags.
        """
        parser = FlagParser()
        return parser.parse(self, arguments)


fn validate_required_flags(flags: FlagSet) raises -> None:
    """Validates all required flags are present and returns an error otherwise."""
    missing_flag_names = List[String]()

    @parameter
    fn check_required_flag(flag: Flag) -> None:
        required_annotation = flag.annotations.get(REQUIRED, List[String]())
        if required_annotation:
            if required_annotation[0] == "true" and not flag.changed:
                missing_flag_names.append(flag.name)

    flags.visit_all[check_required_flag]()

    if len(missing_flag_names) > 0:
        raise Error("Required flag(s): " + missing_flag_names.__str__() + " not set.")
