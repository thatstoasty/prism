from memory import Arc
from prism import Context, Command


fn test(context: Context) -> None:
    print("Pass tool, object, or thing as a subcommand!")


fn tool_func(context: Context) -> None:
    print("My tool!")


fn main() -> None:
    var root = Command(
        name="my",
        description="This is a dummy command!",
        run=test,
    )

    var print_tool = Arc(
        Command(
            name="tool", description="This is a dummy command!", run=tool_func, aliases=List[String]("object", "thing")
        )
    )

    root.add_subcommand(print_tool)
    root.execute()
