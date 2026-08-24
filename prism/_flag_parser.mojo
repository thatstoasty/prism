from prism._flag_set import FlagSet
from prism.opt_type import OptType
from prism._util import UNKNOWN_FLAG_ERROR


def _is_negative_number(argument: StringSpan) -> Bool:
    """Reports whether an argument starting with `-` is a negative number rather than a flag.

    Args:
        argument: The argument to inspect.

    Returns:
        True if the argument reads as a negative number, such as `-5` or `-.5`.
    """
    if argument.byte_length() < 2:
        return False

    var first = argument[byte=1:2]
    return first == "." or (first >= "0" and first <= "9")


@fieldwise_init
struct ShorthandParserState(Equatable, Writable, TrivialRegisterPassable):
    """State of the parser when parsing shorthand flags."""

    var value: UInt8
    """Internal value."""
    comptime START = Self(0)
    """State when the parser is trying to parse the full shorthand flag name."""
    comptime MULTIPLE_BOOLS = Self(1)
    """State when the parser is trying to parse a combination of multiple bool flags."""
    comptime CHECK_FLAG = Self(2)
    """State when the parser has found a match for the full shorthand flag name and is checking if it's a bool flag or not."""


@fieldwise_init
struct ParseFlagResult[arg_origin: ImmOrigin](Movable, Writable):
    """Result of parsing a flag."""

    var name: ImmStringSpan[Self.arg_origin]
    """The name of the flag."""
    var value: String
    """The value of the flag."""
    var increment: Int
    """The index to increment by."""


@fieldwise_init
struct ParseShorthandFlagResult(Movable, Writable):
    """Result of parsing a shorthand flag."""

    var names: List[String]
    """The names of the flag."""
    var value: String
    """The value of the flag."""
    var increment: Int
    """The index to increment by."""


