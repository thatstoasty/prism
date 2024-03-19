from sys import argv
from collections.dict import Dict, KeyElement
from .vector import to_string, contains


@value
struct StringKey(KeyElement):
    var value: String

    fn __init__(inout self, owned s: String):
        self.value = s ^

    fn __init__(inout self, s: StringLiteral):
        self.value = String(s)

    fn __hash__(self) -> Int:
        return hash(self.value)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value


fn contains_flag(vector: Flags, value: String) -> Bool:
    for i in range(vector.size):
        if String(vector[i].name) == value:
            return True
    return False


# TODO: Add functions to get flag as a <TYPE>. Like get flag as int, get flag as bool, etc.
@value
struct Flag(CollectionElement, Stringable):
    var name: StringLiteral
    var shorthand: StringLiteral
    var usage: StringLiteral

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
        return (
            String("(Name: ")
            + self.name
            + String(", Shorthand: ")
            + self.shorthand
            + String(", Usage: ")
            + self.usage
            + String(")")
        )


alias Flags = DynamicVector[Flag]
alias InputFlags = Dict[StringKey, String]
alias PositionalArgs = DynamicVector[String]


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
                    var flag: DynamicVector[String] = argument.split("=")
                    flags[StringKey(flag[0][2:])] = flag[1]
                else:
                    flags[StringKey(argument[2:])] = ""
            else:
                args.append(argument)
