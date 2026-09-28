from prism._flag_set import FlagSet
from prism.flag import Flag
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


def _is_flag(argument: StringSpan, flags: FlagSet) -> Bool:
    """Reports whether an argument is a flag, as opposed to a positional value or a flag's value.

    Args:
        argument: The argument to inspect.
        flags: The flags the command accepts.

    Returns:
        True if the argument should be parsed as a flag.

    #### Notes:
    - A bare `-` is a value, conventionally meaning stdin or stdout, not an empty shorthand.
    - A negative number such as `-5` is a value too, unless the command defines a shorthand that
      it would otherwise spell, in which case the flag wins.
    """
    if not argument.startswith("-", 0, 1) or argument == "-":
        return False

    if _is_negative_number(argument) and not flags.lookup_shorthand(argument[byte=1:2]):
        return False

    return True


def _codepoint_offsets(s: StringSpan) -> List[Int]:
    """Returns the byte offset at which each codepoint starts, with a sentinel at the end.

    Args:
        s: The string to scan.

    Returns:
        `count + 1` offsets, so codepoint `i` spans `[result[i], result[i + 1])`.
    """
    var offsets = List[Int]()
    var offset = 0
    for codepoint in s.codepoint_slices():
        offsets.append(offset)
        offset += codepoint.byte_length()
    offsets.append(offset)
    return offsets^


def _longest_shorthand(body: StringSpan, offsets: List[Int], start: Int, flags: FlagSet) -> Int:
    """Finds the longest shorthand that begins at a position in a cluster of shorthands.

    Args:
        body: The cluster, without its leading `-`.
        offsets: Codepoint offsets into `body`, from `_codepoint_offsets`.
        start: The index into `offsets` the shorthand begins at.
        flags: The flags the command accepts.

    Returns:
        The index into `offsets` just past the shorthand, or -1 if none begins at `start`.

    #### Notes:
    - Shorthands may be longer than one character, such as `-r0`, so each position tries the
      longest candidate first. `-r0vvas` is then `-r0 -vv -a -s` when those are defined.
    """
    var end = len(offsets) - 1
    while end > start:
        if flags.lookup_shorthand(body[byte = offsets[start] : offsets[end]]):
            return end
        end -= 1
    return -1


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
    """Result of parsing a shorthand flag, or a cluster of them."""

    var names: List[String]
    """The full names of the flags, in the order they appeared."""
    var values: List[String]
    """The value for each flag in `names`, at the same index."""
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
            raise Error(t"Flag `--{name_slice}` requires a value, but reached the end of the arguments.")

        # A leading `-` usually means the next argument is another flag rather than this flag's
        # value, but a negative number or a bare `-` is a legitimate value.
        ref next_argument = self.arguments[self.index + 1]
        if _is_flag(next_argument, flags):
            raise Error(t"Flag `--{name_slice}` requires a value, but was followed by another flag: `{next_argument}`.")

        # Increment index by 2 because 2 args were used (one for name and value).
        return ParseFlagResult(name=name_slice, value=String(self.arguments[self.index + 1]), increment=2)

    def parse_shorthand_flag(self, argument: StringSpan, flags: FlagSet) raises -> ParseShorthandFlagResult:
        """Parses a shorthand flag, or a cluster of them, into flag names and values.

        Accepts the POSIX forms: `-o value`, `-o=value`, `-ovalue`, and clusters such as `-abc`,
        where every shorthand before the last value-taking one is a bool. Each position in a
        cluster matches the longest shorthand defined there, so multi-character ones work too. A value-taking shorthand
        takes the rest of the argument as its value, or the next argument when it is last:
        `-ao file`, `-aofile` and `-ao=file` all set `a` and give `o` the value `file`.

        Args:
            argument: The argument to parse, starting with `-`.
            flags: The flags passed to the command.

        Returns:
            The names and values of the flags, and the index to increment by.

        Raises:
            Error: If a shorthand is not recognized, or a value-taking one has no value.
        """
        var body = argument[byte=1:]
        var offsets = _codepoint_offsets(body)
        var names = List[String]()
        var values = List[String]()

        var i = 0
        while i < len(offsets) - 1:
            var j = _longest_shorthand(body, offsets, i, flags)
            if j == -1:
                var shorthand = body[byte = offsets[i] : offsets[i + 1]]
                if shorthand == "=":
                    raise Error(t"Expected a shorthand flag before `=` in `{argument}`.")
                raise Error(UNKNOWN_FLAG_ERROR, shorthand)

            ref flag = flags.lookup_shorthand(body[byte = offsets[i] : offsets[j]]).value()[]
            names.append(flag.name)
            var rest = body[byte = offsets[j] :]
            # A value-taking flag, or a bool given `=value`, ends the cluster.
            if flag.type != OptType.Bool or rest.startswith("="):
                return self._shorthand_value(flag, rest, flags, names^, values^)

            values.append("True")
            i = j

        return ParseShorthandFlagResult(names=names^, values=values^, increment=1)

    def _shorthand_value(
        self, flag: Flag, rest: StringSpan, flags: FlagSet, var names: List[String], var values: List[String]
    ) raises -> ParseShorthandFlagResult:
        """Finishes parsing at a shorthand that ends a cluster by taking a value.

        Args:
            flag: The flag the last shorthand named. Its name is already the last of `names`.
            rest: What follows the shorthand in the same argument.
            flags: The flags passed to the command.
            names: The names parsed so far.
            values: The values of every name but the last.

        Returns:
            The finished result.

        Raises:
            Error: If the flag takes a value but none follows.
        """
        if rest.startswith("="):
            values.append(String(rest[byte=1:]))
            return ParseShorthandFlagResult(names=names^, values=values^, increment=1)

        if flag.type == OptType.Bool:
            if rest:
                raise Error(t"Flag `--{flag.name}` does not take a value, but was given `{rest}`.")
            values.append("True")
            return ParseShorthandFlagResult(names=names^, values=values^, increment=1)

        if rest:
            values.append(String(rest))
            return ParseShorthandFlagResult(names=names^, values=values^, increment=1)

        if self.index + 1 >= len(self.arguments):
            raise Error(t"Flag `--{flag.name}` requires a value, but reached the end of the arguments.")

        # A negative number or a bare `-` is a value, not a flag.
        ref next_argument = self.arguments[self.index + 1]
        if _is_flag(next_argument, flags):
            raise Error(t"Flag `--{flag.name}` requires a value, but was followed by another flag: `{next_argument}`.")

        values.append(String(next_argument))
        return ParseShorthandFlagResult(names=names^, values=values^, increment=2)
