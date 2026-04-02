from std.math import math
from prism.flag import Flag


def jaro_distance(a: StringSlice, b: StringSlice) -> Float64:
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

    var hash_a = List[Bool](length=len(a), fill=False)
    var hash_b = List[Bool](length=len(b), fill=False)

    var max_distance = Int(max(Float64(0), math.floor(Float64(max(len(a), len(b))) / 2.0) - 1))
    var matches: Float64 = 0.0
    for i in range(len(a)):
        var start = Int(max(Float64(0), Float64(i - max_distance)))
        var end = Int(min(Float64(len(b) - 1), Float64(i + max_distance)))

        for j in range(start, end + 1):
            if hash_b[j]:
                continue
            if a[byte=i:i+1] == b[byte=j:j+1]:
                hash_a[i] = True
                hash_b[j] = True
                matches += 1.0
                break

    if matches == 0:
        return 0

    var transpositions: Float64 = 0.0
    var j = 0
    for i in range(len(a)):
        if not hash_a[i]:
            continue
        while not hash_b[j]:
            j += 1
        if a[byte=i:i+1] != b[byte=j:j+1]:
            transpositions += 1.0
        j += 1

    transpositions /= 2.0
    return ((matches / Float64(len(a))) + (matches / Float64(len(b))) + ((matches - transpositions) / matches)) / 3.0


def jaro_winkler(a: StringSlice, b: StringSlice) -> Float64:
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

    comptime BOOST_THRESHOLD = 0.7
    comptime PREFIX_SIZE = 4

    var jaro_dist = jaro_distance(a, b)
    if jaro_dist <= BOOST_THRESHOLD:
        return jaro_dist

    var prefix = Int(min(len(a), min(PREFIX_SIZE, len(b))))
    var prefix_match: Float64 = 0.0
    for i in range(prefix):
        if a[byte=i:i+1] == b[byte=i:i+1]:
            prefix_match += 1.0
        else:
            break

    return jaro_dist + 0.1 * prefix_match * (1.0 - jaro_dist)


def suggest_flag[origin: ImmutOrigin, //](flags: Span[Flag, origin], flag_name: StringSlice, *, hide_help: Bool = False) -> String:
    """Suggests a flag based on the provided string.

    Args:
        flags: The list of flags to suggest from.
        flag_name: The flag name to suggest from.
        hide_help: Whether to hide the help flag.

    Returns:
        The suggested flag.
    """
    # TODO: Implement hide_help and hide_version eventually.
    var distance: Float64 = 0.0
    var suggestion = String()

    for flag in flags:
        for name in flag.names():
            var new_distance = jaro_winkler(name, flag_name)
            if new_distance > distance:
                distance = new_distance
                suggestion = name

    if len(suggestion) == 1:
        suggestion = String("-", suggestion)
    elif len(suggestion) > 1:
        suggestion = String("--", suggestion)

    return suggestion^


def flag_from_error(error: Error) -> Optional[String]:
    """Returns the flag from the error message.

    Args:
        error: The error message to parse.

    Returns:
        The flag.
    """
    var error_str = String(error)
    var index = error_str.find("Name: ")
    if index == -1:
        return None

    return String(error_str[byte=index + 6 :])
