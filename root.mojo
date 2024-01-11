from prism import Flag, InputFlags, PositionalArgs, Command, CommandMap, add_command
from say import build_say_command, build_hello_command, build_goodbye_command
from printer import build_printer_command


fn test(args: PositionalArgs, flags: InputFlags) raises -> None:
    for item in flags.items():
        print(item.key, item.value)


fn test(command: Command, args: PositionalArgs) raises -> None:
    for item in command.input_flags.items():
        print(item.key, item.value)


fn init() raises -> None:
    var command_map = CommandMap()
    var root_command = Command(
        name        = "tones", 
        description = "This is a dummy command!", 
        run         = test
    )

    root_command.add_flag(Flag("env", "e", "Environment."))
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


fn main() raises -> None:
    init()
