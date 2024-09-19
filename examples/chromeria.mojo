from memory import Arc
from prism import Command


fn test(command: Arc[Command], args: List[String]) -> None:
    print("Pass chromeria as a subcommand!")


fn hello(command: Arc[Command], args: List[String]) -> None:
    print("Hello from Chromeria!")


fn main() -> None:
    var root_command = Arc(
        Command(
            name="hello",
            description="This is a dummy command!",
            run=test,
        )
    )

    var hello_command = Arc(Command(name="chromeria", description="This is a dummy command!", run=hello))

    root_command[].add_command(hello_command)
    root_command[].execute()
