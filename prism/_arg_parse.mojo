from std.io.io import _fdopen
from std.sys import argv, stdin


def parse_args_from_command_line(args: Span[StaticString, ImmStaticOrigin]) -> List[String]:
    """Returns the arguments passed to the executable as a list of strings.

    Returns:
        The arguments passed to the executable as a list of strings.
    """
    return [ String(arg) for arg in args[1:] ]


comptime DOUBLE_QUOTE = '"'
"""A constant representing a double quote character."""


def parse_args_from_stdin(str: StringSpan) -> List[String]:
    """Splits a line of input into arguments, the way a shell splits a command line.

    Arguments are separated by whitespace. Double quotes group text, spaces included, into one
    argument, and can appear mid-argument: `--name="a b"` is the single argument `--name=a b`.

    Args:
        str: The input string to parse.

    Returns:
        The arguments read from stdin as a list of strings.

    #### Notes:
    - `--` is kept as an argument. It used to stop parsing and drop everything after it, when
      `--` is what marks the rest as positional, so `--weird` could not be passed through.
    - `""` is an empty argument rather than nothing, and quoted whitespace is kept.
    - A quote left open at the end of the input closes there.
    """
    var args = List[String]()
    var token = String()
    # Whether an argument has started, which `""` does without adding any text to it.
    var in_token = False
    var quoted = False

    for char in str.codepoint_slices():
        if quoted:
            if char == DOUBLE_QUOTE:
                quoted = False
            else:
                token.write(char)
            continue

        if char == DOUBLE_QUOTE:
            quoted = True
            in_token = True
        elif char.isspace():
            if in_token:
                args.append(token^)
                token = String()
                in_token = False
        else:
            token.write(char)
            in_token = True

    if in_token:
        args.append(token^)

    return args^


def read_args() -> List[String]:
    """Reads arguments from command line and returns them as a list of strings.

    Returns:
        The arguments read from command line as a list of strings.
    """
    return parse_args_from_command_line(argv())


def read_args_from_stdin() raises -> List[String]:
    """Reads arguments from stdin and returns them as a list of strings.

    Returns:
        The arguments read from stdin as a list of strings.
    """
    return parse_args_from_stdin(_fdopen["r"](stdin).readline())
