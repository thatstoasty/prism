from memory import Arc
from prism import Command


fn test(inout command: Arc[Command], args: List[String]) -> None:
    print("Pass chromeria as a subcommand!")


fn hello(inout command: Arc[Command], args: List[String]) -> None:
    print("Hello from Chromeria!")


fn main() -> None:
    var root = Arc(
        Command(
            name="hello",
            description="This is a dummy command!",
            run=test,
        )
    )

    var hello_command = Arc(Command(name="chromeria", description="This is a dummy command!", run=hello))

    root[].add_subcommand(hello_command)
    root[].execute()
