from sys import argv
from prism.stdlib.builtins import dict, HashableStr


@value
struct Flag(CollectionElement):
    var name: String
    var shorthand: String
    var usage: String


alias Flags = DynamicVector[Flag]
alias InputFlags = dict[HashableStr, String]
alias PositionalArgs = DynamicVector[String]


fn get_args_and_flags(
    inout args: PositionalArgs, inout flags: InputFlags
) raises -> None:
    """Parses flags and args from the args passed via the command line."""
    let input = argv()
    for i in range(len(input)):
        if i != 0:
            let argument = String(input[i])

            if argument.find("--") != -1:
                let flag: PositionalArgs = argument.split("=")
                flags[HashableStr(flag[0][2:])] = flag[1]
            else:
                args.append(argument)
