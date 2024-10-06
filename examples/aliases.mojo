from memory import Arc
from prism import Command, CommandArc


fn test(inout command: Arc[Command], args: List[String]) -> None:
    print("Pass tool, object, or thing as a subcommand!")


fn tool_func(inout command: Arc[Command], args: List[String]) -> None:
    print("My tool!")


fn main() -> None:
    var root = Arc(
        Command(
            name="my",
            description="This is a dummy command!",
            run=test,
        )
    )

    var print_tool = Arc(
        Command(
            name="tool", description="This is a dummy command!", run=tool_func, aliases=List[String]("object", "thing")
        )
    )

    root[].add_subcommand(print_tool)
    root[].execute()
