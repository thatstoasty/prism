from prism import Flag, Command, arbitrary_args
from prism.command import CommandArc
from prism.vector import to_string
from examples.hello_world.say import (
    build_say_command,
    build_hello_command,
    build_goodbye_command,
)
from examples.hello_world.printer import build_printer_command
from memory._arc import Arc


# TODO: Using CommandArc instead of Arc[Command] works. But using Arc[Command] causes a recursive relationship error?
fn test(command: CommandArc, args: List[String]) -> Error:
    for item in command[].get_all_flags()[].flags:
        print(item[].name, item[].value.value())

    return Error()


fn init() -> None:
    var root_command = Command(
        name="tones",
        description="This is a dummy command!",
        run=test,
    )

    root_command.flags.add_string_flag[name="env", shorthand="e", usage="Environment."]()

    var say_command = build_say_command()
    var hello_command = build_hello_command()
    var goodbye_command = build_goodbye_command()
    var printer_command = build_printer_command()

    say_command.add_command(goodbye_command)
    say_command.add_command(hello_command)
    root_command.add_command(say_command)
    root_command.add_command(printer_command)

    root_command.execute()


fn main() -> None:
    init()
