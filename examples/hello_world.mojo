from memory import ArcPointer
from prism import Command, Context, Flag
import prism


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


fn say_hello(ctx: Context) -> None:
    print("Hello World!")


fn say_goodbye(ctx: Context) -> None:
    print("Goodbye World!")


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
    for item in ctx.command[].flags:
        if item[].value:
            print(item[].name, item[].value.value())
        else:
            print(item[].name, "N/A")

    return None


fn main() -> None:
    var hello_command = build_hello_command()
    var goodbye_command = build_goodbye_command()
    var printer_command = build_printer_command()

    Command(
        name="tones",
        usage="This is a dummy command!",
        run=test,
        flags=List[Flag](
            Flag.string(
                name="env",
                shorthand="e",
                usage="Environment.",
                default="",
            )
        ),
        children=List[ArcPointer[Command]](
            ArcPointer(Command(
                name="say",
                usage="Say something to someone",
                run=say,
                children=List[ArcPointer[Command]](
                    hello_command,
                    goodbye_command,
                ),
            )),
            printer_command,
        ),
    ).execute()
