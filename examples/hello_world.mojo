from memory import Arc
from prism import Command, Context


fn printer(context: Context) -> None:
    if len(context.args) == 0:
        print("No args provided.")
        return

    print(context.args[0])
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


fn say(context: Context) -> None:
    print("Shouldn't be here!")
    return None


fn say_hello(context: Context) -> None:
    print("Hello World!")
    return None


fn say_goodbye(context: Context) -> None:
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


fn test(context: Context) -> None:
    print(context.command[].flags.get_as_string("env").value())
    for item in context.command[].flags.flags:
        if item[].value:
            print(item[].name, item[].value.value())
        else:
            print(item[].name, "N/A")

    return None


fn main() -> None:
    var root = Command(
        name="tones",
        description="This is a dummy command!",
        run=test,
    )
    root.flags.add_string_flag(name="env", shorthand="e", usage="Environment.")

    var say_command = build_say_command()
    var hello_command = build_hello_command()
    var goodbye_command = build_goodbye_command()
    var printer_command = build_printer_command()

    say_command[].add_subcommand(goodbye_command)
    say_command[].add_subcommand(hello_command)
    root.add_subcommand(say_command)
    root.add_subcommand(printer_command)

    root.execute()
