import os
from memory import Span
from collections import InlineArray
from collections.string import StaticString
from prism._flag_set import FlagSet
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
        if argument.find("=") != -1:
            var flag = split(argument, "=")
            var name = flag[0][2:]
            var value = flag[1]

            if name not in flags.names():
                raise Error("Command does not accept the flag supplied: " + name)

            return name, value, 1

        # Flag with value set like "--flag <value>"
        var name = String(argument[2:])
        if String(name) not in flags.names():
            raise Error("Command does not accept the flag supplied: " + name)

        # If it's a bool flag, set it to True and only increment the index by 1 (one arg used).
        try:
            _ = flags.lookup["Bool"](name)
            return name, String("True"), 1
        except:
            pass

        if self.index + 1 >= len(arguments):
            raise Error("Flag `" + name + "` requires a value to be set but reached the end of arguments.")

        if arguments[self.index + 1].startswith("-", 0, 1):
            raise Error("Flag `" + name + "` requires a value to be set but found another flag instead.")

        # Increment index by 2 because 2 args were used (one for name and value).
        return name, String(arguments[self.index + 1]), 2

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

            return name, value, 1

        # Flag with value set like "-f <value>"
        var shorthand = String(argument[1:])
        var name = flags.lookup_name(shorthand)
        if name not in flags.names():
            raise Error("Command does not accept the shorthand flag supplied: " + shorthand)

        # If it's a bool flag, set it to True and only increment the index by 1 (one arg used).
        try:
            _ = flags.lookup["Bool"](name)
            return name, String("True"), 1
        except:
            pass

        if self.index + 1 >= len(arguments):
            raise Error("Flag `" + name + "` requires a value to be set but reached the end of arguments.")

        if arguments[self.index + 1].startswith("-", 0, 1):
            raise Error("Flag `" + name + "` requires a value to be set but found another flag instead.")

        # Increment index by 2 because 2 args were used (one for name and value).
        return name, String(arguments[self.index + 1]), 2

    # TODO: This parsing is dirty atm, will come back around and clean it up.
    fn parse(mut self, mut flags: FlagSet, arguments: List[StaticString]) raises -> List[StaticString]:
        """Parses flags and args from the args passed via the command line and adds them to their appropriate collections.

        Args:
            flags: The flags to parse.
            arguments: The arguments passed via the command line.

        Returns:
            The arguments that are not flags.

        Raises:
            Error: If an error occurred while parsing the flags.
        """
        var remaining_args = List[StaticString](capacity=len(arguments))
        while self.index < len(arguments):
            var argument = arguments[self.index]

            # Positional argument
            if not argument.startswith("-", 0, 1):
                remaining_args.append(argument)
                self.index += 1
                continue

            var name: String
            var value: String
            var increment_by = 0

            # Full flag
            if argument.startswith("--", 0, 2):
                name, value, increment_by = self.parse_flag(argument, arguments, flags)
            # Shorthand flag
            elif argument.startswith("-", 0, 1):
                name, value, increment_by = self.parse_shorthand_flag(argument, arguments, flags)
            else:
                raise Error("Expected a flag but found: " + String(argument))

            # Set the value of the flag.
            alias list_types = InlineArray[String, 3]("StringList", "IntList", "Float64List")
            var flag = flags.lookup(name)
            if flag[].type in list_types:
                if not flag[].changed:
                    flag[].set(value)
                else:
                    flag[].value.value().write(" ", value)
            else:
                flag[].set(value)
            self.index += increment_by

        # If flags are not set, check if they can be set from an environment variable or from a file.
        # Set it from that value if there is one available.
        for flag in flags:
            if not flag[].value:
                if flag[].environment_variable:
                    value = os.getenv(flag[].environment_variable.value())
                    if value != "":
                        flag[].set(value)
                elif flag[].file_path:
                    with open(os.path.expanduser(flag[].file_path.value()), "r") as f:
                        flag[].set(f.read())

        return remaining_args
