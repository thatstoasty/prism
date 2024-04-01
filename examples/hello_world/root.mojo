from prism import Flag, InputFlags, PositionalArgs, Command
from prism.vector import to_string
from examples.hello_world.say import build_say_command, build_hello_command, build_goodbye_command
from examples.hello_world.printer import build_printer_command
from memory._arc import Arc


fn test(command: Arc[Command], args: PositionalArgs) raises -> None:
    for item in command[].get_all_flags()[].flags:
        print(item[].name, item[].value)


fn init() raises -> None:
    var root_command = Command(
        name="tones", description="This is a dummy command!", run=test
    )

    root_command.add_flag(Flag(name="env", shorthand="e", usage="Environment."))

    var say_command = build_say_command()
    var hello_command = build_hello_command()
    var goodbye_command = build_goodbye_command()
    var printer_command = build_printer_command()

    say_command.add_command(goodbye_command)
    say_command.add_command(hello_command)
    root_command.add_command(say_command)
    root_command.add_command(printer_command)

    root_command.execute()


fn main() raises -> None:
    init()
