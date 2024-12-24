from collections import Optional, Dict, InlineList
from utils import Variant
from memory import Pointer
from .flag import Flag, FlagActionFn
from .util import string_to_bool, split
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


# @value
# struct FlagSet(CollectionElement, Stringable, Sized, Boolable, EqualityComparable):
#     """Represents a set of flags."""

#     var flags: List[Flag]
#     """The list of flags in the flag set."""

#     fn __init__(mut self) -> None:
#         """Initializes a new FlagSet."""
#         self.flags = List[Flag]()

#     fn __init__(mut self, other: FlagSet) -> None:
#         """Initializes a new FlagSet from another FlagSet.

#         Args:
#             other: The other FlagSet to copy from.
#         """
#         self.flags = other.flags

#     fn __str__(self) -> String:
#         """Returns a string representation of the FlagSet.

#         Returns:
#             The string representation of the FlagSet.
#         """
#         return String.write(self)

#     fn write_to[W: Writer, //](self, mut writer: W):
#         """Write a string representation to a writer.

#         Parameters:
#             W: The type of writer to write to.

#         Args:
#             writer: The writer to write to.
#         """
#         writer.write("FlagSet: [")
#         for i in range(self.flags.size):
#             writer.write(self.flags[i])
#             if i != self.flags.size - 1:
#                 writer.write(", ")
#         writer.write("]")

#     fn __len__(self) -> Int:
#         """Returns the number of flags in the flag set.

#         Returns:
#             The number of flags in the flag set.
#         """
#         return self.flags.size

#     fn __bool__(self) -> Bool:
#         """Returns whether the flag set is empty.

#         Returns:
#             Whether the flag set is empty.
#         """
#         return self.flags.__bool__()

#     fn __contains__(self, value: Flag) -> Bool:
#         """Returns whether the flag set contains a flag.

#         Args:
#             value: The flag to check for.

#         Returns:
#             Whether the flag set contains the flag.
#         """
#         return value in self.flags

#     fn __eq__(self, other: Self) -> Bool:
#         """Compares two FlagSets for equality.

#         Args:
#             other: The other FlagSet to compare against.

#         Returns:
#             True if the FlagSets are equal, False otherwise.
#         """
#         return self.flags == other.flags

#     fn __ne__(self, other: Self) -> Bool:
#         """Compares two FlagSets for inequality.

#         Args:
#             other: The other FlagSet to compare against.

#         Returns:
#             True if the FlagSets are not equal, False otherwise.
#         """
#         return self.flags != other.flags

#     fn __add__(mut self, other: Self) -> Self:
#         """Merges two FlagSets together.

#         Args:
#             other: The other FlagSet to merge with.

#         Returns:
#             A new FlagSet with the merged flags.
#         """
#         new = Self(self)
#         for flag in other.flags:
#             new.flags.append(flag[])
#         return new

#     fn __iadd__(mut self, other: Self):
#         """Merges another FlagSet into this FlagSet.

#         Args:
#             other: The other FlagSet to merge with.
#         """
#         self.merge(other)

#     fn merge(mut self, new_set: Self) -> None:
#         """Adds flags from another FlagSet. If a flag is already present, the flag from the new set is ignored.

#         Args:
#             new_set: The flag set to add.
#         """

#         @always_inline
#         fn add_flag(flag: Flag) capturing -> None:
#             try:
#                 _ = self.lookup(flag.name)
#             except e:
#                 if str(e).find("FlagNotFoundError") != -1:
#                     self.flags.append(flag)

#         visit_all[add_flag](new_set.flags)


fn set_annotation(mut flags: List[Flag], name: String, key: String, values: String) raises -> None:
    """Sets an annotation for a flag.

    Args:
        flags: The flags to set the annotation for.
        name: The name of the flag to set the annotation for.
        key: The key of the annotation.
        values: The values of the annotation.

    Raises:
        Error: If setting the value for the annotation fails.
    """
    # Annotation value can be a concatenated string of values.
    # Why? Because we can have multiple required groups of flags for example.
    # So each value of the list for the annotation can be a group of flag names.
    var flag = lookup(flags, name)
    try:
        # TODO: remove running 2 lookups when ref can return a Pointer
        # we can store as a without copying the result.
        flag[].annotations[key].extend(values)
    except:
        flag[].annotations[key] = List[String](values)


