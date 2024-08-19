from collections import Optional, Dict


# Individual flag annotations
alias REQUIRED = "REQUIRED"

# Flag Group annotations
alias REQUIRED_AS_GROUP = "REQUIRED_AS_GROUP"
alias ONE_REQUIRED = "ONE_REQUIRED"
alias MUTUALLY_EXCLUSIVE = "MUTUALLY_EXCLUSIVE"


@value
struct Flag(CollectionElement, Stringable):
    """Represents a flag that can be passed via the command line.
    Flags are passed in via --name or -shorthand and can have a value associated with them.
    """

    var name: String
    var shorthand: String
    var usage: String
    var value: Optional[String]
    var default: String
    var type: String
    var annotations: Dict[String, List[String]]
    var changed: Bool

    fn __init__(
        inout self,
        name: String,
        shorthand: String,
        usage: String,
        value: Optional[String],
        default: String,
        type: String,
    ) -> None:
        """Initializes a new Flag.

        Args:
            name: The name of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
            value: The value of the flag.
            default: The default value of the flag.
            type: The type of the flag.
        """
        self.name = name
        self.shorthand = shorthand
        self.usage = usage
        self.value = value
        self.default = default
        self.type = type
        self.annotations = Dict[String, List[String]]()
        self.changed = False

    fn __str__(self) -> String:
        return (
            String("(Name: ")
            + self.name
            + String(", Shorthand: ")
            + self.shorthand
            + String(", Usage: ")
            + self.usage
            + String(")")
        )

    fn __eq__(self, other: Self) -> Bool:
        return (
            self.name == other.name
            and self.shorthand == other.shorthand
            and self.usage == other.usage
            and self.value.value() == other.value.value()
            and self.default == other.default
            and self.type == other.type
            and self.changed == other.changed
        )

    fn __ne__(self, other: Self) -> Bool:
        return not self == other

    fn set_value(inout self, value: String) -> None:
        """Sets the value of the flag.

        Args:
            value: The value to set.
        """
        self.value = value
        self.changed = True


fn split(text: String, sep: String, max_split: Int = -1) -> List[String]:
    try:
        return text.split(sep, max_split)
    except:
        return List[String](text)


fn parse_flag(i: Int, argument: String, arguments: List[String], flags: FlagSet) -> Tuple[String, String, Int, Error]:
    """Parses a flag and returns the name, value, and the index to increment by.

    Args:
        i: The current index in the arguments list.
        argument: The argument to parse.
        arguments: The list of arguments passed via the command line.
        flags: The flags passed via the command line.
    """
    # Flag with value set like "--flag=<value>"
    if argument.find("=") != -1:
        var flag = split(argument, "=")
        var name = flag[0][2:]
        var value = flag[1]

        if name not in flags.get_names():
            return name, value, 0, Error("Command does not accept the flag supplied: " + name)

        return name, value, 1, Error()

    # Flag with value set like "--flag <value>"
    var name = argument[2:]
    if name not in flags.get_names():
        return name, String(""), 0, Error("Command does not accept the flag supplied: " + name)

    # If it's a bool flag, set it to True and only increment the index by 1 (one arg used).
    if flags.get_as_bool(name):
        return name, String("True"), 1, Error()

    if i + 1 >= len(arguments):
        return (
            name,
            String(""),
            0,
            Error("Flag `" + name + "` requires a value to be set but reached the end of arguments."),
        )

    if arguments[i + 1].startswith("-", 0, 1):
        return (
            name,
            String(""),
            0,
            Error("Flag `" + name + "` requires a value to be set but found another flag instead."),
        )

    # Increment index by 2 because 2 args were used (one for name and value).
    return name, arguments[i + 1], 2, Error()


fn parse_shorthand_flag(
    i: Int, argument: String, arguments: List[String], flags: FlagSet
) -> Tuple[String, String, Int, Error]:
    """Parses a shorthand flag and returns the name, value, and the index to increment by.

    Args:
        i: The current index in the arguments list.
        argument: The argument to parse.
        arguments: The list of arguments passed via the command line.
        flags: The flags passed via the command line.

    Returns:
        The name, value, the index to increment by, and an error if one occurred.
    """
    # Flag with value set like "-f=<value>"
    if argument.find("=") != -1:
        var flag = split(argument, "=")
        var shorthand = flag[0][1:]
        var value = flag[1]
        var name = flags.lookup_name(shorthand).value()

        if name not in flags.get_names():
            return name, value, 0, Error("Command does not accept the flag supplied: " + name)

        return name, value, 1, Error()

    # Flag with value set like "-f <value>"
    var shorthand = argument[1:]
    var result = flags.lookup_name(shorthand)
    if not result:
        return shorthand, String(""), 0, Error("Did not find name for shorthand: " + shorthand)
    var name = result.value()

    # If it's a bool flag, set it to True and only increment the index by 1 (one arg used).
    if flags.get_as_bool(name):
        return name, String("True"), 1, Error()

    if i + 1 >= len(arguments):
        return (
            name,
            String(""),
            0,
            Error("Flag `" + name + "` requires a value to be set but reached the end of arguments."),
        )

    if arguments[i + 1].startswith("-", 0, 1):
        return (
            name,
            String(""),
            0,
            Error("Flag `" + name + "` requires a value to be set but found another flag instead."),
        )

    # Increment index by 2 because 2 args were used (one for name and value).
    return name, arguments[i + 1], 2, Error()


# TODO: This parsing is dirty atm, will come back around and clean it up.
fn get_flags(inout flags: FlagSet, arguments: List[String]) -> (List[String], Error):
    """Parses flags and args from the args passed via the command line and adds them to their appropriate collections.

    Args:
        flags: The flags passed via the command line.
        arguments: The arguments passed via the command line.
    """
    var remaining_args = List[String]()
    var i = 0
    while i < len(arguments):
        var argument = arguments[i]

        # Positional argument
        if not argument.startswith("-", 0, 1):
            remaining_args.append(argument)
            i += 1
            continue

        var name: String = ""
        var value: String = ""
        var increment_by: Int = 0
        var err = Error()

        # Full flag
        if argument.startswith("--", 0, 2):
            name, value, increment_by, err = parse_flag(i, argument, arguments, flags)
        # Shorthand flag
        elif argument.startswith("-", 0, 1):
            name, value, increment_by, err = parse_shorthand_flag(i, argument, arguments, flags)

        if err:
            return remaining_args, err

        # Set the value of the flag directly, no more set_value function.
        var flag = flags.lookup(name)
        if not flag:
            return List[String](), Error("No flag found with the name: " + name)

        flag.value()[].set_value(value)
        i += increment_by

    return remaining_args, Error()
