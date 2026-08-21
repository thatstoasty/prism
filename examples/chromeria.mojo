from prism import ArgSet, Command, Flag, FlagSet, read_args


def test(args: ArgSet, flags: FlagSet) -> None:
    print("Pass chromeria as a subcommand!")


def hello(args: ArgSet, flags: FlagSet) -> None:
    print("Hello from Chromeria!")


def main() -> None:
    var cli = Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        children=[
            Command(name="chromeria", usage="This is a dummy command!", run=hello)
        ],
    )
    cli.execute(read_args())
