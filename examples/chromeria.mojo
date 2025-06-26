from prism import Command, Flag, FlagSet


fn test(args: List[String], flags: FlagSet) -> None:
    print("Pass chromeria as a subcommand!")


fn hello(args: List[String], flags: FlagSet) -> None:
    print("Hello from Chromeria!")


fn main() -> None:
    var cli = Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        children=[Command(name="chromeria", usage="This is a dummy command!", run=hello)],
    )
    cli.execute()
