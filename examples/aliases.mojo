from prism import Command, Flag, FlagSet


fn test(args: List[String], flags: FlagSet) -> None:
    print("Pass tool, object, or thing as a subcommand!")


fn tool_func(args: List[String], flags: FlagSet) -> None:
    print("My tool!")


fn main() -> None:
    var cli = Command(
        name="my",
        usage="This is a dummy command!",
        run=test,
        children=[Command(name="tool", usage="This is a dummy command!", run=tool_func, aliases=["object", "thing"])],
    )
    cli.execute()
