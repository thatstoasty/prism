import os
from memory import Span
from collections.string import StaticString
from prism._flag_set import FlagSet, FType
from prism._util import split


struct FlagParser:
    """Parses flags from the command line arguments."""

    var index: Int
    """The current index in the arguments list."""

    fn __init__(mut self) -> None:
        """Initializes the FlagParser."""
        self.index = 0

    fn parse_flag(
        self, argument: StaticString, arguments: Span[StaticString], flags: FlagSet
    ) raises -> Tuple[String, String, Int]:
        """Parses a flag and returns the name, value, and the index to increment by.

        Args:
            argument: The argument to parse.
            arguments: The list of arguments passed via the command line.
            flags: The flags passed via the command line.

        Returns:
            The name, value, the index to increment by, and an error if one occurred.

        Raises:
            Error: If an error occurred while parsing the flag.
        """
        # Flag with value set like "--flag=<value>"
        var sep_index = argument.find("=")
        if sep_index != -1:
            var name = String(argument[2 : sep_index])
            if name not in flags.names():
                raise Error(String("Command does not accept the flag supplied: ", name))

            var value = String(argument[sep_index + 1:])
            return name^, value^, 1

        # Flag with value set like "--flag <value>"
        var name = String(argument[2:])
        if String(name) not in flags.names():
            raise Error("Command does not accept the flag supplied: " + name)

        # If it's a bool flag, set it to True and only increment the index by 1 (one arg used).
        try:
            _ = flags.lookup[FType.Bool](name)
            return name^, String("True"), 1
        except:
            pass

        if self.index + 1 >= len(arguments):
            raise Error("Flag `", name, "` requires a value to be set but reached the end of arguments.")

        if arguments[self.index + 1].startswith("-", 0, 1):
            raise Error("Flag `", name, "` requires a value to be set but found another flag instead.")

        # Increment index by 2 because 2 args were used (one for name and value).
        return name^, String(arguments[self.index + 1]), 2

    fn parse_shorthand_flag(
        self, argument: StaticString, arguments: Span[StaticString], flags: FlagSet
    ) raises -> Tuple[String, String, Int]:
        """Parses a shorthand flag and returns the name, value, and the index to increment by.

        Args:
            argument: The argument to parse.
            arguments: The list of arguments passed via the command line.
            flags: The flags passed via the command line.

        Returns:
            The name, value, the index to increment by, and an error if one occurred.

        Raises:
            Error: If an error occurred while parsing the shorthand flag.
        """
        # Flag with value set like "-f=<value>"
        if argument.find("=") != -1:
            var flag = split(argument, "=")
            var shorthand = flag[0][1:]
            var value = flag[1]
            var name = flags.lookup_name(shorthand)
            if name not in flags.names():
                raise Error("Command does not accept the shorthand flag supplied: " + name)

            return name^, value^, 1

        # Flag with value set like "-f <value>"
        var shorthand = String(argument[1:])
        var name = flags.lookup_name(shorthand)
        if name not in flags.names():
            raise Error("Command does not accept the shorthand flag supplied: " + shorthand)

        # If it's a bool flag, set it to True and only increment the index by 1 (one arg used).
        try:
            _ = flags.lookup[FType.Bool](name)
            return name^, String("True"), 1
        except:
            pass

        if self.index + 1 >= len(arguments):
            raise Error("Flag `" + name + "` requires a value to be set but reached the end of arguments.")

        if arguments[self.index + 1].startswith("-", 0, 1):
            raise Error("Flag `" + name + "` requires a value to be set but found another flag instead.")

        # Increment index by 2 because 2 args were used (one for name and value).
        return name^, String(arguments[self.index + 1]), 2
