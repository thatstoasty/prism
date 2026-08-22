from prism import ArgSet, Command, Flag, FlagSet, read_args


def test(args: ArgSet, flags: FlagSet) -> None:
    print("Pass tool, object, or thing as a subcommand!")


def tool_func(args: ArgSet, flags: FlagSet) -> None:
    print("My tool!")


def main() -> None:
    var cli = Command(
        name="my",
        usage="This is a dummy command!",
        run=test,
        flags=[
            Flag.new[Bool](name="required", shorthand="r", usage="Always required.", required=True, persistent=True),
            Flag.new[String](
                name="host",
                shorthand="h",
                usage="Host",
                persistent=True,
            ),
            Flag.new[String](
                name="port",
                shorthand="p",
                usage="Port",
                persistent=True,
            ),
        ],
        flags_required_together=["host", "port"],
        children=[
            Command(
                name="tool",
                usage="This is a dummy command!",
                run=tool_func,
                flags=[
                    Flag.new[Bool](
                        name="also",
                        shorthand="a",
                        usage="Also always required.",
                        required=True,
                    ),
                    Flag.new[String](
                        name="uri",
                        shorthand="u",
                        usage="URI",
                    ),
                ],
                # mutually_exclusive_flags=["host", "uri"],
            )
        ],
    )
    cli.execute(read_args())
