from collections import Optional, Dict, InlineList
from utils import Variant
from memory import Pointer
from .flag import Flag, FlagActionFn
from ._util import string_to_bool, split
from ._flag_parser import FlagParser


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
        flag[].annotations[key].extend(values)
    except:
        flag[].annotations[key] = List[String](values)


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

    visit_all[check_required_flag](flags)
    if len(missing_flag_names) > 0:
        raise Error("Required flag(s): " + missing_flag_names.__str__() + " not set.")


fn lookup[type: String = ""](ref flags: List[Flag], name: String) raises -> Pointer[Flag, __origin_of(flags)]:
    """Returns an mutable or immutable Pointer to a Flag with the given name.
    Mutable if FlagSet is mutable, immutable if FlagSet is immutable.

    Parameters:
        type: The type of the Flag to lookup.

    Args:
        flags: The flags to lookup.
        name: The name of the Flag to lookup.

    Returns:
        Optional Pointer to the Flag.

    Raises:
        Error: If the Flag is not found.
    """
    constrained[
        type not in ["String", "Bool", "Int", "Int8", "Int16", "Int32", "Int64", "UInt", "UInt8", "UInt16", "UInt32", "UInt64", "Float16", "Float32", "Float64", "StringList", "IntList", "Float64List"],
        "type must be one of `String`, `Bool`, `Int`, `Int8`, `Int16`, `Int32`, `Int64`, `UInt`, `UInt8`, `UInt16`, `UInt32`, `UInt64`, `Float16`, `Float32`, `Float64`, `StringList`, `IntList`, `Float64List`.",
    ]()
    if type == "":
        for i in range(len(flags)):
            if flags[i].name == name:
                return Pointer.address_of(flags[i])
    else:
        for i in range(len(flags)):
            print(flags[i].name, name, flags[i].name == name, flags[i].type, type, flags[i].type == type)
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
