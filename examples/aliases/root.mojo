from prism import FlagSet, Command


fn test(flags: FlagSet, args: List[String]) -> None:
    print("Pass tool, object, or thing as a subcommand!")


fn tool_func(flags: FlagSet, args: List[String]) -> None:
    print("My tool!")


fn init() -> None:
    var root_command = Command(
        name="my",
        description="This is a dummy command!",
        run=test,
    )

    var tool_command = Command(
        name="tool", description="This is a dummy command!", run=tool_func, aliases=List[String]("object", "thing")
    )

    root_command.add_command(tool_command)
    root_command.execute()


fn main() -> None:
    init()
