from std.sys import exit, stderr
from prism.value import ToValue


comptime UNKNOWN_FLAG_ERROR = "Command does not accept the flag supplied. Name: "
"""Prefix of the error raised when an argument names a flag the command does not define.

`flag_from_error` keys off this to decide whether an error is worth suggesting a correction for, so
it must stay specific to unknown flags. Other parse errors also mention a flag name, and matching
those would replace a precise message ("flag requires a value") with a misleading "did you mean".
"""


def panic(message: Some[Writable], code: Int = 1) -> None:
    """Panics with the given message.

    Args:
        message: The message to panic with.
        code: The exit code to use.
    """
    print(message, file=stderr)
    exit(code)


def string_to_bool(value: ImmStringSpan) raises -> Bool:
    """Converts a string to a boolean.

    Accepts the same spellings as Go's `strconv.ParseBool`, which is what most CLI tooling uses:
    `1`, `t`, `T`, `true`, `True`, `TRUE` and their false counterparts.

    Args:
        value: The string to convert to a boolean.

    Returns:
        The boolean equivalent of the string.

    Raises:
        Error: If the value is not a recognized boolean spelling. Returning False for unrecognized
            input would silently accept `--verbose=maybe` and quietly disagree with the user.
    """
    if value == "1" or value == "t" or value == "T" or value == "true" or value == "True" or value == "TRUE":
        return True
    if value == "0" or value == "f" or value == "F" or value == "false" or value == "False" or value == "FALSE":
        return False

    raise Error(
        "Invalid boolean value: '",
        value,
        "'. Expected one of: 1, t, T, true, True, TRUE, 0, f, F, false, False, FALSE.",
    )

def _to_opt_string[T: ToValue](var lhs: T) -> Optional[String]:
    return lhs.to_value()
