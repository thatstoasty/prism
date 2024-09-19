from memory import Arc
from prism import Command, CommandArc


fn test(command: Arc[Command], args: List[String]) -> None:
    print("Pass tool, object, or thing as a subcommand!")


fn tool_func(command: Arc[Command], args: List[String]) -> None:
    print("My tool!")


fn main() -> None:
    var root_command = Arc(
        Command(
            name="my",
            description="This is a dummy command!",
            run=test,
        )
    )

    var tool_command = Arc(
        Command(
            name="tool", description="This is a dummy command!", run=tool_func, aliases=List[String]("object", "thing")
        )
    )

    root_command[].add_command(tool_command)
    root_command[].execute()
