from memory import ArcPointer

from prism import Command, Flag, FlagSet, read_args


fn printer(args: List[String], flags: FlagSet) -> None:
    if len(args) == 0:
        print("No args provided.")
        return

    print(args[0])


fn say(args: List[String], flags: FlagSet) -> None:
    print("Shouldn't be here!")


fn say_hello(args: List[String], flags: FlagSet) -> None:
    print("Hello World!")


fn say_goodbye(args: List[String], flags: FlagSet) -> None:
    print("Goodbye World!")


fn test(args: List[String], flags: FlagSet) -> None:
    if env := flags.get_string("env"):
        print("Env:", env.value())
    else:
        print("No env flag provided.")

    for item in flags:
        if item.value:
            print(item.name, item.value.value())
        else:
            print(item.name, "N/A")


fn main() -> None:
    var cli = Command(
        name="tones",
        usage="This is a dummy command!",
        run=test,
        flags=[Flag.string(name="env", shorthand="e", usage="Environment.")],
        children=[
            ArcPointer(Command(
                name="printer",
                usage="Print the first arg.",
                run=printer,
            )),
            ArcPointer(Command(
                name="say",
                usage="Say something to someone",
                run=say,
                children=[
                    ArcPointer(Command(
                        name="hello",
                        usage="Say hello to someone",
                        run=say_hello,
                    )),
                    ArcPointer(Command(
                        name="goodbye",
                        usage="Say goodbye to someone",
                        run=say_goodbye,
                    )),
                ],
            )),
        ],
    )
    cli.execute(read_args())