struct FlagParser[origin: ImmOrigin](Writable):
    """Parses flags from the command line arguments."""

    var index: Int
    """The current index in the arguments list."""
    var arguments: Span[String, Self.origin]
    """The arguments passed to the command."""

    def __init__(out self, arguments: Span[String, Self.origin]):
        """Initializes the FlagParser.

        Args:
            arguments: The arguments passed to the command.
        """
        self.index = 0
        self.arguments = arguments

    def parse_flag[arg_origin: ImmOrigin, //](self, argument: ImmStringSpan[arg_origin], flags: FlagSet) raises -> ParseFlagResult[arg_origin]:
        """Parses a flag and returns the name, value, and the index to increment by.

        Args:
            argument: The argument to parse.
            flags: The flags passed to the command.

        Returns:
            The name, value, the index to increment by, and an error if one occurred.

        Raises:
            Error: If an error occurred while parsing the flag.
        """
        # Flag with value set like "--flag=<value>"
        var sep_index = argument.find("=")
        if sep_index != -1:
            # `lookup` finds the flag in a single scan. Testing `name not in flags.names()` instead
            # copies every flag name into a fresh list on each flag argument parsed.
            var name_slice = argument[byte=2:sep_index]
            if not flags.lookup(name_slice):
                raise Error(UNKNOWN_FLAG_ERROR, name_slice)

            return ParseFlagResult(name=name_slice, value=String(argument[byte=sep_index + 1 :]), increment=1)

        # Flag with value set like "--flag <value>"
        var name_slice = argument[byte=2:]
        if not flags.lookup(name_slice):
            raise Error(UNKNOWN_FLAG_ERROR, name_slice)

        # If it's a bool flag, set it to True and only increment the index by 1 (one arg used).
        if flags.lookup[Bool](name_slice):
            return ParseFlagResult(name=name_slice, value="True", increment=1)

        if self.index + 1 >= len(self.arguments):
            raise Error("Flag requires a value to be set but reached the end of arguments. Name: ", name_slice)

        # A leading `-` usually means the next argument is another flag rather than this flag's
        # value, but a negative number is a legitimate value.
        ref next_argument = self.arguments[self.index + 1]
        if next_argument.startswith("-", 0, 1) and not _is_negative_number(next_argument):
            raise Error("Flag requires a value to be set but found another flag instead. Name: ", name_slice)

        # Increment index by 2 because 2 args were used (one for name and value).
        return ParseFlagResult(name=name_slice, value=String(self.arguments[self.index + 1]), increment=2)

    def parse_shorthand_flag(self, argument: StringSpan, flags: FlagSet) raises -> ParseShorthandFlagResult:
        """Parses a shorthand flag and returns the name, value, and the index to increment by.

        Args:
            argument: The argument to parse.
            flags: The flags passed to the command.

        Returns:
            The name, value, the index to increment by, and an error if one occurred.

        Raises:
            Error: If an error occurred while parsing the shorthand flag.
        """
        # Flag with value set like "-f=<value>"
        var sep_index = argument.find("=")
        if sep_index != -1:
            var shorthand = argument[byte=1:sep_index]
            var value = argument[byte = sep_index + 1 :]
            # `lookup_name` already resolved the shorthand against the set, so a second membership
            # test against a freshly built list of every name proves nothing.
            var name = flags.lookup_name(shorthand)
            if not name:
                raise Error("Command does not accept the shorthand flag supplied: ", shorthand)

            return ParseShorthandFlagResult(names=[name.take()], value=String(value), increment=1)

        # Flag with value set like "-f <value>"
        var state = ShorthandParserState.START
        var start = 1
        var end = argument.byte_length()
        var flag_names = List[String]()
        while start != end:
            var shorthand = argument[byte=start:end]

            # Try to find the flag with the full shorthand flag name.
            # If that doesn't work, then slice off the last character and check again, until we find a match.
            # Shorthand flags can be a combination of multiple bool flags, so we need to check for that.
            if state == ShorthandParserState.START:
                var flag = flags.lookup_shorthand(shorthand)
                if not flag:
                    end -= 1
                    state = ShorthandParserState.MULTIPLE_BOOLS
                    continue

                flag_names.append(flag.value()[].name)
                state = ShorthandParserState.CHECK_FLAG

            # Found no matches for the full shorthand flag name, so we need to check for a combination of bool flags.
            elif state == ShorthandParserState.MULTIPLE_BOOLS:
                # This block must not swallow its own error. `lookup_shorthand` does not raise, so
                # the only error reachable here is the non-bool one raised just below; catching it
                # without re-raising leaves `start` and `end` unchanged and spins this loop forever.
                var flag = flags.lookup_shorthand(shorthand)
                if not flag:
                    end -= 1
                    continue

                if flag.value()[].type != OptType.Bool:
                    raise Error(
                        "Received a combination of shorthand flags that are not all bool flags. flag received: ",
                        argument,
                        ". Found the following flag which is not a bool flag: ",
                        flag.value()[].name,
                    )

                flag_names.append(flag.value()[].name)
                start = end
                end = argument.byte_length()
                # Reached the end of the parser, all flags have been matched and will be set to true.
                if start == end:
                    return ParseShorthandFlagResult(names=flag_names^, value="True", increment=1)

            # It's a single option
            elif state == ShorthandParserState.CHECK_FLAG:
                # If it's a bool flag, set it to True and only increment the index by 1 (one arg used).
                var flag = flags.lookup_shorthand(shorthand)  # TODO: Try to lookup only once
                if not flag:
                    raise Error(
                        "FlagParser._parse_shorthand_flag: Command does not accept the shorthand flag supplied: ",
                        shorthand,
                    )

                if flag[][].type == OptType.Bool:
                    return ParseShorthandFlagResult(names=flag_names^, value="True", increment=1)

                # Non bool flags expect a value to be set. If the end of the arguments list is reached, raise an error.
                if self.index + 1 >= len(self.arguments):
                    raise Error(
                        "Flag `", flag.value()[].name, "` requires a value to be set but reached the end of arguments."
                    )

                # If the next argument is another flag, raise an error. A negative number is a
                # value, not a flag.
                ref next_argument = self.arguments[self.index + 1]
                if next_argument.startswith("-", 0, 1) and not _is_negative_number(next_argument):
                    raise Error(
                        "Flag `", flag.value()[].name, "` requires a value to be set but found another flag instead."
                    )

                # Increment index by 2 because 2 args were used (one for name and value).
                return ParseShorthandFlagResult(
                    names=flag_names^, value=String(self.arguments[self.index + 1]), increment=2
                )

        raise Error(
            "FlagParser._parse_shorthand_flag: Parsed out the following flag: ",
            flag_names,
            ". Could not find a match for the remaining flags: ",
            argument[byte=start : argument.byte_length()],
        )
