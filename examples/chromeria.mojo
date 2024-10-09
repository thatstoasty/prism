from memory import Arc
from prism import Command, Context


fn test(ctx: Context) -> None:
    print("Pass chromeria as a subcommand!")


fn hello(ctx: Context) -> None:
    print("Hello from Chromeria!")


fn main() -> None:
    var root = Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
    )

    var hello_command = Arc(Command(name="chromeria", usage="This is a dummy command!", run=hello))

    root.add_subcommand(hello_command)
    root.execute()
