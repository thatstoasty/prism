from sys import argv
from prism.external.stdlib.builtins import dict, HashableStr, list
from prism.external.stdlib.builtins.vector import contains


fn contains_flag(vector: Flags, value: String) -> Bool:
    for i in range(vector.size):
        if String(vector[i].name) == value:
            return True
    return False


fn string(vector: DynamicVector[Flag]) -> String:
    var result = String("[")
    for i in range(vector.size):
        result += vector[i].__str__()
        if i < vector.size - 1:
            result += String(", ")
    result += String("]")
    return result


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
alias InputFlags = dict[HashableStr, String]
alias PositionalArgs = list[String]


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
    let input = argv()
    for i in range(len(input)):
        if i != 0:
            let argument = String(input[i])
            if argument.find("--") != -1:
                if argument.find("=") != -1:
                    let flag = argument.split("=")
                    flags[HashableStr(flag[0][2:])] = flag[1]
                else:
                    flags[HashableStr(argument[2:])] = ""
            else:
                args.append(argument)
