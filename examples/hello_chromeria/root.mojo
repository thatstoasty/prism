from prism import FlagSet, Command, CLI


fn test(flags: FlagSet, args: List[String]) -> None:
    print("Pass chromeria as a subcommand!")


fn hello(flags: FlagSet, args: List[String]) -> None:
    print("Hello from Chromeria!")


fn init() -> None:
    var root_command = Command(
        name="hello",
        description="This is a dummy command!",
        run=test,
    )
    var hello_command = Command(name="chromeria", description="This is a dummy command!", run=hello)
    var cli = CLI()
    cli.add_command(root_command)
    cli.add_command(hello_command, parent_name=root_command.name)
    cli.run()


fn main() -> None:
    init()
