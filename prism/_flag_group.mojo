from std.collections.dict import DictEntry


def validate_required_flag_group(data: Dict[String, Dict[String, Bool]]) raises -> None:
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
        for flag in pair.value.items():
            if not flag.value:
                unset.append(flag.key)

        if len(unset) == len(pair.value) or len(unset) == 0:
            continue

        raise Error(
            t"If any flags in the group, {extract_keys(pair.value)}, are set then all of the flags in the group must be set; missing {unset}.",
        )


def get_set_flags(flags: Dict[String, Bool]) -> List[String]:
    """Returns a list of flags that are set.

    Args:
        flags: The dictionary of flag names to if they're set or not.

    Returns:
        A list of flags that are set.
    """
    return [ flag.key for flag in flags.items() if flag.value ]


def extract_keys(flags: Dict[String, Bool]) -> List[String]:
    """Extracts the keys from a dictionary entry.

    Args:
        flags: The dictionary of flag names to if they're set or not.

    Returns:
        A list of keys.
    """
    var keys = [ key for key in flags.keys() ]
    sort(keys)
    return keys^


def validate_one_required_flag_group(data: Dict[String, Dict[String, Bool]]) raises -> None:
    """Validates that at least one flag in a group is set.
    This is for flags that are marked as required via `Command(one_required_flags=...)`.

    Args:
        data: The dictionary of flag groups to validate.

    Raises:
        Error: If an error occurred while validating the flag groups.
    """
    # Check if at least one key is set.
    for pair in data.items():
        var set = get_set_flags(pair.value)
        if len(set) >= 1:
            continue

        raise Error(t"At least one of the flags in the group, {extract_keys(pair.value)}, is required.")


def validate_mutually_exclusive_flag_group(data: Dict[String, Dict[String, Bool]]) raises -> None:
    """Validates that only one flag in a group is set.
    This is for flags that are marked as required via `Command(mutually_exclusive_flags=...)`.

    Args:
        data: The dictionary of flag groups to validate.

    Raises:
        Error: If an error occurred while validating the flag groups.
    """
    # Check if more than one mutually exclusive flag is set.
    for pair in data.items():
        var set = get_set_flags(pair.value)
        if len(set) == 0 or len(set) == 1:
            continue

        raise Error(
            t"If any flags in the group, {extract_keys(pair.value)}, are set none of the others can be; {set} were all set.",
        )
