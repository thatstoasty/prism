from sys import argv
from prism.stdlib.builtins import dict, HashableStr
from prism.command import Command, CommandMap, CommandTree
from prism.flag import Flag, InputFlags, PositionalArgs, get_args_and_flags

fn test(args: PositionalArgs, flags: InputFlags) raises -> None:
    print(flags["env"])


fn child_test(args: PositionalArgs, flags: InputFlags) raises -> None:
    print("I am a child!")


fn main() raises:
    # Just using a vector for now, since there's no (easy) way to get Strings out of Tuples or ListLiterals yet.
    var flags = InputFlags()
    var args = PositionalArgs()
    get_args_and_flags(args, flags)

    for item in flags.items():
        print("Flag: ", item.key, " Value: ", item.value)
    for i in range(len(args)):
        print("Arg: ", args[i])
    
    var command_map = CommandMap()
    var command_tree = CommandTree()
    var root_command = Command("prism", "test command", test)
    root_command.add_flag(Flag("env", "e", "Environment."))
    root_command.add_flag(Flag("verbose", "v", "Verbose output."))

    var child_command = Command("child", "child test command", child_test)
    command_map[child_command.name] = child_command
    command_tree[child_command.name] = root_command.name
    root_command.add_command(child_command)
    root_command.execute(args, flags, command_map)