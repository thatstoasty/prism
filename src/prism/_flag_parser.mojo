import os
from memory import Span
from collections.string import StringSlice
from prism._flag_set import FlagSet, FType
from prism._util import split


@value
@register_passable("trivial")
struct ShorthandParserState:
    var value: UInt8
    alias START = Self(0)
    alias MULTIPLE_BOOLS = Self(1)
    alias CHECK_FLAG = Self(2)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: Self) -> Bool:
        return self.value != other.value


struct FlagParser[origin: ImmutableOrigin]:
    """Parses flags from the command line arguments."""

    var index: Int
    """The current index in the arguments list."""
    var arguments: Span[String, origin]

    fn __init__(out self, arguments: Span[String, origin]):
        """Initializes the FlagParser."""
        self.index = 0
        self.arguments = arguments

    fn parse_flag(self, argument: StringSlice, flags: FlagSet) raises -> Tuple[String, String, Int]:
        """Parses a flag and returns the name, value, and the index to increment by.

        Args:
            argument: The argument to parse.
            flags: The flags passed via the command line.

        Returns:
            The name, value, the index to increment by, and an error if one occurred.

        Raises:
            Error: If an error occurred while parsing the flag.
        """
        # Flag with value set like "--flag=<value>"
        var sep_index = argument.find("=")
        if sep_index != -1:
            var name = String(argument[2:sep_index])
            if name not in flags.names():
                raise Error("Command does not accept the flag supplied. Name: ", name)

            var value = String(argument[sep_index + 1 :])
            return name^, value^, 1

        # Flag with value set like "--flag <value>"
        var name = String(argument[2:])
        if name not in flags.names():
            raise Error("Command does not accept the flag supplied. Name: ", name)

        # If it's a bool flag, set it to True and only increment the index by 1 (one arg used).
        if flags.lookup[FType.Bool](name):
            return name^, String("True"), 1

        if self.index + 1 >= len(self.arguments):
            raise Error("Flag requires a value to be set but reached the end of arguments. Name: ", name)

        if self.arguments[self.index + 1].startswith("-", 0, 1):
            raise Error("Flag requires a value to be set but found another flag instead. Name: ", name)

        # Increment index by 2 because 2 args were used (one for name and value).
        return name^, String(self.arguments[self.index + 1]), 2

    fn parse_shorthand_flag(self, argument: StringSlice, flags: FlagSet) raises -> Tuple[List[String], String, Int]:
        """Parses a shorthand flag and returns the name, value, and the index to increment by.

        Args:
            argument: The argument to parse.
            flags: The flags passed via the command line.

        Returns:
            The name, value, the index to increment by, and an error if one occurred.

        Raises:
            Error: If an error occurred while parsing the shorthand flag.
        """
        # Flag with value set like "-f=<value>"
        var sep_index = argument.find("=")
        if sep_index != -1:
            var shorthand = argument[1:sep_index]
            var value = argument[sep_index:]
            var name = flags.lookup_name(shorthand)
            if not name or name.value() not in flags.names():
                raise Error("Command does not accept the shorthand flag supplied: ", shorthand)

            return List[String](name.value()), String(value), 1

        # Flag with value set like "-f <value>"
        var state = ShorthandParserState.START
        var start = 1
        var end = len(argument)
        var flag_names = List[String]()
        while start != end:
            var shorthand = argument[start:end]

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
                try:
                    var flag = flags.lookup_shorthand(shorthand)
                    if not flag:
                        end -= 1
                        continue

                    if flag.value()[].type != FType.Bool:
                        raise Error(
                            "Received an combination of shorthand flags that are not all bool flags. flag received: ",
                            argument,
                            ". Found the following flag which is not a bool flag: ",
                            flag.value()[].name,
                        )

                    flag_names.append(flag.value()[].name)
                    start = end
                    end = len(argument)
                    # Reached the end of the parser, all flags have been matched and will be set to true.
                    if start == end:
                        return flag_names^, String("True"), 1
                except e:
                    if "FlagNotFoundError" in String(e):
                        end -= 1
                        continue

            # It's a single option
            elif state == ShorthandParserState.CHECK_FLAG:
                # If it's a bool flag, set it to True and only increment the index by 1 (one arg used).
                var flag = flags.lookup_shorthand(shorthand)  # TODO: Try to lookup only once
                if not flag:
                    raise Error(
                        "FlagParser._parse_shorthand_flag: Command does not accept the shorthand flag supplied: ",
                        shorthand,
                    )

                if flag.value()[].type == FType.Bool:
                    return flag_names^, String("True"), 1

                # Non bool flags expect a value to be set. If the end of the arguments list is reached, raise an error.
                if self.index + 1 >= len(self.arguments):
                    raise Error(
                        "Flag `", flag.value()[].name, "` requires a value to be set but reached the end of arguments."
                    )

                # If the next argument is another flag, raise an error.
                if self.arguments[self.index + 1].startswith("-", 0, 1):
                    raise Error(
                        "Flag `", flag.value()[].name, "` requires a value to be set but found another flag instead."
                    )

                # Increment index by 2 because 2 args were used (one for name and value).
                return flag_names^, String(self.arguments[self.index + 1]), 2

        raise Error(
            "FlagParser._parse_shorthand_flag: Parsed out the following flag: ",
            flag_names.__str__(),
            ". Could not find a match for the remaining flags: ",
            argument[start : len(argument)],
        )
