from utils import Span
import os
from .flag_set import FlagSet
from .util import split


struct FlagParser:
    """Parses flags from the command line arguments."""

    var index: Int
    """The current index in the arguments list."""

    fn __init__(inout self) -> None:
        self.index = 0

    fn parse_flag(self, argument: String, arguments: Span[String], flags: FlagSet) raises -> Tuple[String, String, Int]:
        """Parses a flag and returns the name, value, and the index to increment by.

        Args:
            argument: The argument to parse.
            arguments: The list of arguments passed via the command line.
            flags: The flags passed via the command line.
        """
        # Flag with value set like "--flag=<value>"
        if argument.find("=") != -1:
            flag = split(argument, "=")
            name = flag[0][2:]
            value = flag[1]

            if name not in flags.names():
                raise Error("Command does not accept the flag supplied: " + name)

            return name, value, 1

        # Flag with value set like "--flag <value>"
        name = argument[2:]
        if name not in flags.names():
            raise Error("Command does not accept the flag supplied: " + name)

        # If it's a bool flag, set it to True and only increment the index by 1 (one arg used).
        try:
            _ = flags.lookup(name, "Bool")
            return name, String("True"), 1
        except:
            pass

        if self.index + 1 >= len(arguments):
            raise Error("Flag `" + name + "` requires a value to be set but reached the end of arguments.")

        if arguments[self.index + 1].startswith("-", 0, 1):
            raise Error("Flag `" + name + "` requires a value to be set but found another flag instead.")

        # Increment index by 2 because 2 args were used (one for name and value).
        return name, arguments[self.index + 1], 2

    fn parse_shorthand_flag(
        self, argument: String, arguments: Span[String], flags: FlagSet
    ) raises -> Tuple[String, String, Int]:
        """Parses a shorthand flag and returns the name, value, and the index to increment by.

        Args:
            argument: The argument to parse.
            arguments: The list of arguments passed via the command line.
            flags: The flags passed via the command line.

        Returns:
            The name, value, the index to increment by, and an error if one occurred.
        """
        # Flag with value set like "-f=<value>"
        if argument.find("=") != -1:
            flag = split(argument, "=")
            shorthand = flag[0][1:]
            value = flag[1]
            name = flags.lookup_name(shorthand)
            if name not in flags.names():
                raise Error("Command does not accept the shorthand flag supplied: " + name)

            return name, value, 1

        # Flag with value set like "-f <value>"
        shorthand = argument[1:]
        name = flags.lookup_name(shorthand)
        if name not in flags.names():
            raise Error("Command does not accept the shorthand flag supplied: " + shorthand)

        # If it's a bool flag, set it to True and only increment the index by 1 (one arg used).
        try:
            _ = flags.lookup(name, "Bool")
            return name, String("True"), 1
        except:
            pass

        if self.index + 1 >= len(arguments):
            raise Error("Flag `" + name + "` requires a value to be set but reached the end of arguments.")

        if arguments[self.index + 1].startswith("-", 0, 1):
            raise Error("Flag `" + name + "` requires a value to be set but found another flag instead.")

        # Increment index by 2 because 2 args were used (one for name and value).
        return name, arguments[self.index + 1], 2

    # TODO: This parsing is dirty atm, will come back around and clean it up.
    fn parse(inout self, inout flags: FlagSet, arguments: List[String]) raises -> List[String]:
        """Parses flags and args from the args passed via the command line and adds them to their appropriate collections.

        Args:
            flags: The flags to parse.
            arguments: The arguments passed via the command line.
        """
        remaining_args = List[String](capacity=len(arguments))
        while self.index < len(arguments):
            argument = arguments[self.index]

            # Positional argument
            if not argument.startswith("-", 0, 1):
                remaining_args.append(argument)
                self.index += 1
                continue

            var name: String
            var value: String
            increment_by = 0

            # Full flag
            if argument.startswith("--", 0, 2):
                name, value, increment_by = self.parse_flag(argument, arguments, flags)
            # Shorthand flag
            elif argument.startswith("-", 0, 1):
                name, value, increment_by = self.parse_shorthand_flag(argument, arguments, flags)
            else:
                raise Error("Expected a flag but found: " + argument)

            # Set the value of the flag.
            flags.lookup(name).set(value)
            self.index += increment_by

        # If flags are not set, check if they can be set from an environment variable or from a file.
        # Set it from that value if there is one available.
        for flag in flags.flags:
            if not flag[].value:
                if flag[].environment_variable:
                    value = os.getenv(flag[].environment_variable.value())
                    if value != "":
                        flag[].set(value)
                elif flag[].file_path:
                    with open(flag[].file_path.value(), "r") as f:
                        flag[].set(f.read())

        return remaining_args
