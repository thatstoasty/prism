from memory import Arc
from prism import Command, Context


fn test(context: Context) -> None:
    print("Pass chromeria as a subcommand!")


fn hello(context: Context) -> None:
    print("Hello from Chromeria!")


fn main() -> None:
    var root = Command(
        name="hello",
        description="This is a dummy command!",
        run=test,
    )

    var hello_command = Arc(Command(name="chromeria", description="This is a dummy command!", run=hello))

    root.add_subcommand(hello_command)
    root.execute()
