from prism import ArgSet, Command, Flag, FlagSet, read_args


def test(args: ArgSet, flags: FlagSet) raises -> None:
    if flags.get[Bool]("required"):
        print("Required flag is set!")
    if flags.get[Bool]("automation"):
        print("Automation flag is set!")
    if flags.get[Bool]("secure"):
        print("Secure flag is set!")
    if flags.get[Bool]("verbose"):
        print("Verbose flag is set!")

    if len(args) > 0:
        print("Arguments:", args)


def main() -> None:
    var cli = Command(
        name="my",
        usage="This is a dummy command!",
        run=test,
        flags=[
            Flag.new[Bool](
                name="required",
                shorthand="r0",
                usage="Always required.",
                required=True,
            ),
            Flag.new[Bool](
                name="automation",
                shorthand="a",
                usage="In automation?",
            ),
            Flag.new[Bool](
                name="secure",
                shorthand="s",
                usage="Use SSL?",
            ),
            Flag.new[Bool](
                name="verbose",
                shorthand="vv",
                usage="Verbose output.",
            ),
        ],
    )
    cli.execute(read_args())
