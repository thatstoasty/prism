from prism import Command, FlagSet, Flag, Help, Version


fn test(args: List[String], flags: FlagSet) -> None:
    print("Pass -ch to see helpful information!")


fn main() -> None:
    var cli = Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        help=Help(flag=Flag.bool(name="custom-help", shorthand="ch", usage="My Cool Help Flag.")),
        version=Version("0.1.0", flag=Flag.bool(name="custom-version", shorthand="cv", usage="My Cool Version Flag.")),
    )
    cli.execute()
