from memory import Arc
from prism import Command


fn printer(command: Arc[Command], args: List[String]) -> None:
    if len(args) == 0:
        print("No args provided.")
        return

    print(args[0])
    return


fn build_printer_command() -> Arc[Command]:
    var cmd = Arc(
        Command(
            name="printer",
            description="Print the first arg.",
            run=printer,
        )
    )
    return cmd


fn say(command: Arc[Command], args: List[String]) -> None:
    print("Shouldn't be here!")
    return None


fn say_hello(command: Arc[Command], args: List[String]) -> None:
    print("Hello World!")
    return None


fn say_goodbye(command: Arc[Command], args: List[String]) -> None:
    print("Goodbye World!")
    return None


# for some reason returning the command object without setting it to variable breaks the compiler
fn build_say_command() -> Arc[Command]:
    return Arc(
        Command(
            name="say",
            description="Say something to someone",
            run=say,
        )
    )


fn build_hello_command() -> Arc[Command]:
    var cmd = Arc(
        Command(
            name="hello",
            description="Say hello to someone",
            run=say_hello,
        )
    )
    return cmd


fn build_goodbye_command() -> Arc[Command]:
    var cmd = Arc(
        Command(
            name="goodbye",
            description="Say goodbye to someone",
            run=say_goodbye,
        )
    )
    return cmd


fn test(command: Arc[Command], args: List[String]) -> None:
    var cmd = command
    for item in cmd[].flags.flags:
        if item[].value:
            print(item[].name, item[].value.value())
        else:
            print(item[].name, "N/A")

    return None


fn main() -> None:
    var root_command = Arc(
        Command(
            name="tones",
            description="This is a dummy command!",
            run=test,
        )
    )
    root_command[].flags.add_string_flag(name="env", shorthand="e", usage="Environment.")

    var say_command = build_say_command()
    var hello_command = build_hello_command()
    var goodbye_command = build_goodbye_command()
    var printer_command = build_printer_command()

    say_command[].add_command(goodbye_command)
    say_command[].add_command(hello_command)
    root_command[].add_command(say_command)
    root_command[].add_command(printer_command)

    root_command[].execute()