fn set_required(mut flags: List[Flag], name: String) raises -> None:
    """Sets a flag as required or not.

    Args:
        flags: The flags to set the required flag for.
        name: The name of the flag to set as required.

    Raises:
        Error: If setting the value for the annotation fails.
    """
    try:
        set_annotation(flags, name, REQUIRED, "true")
    except e:
        print("FlagSet.set_required: Failed to set flag, {}, to required.".format(name), file=2)
        raise e


fn set_as[annotation_type: String](mut flags: List[Flag], name: String, names: String) raises -> None:
    """Sets a flag as a specific annotation type.

    Parameters:
        annotation_type: The type of annotation to set.

    Args:
        flags: The flags to set the annotation for.
        name: The name of the flag to set the annotation for.
        names: The values of the annotation.

    Raises:
        Error: If the annotation type is not one of `REQUIRED_AS_GROUP`, `ONE_REQUIRED`, or `MUTUALLY_EXCLUSIVE`.
    """
    constrained[
        annotation_type not in [REQUIRED_AS_GROUP, ONE_REQUIRED, MUTUALLY_EXCLUSIVE],
        "annotation_type must be one of REQUIRED_AS_GROUP, ONE_REQUIRED, or MUTUALLY_EXCLUSIVE.",
    ]()
    try:
        set_annotation(flags, name, annotation_type, names)
    except e:
        print(
            "FlagSet.set_as: Failed to set flag, {}, with the following annotation: {}".format(name, annotation_type),
            file=2,
        )
        raise e


fn from_args(mut flags: List[Flag], arguments: List[String]) raises -> List[String]:
    """Parses flags and args from the args passed via the command line and adds them to their appropriate collections.

    Args:
        flags: The flags to parse.
        arguments: The arguments passed via the command line.

    Returns:
        The remaining arguments after parsing out flags.

    Raises:
        Error: If a flag is not recognized.
    """
    var parser = FlagParser()
    return parser.parse(flags, arguments)


fn names(flags: List[Flag]) -> List[String]:
    """Returns a list of names of all flags in the flag set.

    Args:
        flags: The flags to get the names for.

    Returns:
        A list of names of all flags in the flag set.
    """
    var result = List[String](capacity=len(flags))
    for flag in flags:
        result.append(flag[].name)
    return result


fn shorthands(flags: List[Flag]) -> List[String]:
    """Returns a list of shorthands of all flags in the flag set.

    Args:
        flags: The flags to get the shorthands for.

    Returns:
        A list of shorthands of all flags in the flag set.
    """
    var result = List[String](capacity=len(flags))
    for flag in flags:
        if flag[].shorthand:
            result.append(flag[].shorthand)
    return result


fn visit_all[visitor: FlagVisitorFn](flags: List[Flag]) -> None:
    """Visits all flags in the flag set.

    Parameters:
        visitor: The visitor function to call for each flag.
    """
    for flag in flags:
        visitor(flag[])


fn visit_all[visitor: FlagVisitorRaisingFn](flags: List[Flag]) raises -> None:
    """Visits all flags in the flag set.

    Parameters:
        visitor: The visitor function to call for each flag.

    Raises:
        Error: If the visitor raises an error.
    """
    for flag in flags:
        visitor(flag[])


fn validate_required_flags(flags: List[Flag]) raises -> None:
    """Validates all required flags are present and returns an error otherwise.

    Args:
        flags: The flags to validate.

    Raises:
        Error: If a required flag is not set.
    """
    var missing_flag_names = List[String]()

    @parameter
    fn check_required_flag(flag: Flag) -> None:
        if flag.required and not flag.changed:
            missing_flag_names.append(flag.name)
        # var required_annotation = flag.annotations.get(REQUIRED, List[String]())
        # if required_annotation:
        #     if required_annotation[0] == "true" and not flag.changed:
        #         missing_flag_names.append(flag.name)

    visit_all[check_required_flag](flags)

    if len(missing_flag_names) > 0:
        raise Error("Required flag(s): " + missing_flag_names.__str__() + " not set.")


