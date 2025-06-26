from collections.dict import DictEntry
from prism.flag import Flag
from prism._flag_set import FlagSet, Annotation


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
        for flag in pair.value.items():
            if not flag.value:
                unset.append(flag.key)

        if len(unset) == len(pair.value) or len(unset) == 0:
            continue

        var keys = extract_keys(pair)
        raise Error(
            "If any flags in the group, ",
            keys.__str__(),
            "are set they must all be set; missing ",
            unset.__str__(),
            ".",
        )


fn get_set_flags(pair: DictEntry[String, Dict[String, Bool]]) -> List[String]:
    """Returns a list of flags that are set.

    Args:
        pair: The key value pair to check.

    Returns:
        A list of flags that are set.
    """
    var set = List[String]()
    for flag in pair.value.items():
        if flag.value:
            set.append(flag.key)
    return set^


fn extract_keys(pair: DictEntry[String, Dict[String, Bool]]) -> List[String]:
    """Extracts the keys from a dictionary entry.

    Args:
        pair: The key value pair to extract the keys from.

    Returns:
        A list of keys.
    """
    var keys = List[String]()
    for key in pair.value.keys():
        keys.append(key)
    sort(keys)
    return keys^


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
        var set = get_set_flags(pair)
        if len(set) >= 1:
            continue

        var keys = extract_keys(pair)
        raise Error(StaticString("At least one of the flags in the group {} is required.").format(keys.__str__()))


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
        var set = get_set_flags(pair)
        if len(set) == 0 or len(set) == 1:
            continue

        var keys = extract_keys(pair)
        alias msg = StaticString("If any flags in the group {} are set none of the others can be; {} were all set.")
        raise Error(msg.format(keys.__str__(), set.__str__()))
