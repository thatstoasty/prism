from collections import Dict
from .util import panic
from gojo import fmt


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
