"""Fuzzy matching used to suggest a flag or subcommand after a typo."""

from std.math import math
from prism.flag import Flag
from prism._util import UNKNOWN_FLAG_ERROR


comptime SUGGESTION_THRESHOLD = 0.6
"""Minimum Jaro-Winkler similarity before a correction is worth offering.

Sharing no characters already scores 0.0, but a weak partial match does not: against a command
whose only flag is `--help`, `--verbos` scores 0.47 and would be answered with "did you mean
--help?". Offering nothing is better than offering something the user plainly did not mean.
"""


def _grapheme_offsets(s: StringSpan) -> List[Int]:
    """Returns the byte offset at which each grapheme starts, with a sentinel at the end.

    Args:
        s: The string to scan.

    Returns:
        `count + 1` offsets, so grapheme `i` spans `[result[i], result[i + 1])`.
    """
    var offsets = List[Int]()
    var offset = 0
    for grapheme in s.graphemes():
        offsets.append(offset)
        offset += grapheme.byte_length()
    offsets.append(offset)
    return offsets^


def _jaro_distance(a: StringSpan, a_offsets: List[Int], b: StringSpan, b_offsets: List[Int]) -> Float64:
    """Jaro distance between two strings whose grapheme boundaries have already been located.

    Args:
        a: The first string.
        a_offsets: Grapheme offsets for `a`, from `_grapheme_offsets`.
        b: The second string.
        b_offsets: Grapheme offsets for `b`, from `_grapheme_offsets`.

    Returns:
        A value between 0 and 1, where 1 indicates identical strings.

    #### Notes:
    - Indexing a string by grapheme rescans it from the start, so doing that inside these nested
      loops made the comparison cubic in the string length. Slicing by a precomputed byte offset
      is constant time.
    """
    var a_count = len(a_offsets) - 1
    var b_count = len(b_offsets) - 1
    if a_count == 0 and b_count == 0:
        return 1.0
    if a_count == 0 or b_count == 0:
        return 0.0

    var hash_a = List[Bool](length=a_count, fill=False)
    var hash_b = List[Bool](length=b_count, fill=False)

    var max_distance = Int(max(Float64(0), math.floor(Float64(max(a_count, b_count)) / 2.0) - 1))
    var matches: Float64 = 0.0
    for i in range(a_count):
        var start = Int(max(Float64(0), Float64(i - max_distance)))
        var end = Int(min(Float64(b_count - 1), Float64(i + max_distance)))

        for j in range(start, end + 1):
            if hash_b[j]:
                continue
            if a[byte = a_offsets[i] : a_offsets[i + 1]] == b[byte = b_offsets[j] : b_offsets[j + 1]]:
                hash_a[i] = True
                hash_b[j] = True
                matches += 1.0
                break

    if matches == 0:
        return 0

    var transpositions: Float64 = 0.0
    var j = 0
    for i in range(a_count):
        if not hash_a[i]:
            continue
        while not hash_b[j]:
            j += 1
        if a[byte = a_offsets[i] : a_offsets[i + 1]] != b[byte = b_offsets[j] : b_offsets[j + 1]]:
            transpositions += 1.0
        j += 1

    transpositions /= 2.0
    return (
        (matches / Float64(a_count)) + (matches / Float64(b_count)) + ((matches - transpositions) / matches)
    ) / 3.0


def jaro_distance(a: StringSpan, b: StringSpan) -> Float64:
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
    return _jaro_distance(a, _grapheme_offsets(a), b, _grapheme_offsets(b))


def jaro_winkler(a: StringSpan, b: StringSpan) -> Float64:
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

    # Locate grapheme boundaries once and share them with the prefix scan below.
    var a_offsets = _grapheme_offsets(a)
    var b_offsets = _grapheme_offsets(b)

    var jaro_dist = _jaro_distance(a, a_offsets, b, b_offsets)
    if jaro_dist <= BOOST_THRESHOLD:
        return jaro_dist

    var prefix = min(len(a_offsets) - 1, min(PREFIX_SIZE, len(b_offsets) - 1))
    var prefix_match: Float64 = 0.0
    for i in range(prefix):
        if a[byte = a_offsets[i] : a_offsets[i + 1]] == b[byte = b_offsets[i] : b_offsets[i + 1]]:
            prefix_match += 1.0
        else:
            break

    return jaro_dist + 0.1 * prefix_match * (1.0 - jaro_dist)


def suggest_name[origin: ImmOrigin, //](candidates: Span[String, origin], name: StringSpan) -> String:
    """Suggests the closest match to a name from a list of candidates.

    Args:
        candidates: The names to choose from.
        name: The name the user supplied.

    Returns:
        The closest candidate, or an empty string when none of them resemble `name`.

    #### Notes:
    - Candidates sharing no characters with `name` score 0.0 and are never suggested, so an
      unrecognizable input yields no suggestion rather than an arbitrary one.
    """
    var distance = SUGGESTION_THRESHOLD
    var suggestion = String()

    for candidate in candidates:
        var new_distance = jaro_winkler(candidate, name)
        if new_distance > distance:
            distance = new_distance
            suggestion = candidate

    return suggestion^


def suggest_flag[origin: ImmOrigin, //](flags: Span[Flag, origin], flag_name: StringSpan, *, hide_help: Bool = False) -> String:
    """Suggests a flag based on the provided string.

    Args:
        flags: The list of flags to suggest from.
        flag_name: The flag name to suggest from.
        hide_help: Whether to hide the help flag.

    Returns:
        The suggested flag.
    """
    # TODO: Implement hide_help and hide_version eventually.
    # A one-character shorthand scores spuriously high against any longer string that happens to
    # contain that character, because the `matches / len(a)` term of the Jaro distance is 1.0 when
    # `a` is a single character: `count` scores 0.73 against the shorthand `o`. Only weigh
    # shorthands when the user typed a single character too, which is the only time a shorthand is
    # a plausible thing to have meant.
    var compare_shorthands = flag_name.count_graphemes() == 1
    var distance = SUGGESTION_THRESHOLD
    var suggestion = String()

    for flag in flags:
        var name_distance = jaro_winkler(flag.name, flag_name)
        if name_distance > distance:
            distance = name_distance
            suggestion = flag.name

        if compare_shorthands and flag.shorthand:
            var shorthand_distance = jaro_winkler(flag.shorthand, flag_name)
            if shorthand_distance > distance:
                distance = shorthand_distance
                suggestion = flag.shorthand

    # Prefix by codepoint count, not byte length, so a non-ASCII shorthand is not mistaken for a
    # long name and rendered as `--é`.
    var graphemes = suggestion.count_graphemes()
    if graphemes == 1:
        suggestion = String("-", suggestion)
    elif graphemes > 1:
        suggestion = String("--", suggestion)

    return suggestion^


def flag_from_error(error: Error) -> Optional[String]:
    """Returns the flag from the error message.

    Args:
        error: The error message to parse.

    Returns:
        The flag name, or `None` if the error was not an unknown-flag error.
    """
    var error_str = String(error)
    var index = error_str.find(UNKNOWN_FLAG_ERROR)
    if index == -1:
        return None

    return String(error_str[byte = index + UNKNOWN_FLAG_ERROR.byte_length() :])
