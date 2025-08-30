from prism import Command, Flag, FlagSet, Version


fn test(args: List[String], flags: FlagSet) -> None:
    print("Pass -v to see the version!")


fn version(version: String) -> String:
    return String("MyCLI version: ", version)


fn main() -> None:
    var cli = Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        version=Version("0.1.0", action=version),
    )
    cli.execute()
