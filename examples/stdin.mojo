from prism import Command, FlagSet


fn test(args: List[String], flags: FlagSet) -> None:
    for arg in args:
        print("Received:", arg)


fn main() -> None:
    var cli = Command(name="hello", usage="This is a dummy command!", run=test, read_from_stdin=True)
    cli.execute()
