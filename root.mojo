from prism import Command, CommandMap, add_command, Flag, InputFlags, PositionalArgs
from say import build_say_command, build_hello_command, build_goodbye_command
from printer import build_printer_command

fn test(args: PositionalArgs, flags: InputFlags) raises -> None:
    for item in flags.items():
        print(item.key, item.value)


fn main() raises:
    var command_map = CommandMap()
    var root_command = Command(
        name        = "prism", 
        description = "This is a dummy command!", 
        run         = test
    )

    root_command.add_flag(Flag("env", "e", "Environment."))
    root_command.add_flag(Flag("verbose", "v", "Verbose output."))
    command_map[root_command.name] = root_command

    var say_command = build_say_command()
    add_command(say_command, root_command, command_map)

    var hello_command = build_hello_command()
    add_command(hello_command, say_command, command_map)

    var goodbye_command = build_goodbye_command()
    add_command(goodbye_command, say_command, command_map)

    var printer_command = build_printer_command()
    add_command(printer_command, root_command, command_map)

    root_command.execute(command_map)