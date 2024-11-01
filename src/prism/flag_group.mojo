from collections import Dict
from os import abort
from .flag import Flag
from .flag_set import REQUIRED, REQUIRED_AS_GROUP, ONE_REQUIRED, MUTUALLY_EXCLUSIVE
from gojo import fmt


fn has_all_flags(flags: FlagSet, flag_names: List[String]) -> Bool:
    for name in flag_names:
        try:
            _ = flags.lookup(name[])
        except:
            return False
    return True


fn process_flag_for_group_annotation(
    flags: FlagSet,
    flag: Flag,
    annotation: String,
    inout group_status: Dict[String, Dict[String, Bool]],
) raises -> None:
    group_info = flag.annotations.get(annotation, List[String]())
    if group_info:
        for group in group_info:
            group_name = group[]
            if len(group_status.get(group_name, Dict[String, Bool]())) == 0:
                flag_names = group_name.split(sep=" ")

                # Only consider this flag group at all if all the flags are defined.
                if not has_all_flags(flags, flag_names):
                    continue

                for name in flag_names:
                    entry = Dict[String, Bool]()
                    entry[name[]] = False
                    group_status[group[]] = entry

            # If flag.changed = True, then it had a value set on it.
            try:
                group_status[group[]][flag.name] = flag.changed
            except e:
                raise Error(
                    String(
                        "process_flag_for_group_annotation: Failed to set group status for annotation {}: {}."
                    ).format(annotation, str(e))
                )


fn validate_required_flag_group(data: Dict[String, Dict[String, Bool]]) -> None:
    """Validates that all flags in a group are set if any are set.
    This is for flags that are marked as required via `Command().mark_flags_required_together()`.

    Args:
        data: The dictionary of flag groups to validate.
    """
    # Within each group, is a Dict of flag name and if they're set.
    # If it's unset then add to a list to check the condition of all required flags being set.
    for pair in data.items():
        unset = List[String]()
        for flag in pair[].value.items():
            if not flag[].value:
                unset.append(flag[].key)

        if len(unset) == len(pair[].value) or len(unset) == 0:
            continue

        # Sort values, so they can be tested/scripted against consistently.
        # unset.sort()
        keys = List[String]()
        for key in pair[].value.keys():
            keys.append(key[])

        abort(
            fmt.sprintf(
                "If any flags in the group, %s, are set they must all be set; missing %s.",
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
        set = List[String]()
        for flag in pair[].value.items():
            if flag[].value:
                set.append(flag[].key)

        if len(set) >= 1:
            continue

        # Sort values, so they can be tested/scripted against consistently.
        # unset.sort()
        keys = List[String]()
        for key in pair[].value.keys():
            keys.append(key[])

        abort(fmt.sprintf("At least one of the flags in the group %s is required.", keys.__str__()))


fn validate_mutually_exclusive_flag_group(data: Dict[String, Dict[String, Bool]]) -> None:
    """Validates that only one flag in a group is set.
    This is for flags that are marked as required via `Command().mark_flags_mutually_exclusive()`.

    Args:
        data: The dictionary of flag groups to validate.
    """
    # Check if more than one mutually exclusive flag is set.
    for pair in data.items():
        set = List[String]()
        for flag in pair[].value.items():
            if flag[].value:
                set.append(flag[].key)

        if len(set) == 0 or len(set) == 1:
            continue

        # Sort values, so they can be tested/scripted against consistently.
        # unset.sort()
        keys = List[String]()
        for key in pair[].value.keys():
            keys.append(key[])

        abort(
            fmt.sprintf(
                "If any flags in the group %s are set none of the others can be; %s were all set.",
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


fn validate_flag_groups(flags: FlagSet) raises -> None:
    group_status = Dict[String, Dict[String, Bool]]()
    one_required_group_status = Dict[String, Dict[String, Bool]]()
    mutually_exclusive_group_status = Dict[String, Dict[String, Bool]]()

    @parameter
    fn flag_checker(flag: Flag) raises -> None:
        process_flag_for_group_annotation(flags, flag, REQUIRED_AS_GROUP, group_status)
        process_flag_for_group_annotation(flags, flag, ONE_REQUIRED, one_required_group_status)
        process_flag_for_group_annotation(flags, flag, MUTUALLY_EXCLUSIVE, mutually_exclusive_group_status)

    flags.visit_all[flag_checker]()

    # Validate required flag groups
    validate_flag_groups(group_status, one_required_group_status, mutually_exclusive_group_status)
