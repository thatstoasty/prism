from sys import argv
from prism.stdlib.builtins import dict, HashableStr
from prism.command import Command, CommandMap, CommandTree
from prism.flag import Flag, InputFlags, PositionalArgs, get_args_and_flags
from say_hello import build_say_command, build_say_hello_command, build_say_goodbye_command

fn test(args: PositionalArgs, flags: InputFlags) raises -> None:
    print(flags["env"])


fn main() raises:
    # Just using a vector for now, since there's no (easy) way to get Strings out of Tuples or ListLiterals yet.
    var flags = InputFlags()
    var args = PositionalArgs()
    get_args_and_flags(args, flags)

    # for item in flags.items():
    #     print("Flag: ", item.key, " Value: ", item.value)
    # for i in range(len(args)):
    #     print("Arg: ", args[i])
    
    var command_map = CommandMap()
    var command_tree = CommandTree()
    var root_command = Command("prism", "test command", test)
    root_command.add_flag(Flag("env", "e", "Environment."))
    root_command.add_flag(Flag("verbose", "v", "Verbose output."))

    var say_command = build_say_command()
    command_map[say_command.name] = say_command
    command_tree[say_command.name] = root_command.name
    root_command.add_command(say_command)

    var say_hello_command = build_say_hello_command()
    command_map[say_hello_command.name] = say_hello_command
    command_tree[say_hello_command.name] = say_command.name
    say_command.add_command(say_hello_command)

    var say_goodbye_command = build_say_goodbye_command()
    command_map[say_goodbye_command.name] = say_goodbye_command
    command_tree[say_goodbye_command.name] = say_command.name
    say_command.add_command(say_goodbye_command)

    for item in command_tree.items():
        print(item.key, " -> ", item.value)

    root_command.execute(args, flags, command_map)