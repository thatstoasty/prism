from sys import argv
from collections.dict import Dict, KeyElement


@value
struct StringKey(KeyElement):
    var s: String

    fn __init__(inout self, owned s: String):
        self.s = s ^

    fn __init__(inout self, s: StringLiteral):
        self.s = String(s)

    fn __hash__(self) -> Int:
        return hash(self.s)

    fn __eq__(self, other: Self) -> Bool:
        return self.s == other.s

    fn __ne__(self, other: Self) -> Bool:
        return self.s != other.s

    fn __str__(self) -> String:
        return self.s


fn contains_flag(vector: Flags, value: String) -> Bool:
    for i in range(vector.size):
        if String(vector[i].name) == value:
            return True
    return False


# TODO: Add functions to get flag as a <TYPE>. Like get flag as int, get flag as bool, etc.
@value
struct Flag(CollectionElement, Stringable):
    """Represents a flag that can be passed via the command line.
    Flags are passed in via --name or -shorthand and can have a value associated with them.
    """
    var name: String
    var shorthand: String
    var usage: String

    fn __init__(inout self, name: String, shorthand: String, usage: String) -> None:
        """Initializes a new Flag.

        Args:
            name: The name of the flag.
            shorthand: The shorthand of the flag.
            usage: The usage of the flag.
        """
        self.name = name
        self.shorthand = shorthand
        self.usage = usage

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

    fn __repr__(self) -> String:
        return str(self)


alias Flags = List[Flag]
alias InputFlags = Dict[StringKey, String]
alias PositionalArgs = List[String]


fn get_args_and_flags(
    inout args: PositionalArgs, inout flags: InputFlags
) raises -> None:
    """Parses flags and args from the args passed via the command line and adds them to their appropriate collections.

    Args:
        args: The positional args passed via the command line.
        flags: The flags passed via the command line.

    Raises:
        Error: TODO
    """
    var arguments = argv()
    for i in range(len(arguments)):
        if i != 0:
            var argument = String(arguments[i])
            if argument.find("--") != -1:
                if argument.find("=") != -1:
                    var flag = argument.split("=")
                    flags[StringKey(flag[0][2:])] = flag[1]
                else:
                    flags[StringKey(argument[2:])] = ""
            else:
                args.append(argument)
