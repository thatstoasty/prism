import math.math


fn jaro_distance(a: String, b: String) -> Float64:
    """Measure of similarity between two strings. It returns a
    value between 0 and 1, where 1 indicates identical strings and 0 indicates
    completely different strings.

    Args:
        a: The first string.
        b: The second string.

    Returns:
        A value between 0 and 1, where 1 indicates identical strings and 0 indicates
        completely different strings.

    #### Notes:
        Adapted from: https://github.com/urfave/cli/blob/main/suggestions.go#L24."""

    if len(a) == 0 and len(b) == 0:
        return 1.0

    if len(a) == 0 or len(b) == 0:
        return 0.0

    var hash_a = List[Bool]()
    var hash_b = List[Bool]()
    hash_a.resize(len(a), False)
    hash_b.resize(len(b), False)

    var max_distance = Int(max(0, math.floor(max(len(a), len(b)) / 2.0) - 1))
    var matches = Float64(0)
    for i in range(len(a)):
        var start = Int(max(0, Float64(i - max_distance)))
        var end = Int(min(len(b) - 1, Float64(i + max_distance)))

        for j in range(start, end + 1):
            if hash_b[j]:
                continue
            if a[i] == b[j]:
                hash_a[i] = True
                hash_b[j] = True
                matches += 1.0
                break

    if matches == 0:
        return 0

    var transpositions = Float64(0)
    var j = 0
    for i in range(len(a)):
        if not hash_a[i]:
            continue
        while not hash_b[j]:
            j += 1
        if a[i] != b[j]:
            transpositions += 1.0
        j += 1

    transpositions /= 2.0
    return ((matches / len(a)) + (matches / len(b)) + ((matches - transpositions) / matches)) / 3.0


fn jaro_winkler(a: String, b: String) -> Float64:
    """Jaro-Winkler distance between two strings. It returns a value between 0 and 1,
    where 1 indicates identical strings and 0 indicates completely different strings.

    Args:
        a: The first string.
        b: The second string.

    Returns:
        A value between 0 and 1, where 1 indicates identical strings and 0 indicates
        completely different strings.

    #### Notes:
        Adapted from: https://github.com/urfave/cli/blob/main/suggestions.go#L82.
    """

    alias BOOST_THRESHOLD = 0.7
    alias PREFIX_SIZE = 4

    var jaro_dist = jaro_distance(a, b)
    if jaro_dist <= BOOST_THRESHOLD:
        return jaro_dist

    var prefix = Int(min(len(a), min(PREFIX_SIZE, len(b))))
    var prefix_match = Float64(0)
    for i in range(prefix):
        if a[i] == b[i]:
            prefix_match += 1.0
        else:
            break

    return jaro_dist + 0.1 * prefix_match * (1.0 - jaro_dist)


fn suggest_flag(flags: List[Flag], flag_name: String, hide_help: Bool = False) -> String:
    """Suggests a flag based on the provided string.

    Args:
        flags: The list of flags to suggest from.
        flag_name: The flag name to suggest from.
        hide_help: Whether to hide the help flag.

    Returns:
        The suggested flag.
    """
    # TODO: Implement hide_help and hide_version eventually.
    var distance = Float64(0)
    var suggestion = String("")

    for flag in flags:
        var flag_names = flag[].names()
        # if not hide_help and Flag.help_flag() != None:
        #     flag_names.append(Flag.help_flag().names())

        for name in flag_names:
            var new_distance = jaro_winkler(name[], flag_name)
            if new_distance > distance:
                distance = new_distance
                suggestion = name[]

    if len(suggestion) == 1:
        suggestion = String("-", suggestion)
    elif len(suggestion) > 1:
        suggestion = String("--", suggestion)

    return suggestion^


fn flag_from_error(error: Error) -> Optional[String]:
    """Returns the flag from the error message.

    Args:
        error: The error message to parse.

    Returns:
        The flag.
    """
    var message = String(error)
    var index = message.find("Name: ")
    if index == -1:
        return None

    return message[index + 6 :]
