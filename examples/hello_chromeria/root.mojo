from prism import Flag, Command, CommandArc


fn test(command: CommandArc, args: List[String]) -> None:
    print("Pass hello as a subcommand!")


fn hello(command: CommandArc, args: List[String]) -> None:
    print("Hello from Chromeria!")


fn init() -> None:
    var root_command = Command(
        name="hello",
        description="This is a dummy command!",
        run=test,
    )

    var hello_command = Command(name="chromeria", description="This is a dummy command!", run=hello)

    root_command.add_command(hello_command)
    root_command.execute()


fn main() -> None:
    init()
