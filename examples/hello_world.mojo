from memory import ArcPointer
from prism import Command, Context


fn printer(ctx: Context) -> None:
    if len(ctx.args) == 0:
        print("No args provided.")
        return

    print(ctx.args[0])
    return


fn build_printer_command() -> ArcPointer[Command]:
    var cmd = ArcPointer(
        Command(
            name="printer",
            usage="Print the first arg.",
            run=printer,
        )
    )
    return cmd


fn say(ctx: Context) -> None:
    print("Shouldn't be here!")
    return None


fn say_hello(ctx: Context) -> None:
    print("Hello World!")
    return None


fn say_goodbye(ctx: Context) -> None:
    print("Goodbye World!")
    return None


# for some reason returning the command object without setting it to variable breaks the compiler
fn build_say_command() -> ArcPointer[Command]:
    return ArcPointer(
        Command(
            name="say",
            usage="Say something to someone",
            run=say,
        )
    )


fn build_hello_command() -> ArcPointer[Command]:
    var cmd = ArcPointer(
        Command(
            name="hello",
            usage="Say hello to someone",
            run=say_hello,
        )
    )
    return cmd


fn build_goodbye_command() -> ArcPointer[Command]:
    var cmd = ArcPointer(
        Command(
            name="goodbye",
            usage="Say goodbye to someone",
            run=say_goodbye,
        )
    )
    return cmd


fn test(ctx: Context) -> None:
    try:
        print(ctx.command[].flags.get_string("env"))
    except:
        print("No env flag provided.")
    for item in ctx.command[].flags.flags:
        if item[].value:
            print(item[].name, item[].value.value())
        else:
            print(item[].name, "N/A")

    return None


fn main() -> None:
    var root = Command(
        name="tones",
        usage="This is a dummy command!",
        run=test,
    )
    root.flags.string_flag(name="env", shorthand="e", usage="Environment.", default="")

    var say_command = build_say_command()
    var hello_command = build_hello_command()
    var goodbye_command = build_goodbye_command()
    var printer_command = build_printer_command()

    say_command[].add_subcommand(goodbye_command)
    say_command[].add_subcommand(hello_command)
    root.add_subcommand(say_command)
    root.add_subcommand(printer_command)

    root.execute()
