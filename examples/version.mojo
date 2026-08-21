from prism import ArgSet, Command, Flag, FlagSet, Version, read_args


def test(args: ArgSet, flags: FlagSet) -> None:
    print("Pass -v to see the version!")


def version(name: String, version: String) -> String:
    return String("MyCLI version: ", version)


def main() -> None:
    var cli = Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        version=Version("0.1.0", action=version),
    )
    cli.execute(read_args())
