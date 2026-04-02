from std.io.io import _fdopen
from std.sys import argv, stdin


def parse_args_from_command_line(args: Span[StaticString, StaticConstantOrigin]) -> List[String]:
    """Returns the arguments passed to the executable as a list of strings.

    Returns:
        The arguments passed to the executable as a list of strings.
    """
    return [ String(arg) for arg in args[1:] ]


@fieldwise_init
struct STDINParserState(ImplicitlyCopyable, Equatable, TrivialRegisterPassable):
    """State of the parser when reading from stdin."""

    var value: UInt8
    """Internal value representing the state of the parser."""
    comptime FIND_TOKEN = Self(0)
    """State when the parser is looking for the start of a token."""
    comptime FIND_ARG = Self(1)
    """State when the parser is looking for the end of a token."""


comptime DOUBLE_QUOTE = '"'
"""A constant representing a double quote character."""
comptime DOUBLE_DASH = "--"
"""A constant representing a double dash string."""

def parse_args_from_stdin(str: StringSlice) -> List[String]:
    """Reads arguments from stdin and returns them as a list of strings.

    Args:
        str: The input string to parse.

    Returns:
        The arguments read from stdin as a list of strings.
    """
    var state = STDINParserState.FIND_TOKEN
    var line_number = 1
    var token = ""
    var args = List[String]()

    for char in str.codepoint_slices():
        if state == STDINParserState.FIND_TOKEN:
            if char.isspace() or char == DOUBLE_QUOTE:
                if char == "\n":
                    line_number += 1
                if token != "":
                    if token == DOUBLE_DASH:
                        break
                    args.append(token)
                    token = ""
                if char == DOUBLE_QUOTE:
                    state = STDINParserState.FIND_ARG
                continue
            token.write(char)
        else:
            if char != StringSlice(DOUBLE_QUOTE):
                token.write(char)
            else:
                if token != "":
                    args.append(token)
                    token = ""
                state = STDINParserState.FIND_TOKEN

    if state == STDINParserState.FIND_TOKEN:
        if token and token != DOUBLE_DASH:
            args.append(token)
    else:
        # Not an empty string and not a space
        if token and not token.isspace():
            args.append(token)

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
