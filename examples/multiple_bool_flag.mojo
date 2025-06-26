from prism import Command, FlagSet, Flag


fn test(args: List[String], flags: FlagSet) raises -> None:
    if flags.get_bool("required"):
        print("Required flag is set!")
    if flags.get_bool("automation"):
        print("Automation flag is set!")
    if flags.get_bool("secure"):
        print("Secure flag is set!")
    if flags.get_bool("verbose"):
        print("Verbose flag is set!")

    if len(args) > 0:
        print("Arguments:", args.__str__())


fn main() -> None:
    var cli = Command(
        name="my",
        usage="This is a dummy command!",
        raising_run=test,
        flags=[
            Flag.bool(
                name="required",
                shorthand="r0",
                usage="Always required.",
                required=True,
            ),
            Flag.bool(
                name="automation",
                shorthand="a",
                usage="In automation?",
            ),
            Flag.bool(
                name="secure",
                shorthand="s",
                usage="Use SSL?",
            ),
            Flag.bool(
                name="verbose",
                shorthand="vv",
                usage="Verbose output.",
            ),
        ],
    )
    cli.execute()
