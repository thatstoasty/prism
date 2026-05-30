from prism import Command, Flag, FlagSet, read_args


def test(args: List[String], flags: FlagSet) raises -> None:
    if name := flags.get_string("name"):
        print("Hello", name[])
    else:
        print("Hello World")


def validate_name(value: String) raises -> None:
    if value != "Mikhail":
        raise Error("ValueError: Name provided is not permitted.")


def main() -> None:
    var cli = Command(
        name="greet",
        usage="Greet a user!",
        run=test,
        flags=[
            Flag.string(
                name="name",
                shorthand="n",
                usage="The name of the person to greet.",
                default=String("World"),
                action=validate_name,
            )
        ],
    )
    cli.execute(read_args())
