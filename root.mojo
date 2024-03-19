from prism import Flag, InputFlags, PositionalArgs, Command
from say import build_say_command, build_hello_command, build_goodbye_command
from printer import build_printer_command


fn test(args: PositionalArgs, flags: InputFlags) raises -> None:
    for item in flags.items():
        print(item[].key.value, item[].value)


fn init() raises -> None:
    var root_command = Command(
        name        = "tones", 
        description = "This is a dummy command!", 
        run         = test
    )

    root_command.add_flag(Flag("env", "e", "Environment."))

    # var say_command = build_say_command()
    # root_command.add_command(say_command)

    # var hello_command = build_hello_command()
    # say_command.add_command(hello_command)

    # var goodbye_command = build_goodbye_command()
    # say_command.add_command(goodbye_command)

    # var printer_command = build_printer_command()
    # root_command.add_command(printer_command)

    root_command.execute()


fn main() raises -> None:
    init()