fn lookup(ref flags: List[Flag], name: String, type: String = "") raises -> Pointer[Flag, __origin_of(flags)]:
    """Returns an mutable or immutable Pointer to a Flag with the given name.
    Mutable if FlagSet is mutable, immutable if FlagSet is immutable.

    Args:
        flags: The flags to lookup.
        name: The name of the Flag to lookup.
        type: The type of the Flag to lookup.

    Returns:
        Optional Pointer to the Flag.

    Raises:
        Error: If the Flag is not found.
    """
    if type == "":
        for i in range(len(flags)):
            if flags[i].name == name:
                return Pointer.address_of(flags[i])
    else:
        for i in range(len(flags)):
            if flags[i].name == name and flags[i].type == type:
                return Pointer.address_of(flags[i])

    raise Error("FlagNotFoundError: Could not find the following flag: " + name)


fn lookup_name(flags: List[Flag], shorthand: String) raises -> String:
    """Returns the name of a flag given its shorthand.

    Args:
        flags: The flags to lookup.
        shorthand: The shorthand of the flag to lookup.

    Returns:
        The name of the flag.

    Raises:
        Error: If the flag is not found.
    """
    for flag in flags:
        if flag[].shorthand and flag[].shorthand == shorthand:
            return flag[].name

    raise Error("FlagNotFoundError: Could not find the following flag shorthand: " + shorthand)


fn string_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: String = "",
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `String` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=str(default),
        type="String",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn bool_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: Bool = False,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `Bool` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=str(default),
        type="Bool",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn int_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: Int = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds an `Int` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=str(default),
        type="Int",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn int8_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: Int8 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds an `Int8` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=str(default),
        type="Int8",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn int16_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: Int16 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds an `Int16` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=str(default),
        type="Int16",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn int32_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: Int32 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds an `Int32` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=str(default),
        type="Int32",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn int64_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: Int64 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds an `Int64` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=str(default),
        type="Int64",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn uint_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: UInt8 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `UInt` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=str(default),
        type="UInt",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn uint8_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: UInt8 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `UInt8` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=str(default),
        type="UInt8",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn uint16_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: UInt16 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `UInt16` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=str(default),
        type="UInt16",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn uint32_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: UInt32 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `UInt32` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=str(default),
        type="UInt32",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn uint64_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: UInt64 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `UInt64` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=str(default),
        type="UInt64",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn float16_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: Float16 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `Float16` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=str(default),
        type="Float16",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn float32_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: Float32 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `Float32` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=str(default),
        type="Float32",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn float64_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: Float64 = 0,
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `Float64` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=str(default),
        type="Float64",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn string_list_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: List[String] = List[String](),
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `StringList` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=" ".join(default),
        type="StringList",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn int_list_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: List[Int, True] = List[Int, True](),
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `IntList` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=" ".join(default),
        type="IntList",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )


fn float64_list_flag(
    name: String,
    usage: String,
    shorthand: String = "",
    default: List[Float64, True] = List[Float64, True](),
    environment_variable: Optional[StringLiteral] = None,
    file_path: Optional[StringLiteral] = None,
    action: Optional[FlagActionFn] = None,
    required: Bool = False,
    persistent: Bool = False,
) -> Flag:
    """Adds a `Float64List` flag to the flag set.

    Args:
        name: The name of the flag.
        usage: The usage of the flag.
        shorthand: The shorthand of the flag.
        default: The default value of the flag.
        environment_variable: The environment variable to check for a value.
        file_path: The file to check for a value.
        action: Function to run after the flag has been processed.
        required: If the flag is required.
        persistent: If the flag should persist to children commands.
    """
    return Flag(
        name=name,
        shorthand=shorthand,
        usage=usage,
        default=" ".join(default),
        type="Float64List",
        environment_variable=environment_variable,
        file_path=file_path,
        action=action,
        required=required,
        persistent=persistent,
    )
