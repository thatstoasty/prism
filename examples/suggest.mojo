from prism import ArgSet, Command, FlagSet, read_args


def test(args: ArgSet, flags: FlagSet) -> None:
    for arg in args:
        print("Received:", arg)


def main() -> None:
    var cli = Command(name="hello", usage="This is a dummy command!", run=test, suggest=True)
    cli.execute(read_args())
