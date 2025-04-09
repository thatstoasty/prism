from collections.string import StaticString


fn parse_args_from_command_line(args: VariadicList[StaticString]) -> List[String]:
    """Returns the arguments passed to the executable as a list of strings.

    Returns:
        The arguments passed to the executable as a list of strings.
    """
    var result = List[String](capacity=len(args))
    var i = 1
    while i < len(args):
        result.append(String(args[i]))
        i += 1

    return result^


@value
@register_passable("trivial")
struct STDINParserState:
    """State of the parser when reading from stdin."""

    var value: UInt8
    """State of the parser when reading from stdin."""

    alias FIND_TOKEN = Self(0)
    alias FIND_ARG = Self(1)

    fn __eq__(self, other: Self) -> Bool:
        """Compares two `STDINParserState` instances for equality.

        Args:
            other: The other `STDINParserState` instance to compare to.

        Returns:
            True if the two instances are equal, False otherwise.
        """
        return self.value == other.value

    fn __ne__(self, other: Self) -> Bool:
        """Compares two `STDINParserState` instances for inequality.

        Args:
            other: The other `STDINParserState` instance to compare to.

        Returns:
            True if the two instances are not equal, False otherwise.
        """
        return self.value != other.value


fn parse_args_from_stdin(input: String) -> List[String]:
    """Reads arguments from stdin and returns them as a list of strings.

    Args:
        input: The input string to parse.

    Returns:
        The arguments read from stdin as a list of strings.
    """
    var state = STDINParserState.FIND_TOKEN
    var line_number = 1
    var token = String("")
    var args = List[String]()

    for char in input.codepoint_slices():
        if state == STDINParserState.FIND_TOKEN:
            if char.isspace() or char == '"':
                if char == "\n":
                    line_number += 1
                if token != "":
                    if token == "--":
                        break
                    args.append(token)
                    token = ""
                if char == '"':
                    state = STDINParserState.FIND_ARG
                continue
            token.write(char)
        else:
            if char != '"':
                token.write(char)
            else:
                if token != "":
                    args.append(token)
                    token = ""
                state = STDINParserState.FIND_TOKEN

    if state == STDINParserState.FIND_TOKEN:
        if token and token != "--":
            args.append(token)
    else:
        # Not an empty string and not a space
        if token and not token.isspace():
            args.append(token)

    return args^
