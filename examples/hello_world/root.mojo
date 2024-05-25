from prism import FlagSet, Command, arbitrary_args
from examples.hello_world.say import (
    build_say_command,
    build_hello_command,
    build_goodbye_command,
)
from examples.hello_world.printer import build_printer_command


fn test(flag_set: FlagSet, args: List[String]) -> None:
    for item in flag_set.flags:
        print(item[].name, item[].value.value()[])

    return None


fn init() -> None:
    var root_command = Command(
        name="tones",
        description="This is a dummy command!",
        run=test,
    )
    root_command.add_string_flag(name="env", shorthand="e", usage="Environment.")

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
