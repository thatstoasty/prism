from collections.dict import Dict, DictEntry
from .flag import Flag
from ._flag_set import REQUIRED, REQUIRED_AS_GROUP, ONE_REQUIRED, MUTUALLY_EXCLUSIVE, visit_all, names
from ._util import panic


fn has_all_flags(flags: List[Flag], owned flag_names: List[String]) -> Bool:
    """Checks if all flags are defined in the flag set.

    Args:
        flags: The command's flags to check.
        flag_names: The names of the flags to check for.

    Returns:
        True if all flags are defined, False otherwise.
    """
    var names = names(flags)
    for name in flag_names:
        if name[] not in names:
            return False
    return True


fn process_group_annotations[annotation: String](
    flags: List[Flag],
    flag: Flag,
    mut group_status: Dict[String, Dict[String, Bool]],
) raises -> None:
    """Processes a flag for a group annotation.

    Parameters:
        annotation: The annotation to check for.

    Args:
        flags: The flag set to check for the flags.
        flag: The flag to process.
        group_status: The status of the flag groups.

    Raises:
        Error: If an error occurred while processing the flag.
    """
    var fg_annotations = flag.annotations.get(annotation, List[String]())
    if not fg_annotations:
        return

    for group in fg_annotations:
        if len(group_status.get(group[], Dict[String, Bool]())) == 0:
            var flag_names = group[].split(sep=" ")

            # Only consider this flag group at all if all the flags are defined.
            if not has_all_flags(flags, flag_names):
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
                    annotation, str(e)
                )
            )


fn validate_required_flag_group(data: Dict[String, Dict[String, Bool]]) raises -> None:
    """Validates that all flags in a group are set if any are set.
    This is for flags that are marked as required via `Command(flags_required_together=...)`.

    Args:
        data: The dictionary of flag groups to validate.

    Raises:
        Error: If an error occurred while validating the flag groups.
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

        var keys = extract_keys(pair[])
        alias msg = "If any flags in the group, {}, are set they must all be set; missing {}."
        panic(msg.format(keys.__str__(), unset.__str__()))


fn get_set_flags(pair: DictEntry[String, Dict[String, Bool]]) -> List[String]:
    """Returns a list of flags that are set.

    Args:
        pair: The key value pair to check.

    Returns:
        A list of flags that are set.
    """
    var set = List[String]()
    for flag in pair.value.items():
        if flag[].value:
            set.append(flag[].key)
    return set


fn extract_keys(pair: DictEntry[String, Dict[String, Bool]]) -> List[String]:
    """Extracts the keys from a dictionary entry.

    Args:
        pair: The key value pair to extract the keys from.
    
    Returns:
        A list of keys.
    """
    var keys = List[String]()
    for key in pair.value.keys():
        keys.append(key[])
    sort(keys)
    return keys


fn validate_one_required_flag_group(data: Dict[String, Dict[String, Bool]]) raises -> None:
    """Validates that at least one flag in a group is set.
    This is for flags that are marked as required via `Command(one_required_flags=...)`.

    Args:
        data: The dictionary of flag groups to validate.

    Raises:
        Error: If an error occurred while validating the flag groups.
    """
    # Check if at least one key is set.
    for pair in data.items():
        var set = get_set_flags(pair[])
        if len(set) >= 1:
            continue

        var keys = extract_keys(pair[])
        panic("At least one of the flags in the group {} is required.".format(keys.__str__()))


fn validate_mutually_exclusive_flag_group(data: Dict[String, Dict[String, Bool]]) raises -> None:
    """Validates that only one flag in a group is set.
    This is for flags that are marked as required via `Command(mutually_exclusive_flags=...)`.

    Args:
        data: The dictionary of flag groups to validate.

    Raises:
        Error: If an error occurred while validating the flag groups.
    """
    # Check if more than one mutually exclusive flag is set.
    for pair in data.items():
        var set = get_set_flags(pair[])
        if len(set) == 0 or len(set) == 1:
            continue

        var keys = extract_keys(pair[])
        alias msg = "If any flags in the group {} are set none of the others can be; {} were all set."
        panic(msg.format(keys.__str__(), set.__str__()))


fn validate_flag_groups(flags: List[Flag]) raises -> None:
    """Validates the status of flag groups.
    Checks for flags annotated with the `REQUIRED_AS_GROUP`, `ONE_REQUIRED`, or `MUTUALLY_EXCLUSIVE` annotations.
    Then validates if the flags in the group are set correctly to satisfy the annotation.

    Args:
        flags: The flags to validate.

    Raises:
        Error: If an error occurred while validating the flag groups.
    """
    var group_status = Dict[String, Dict[String, Bool]]()
    var one_required_group_status = Dict[String, Dict[String, Bool]]()
    var mutually_exclusive_group_status = Dict[String, Dict[String, Bool]]()

    @parameter
    fn flag_checker(flag: Flag) raises -> None:
        process_group_annotations[REQUIRED_AS_GROUP](flags, flag, group_status)
        process_group_annotations[ONE_REQUIRED](flags, flag, one_required_group_status)
        process_group_annotations[MUTUALLY_EXCLUSIVE](flags, flag, mutually_exclusive_group_status)

    visit_all[flag_checker](flags)

    # Validate required flag groups
    validate_required_flag_group(group_status)
    validate_one_required_flag_group(one_required_group_status)
    validate_mutually_exclusive_flag_group(mutually_exclusive_group_status)
