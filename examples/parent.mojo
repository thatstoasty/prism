from prism import ArgSet, Command, Flag, FlagSet, read_args


def test(args: ArgSet, flags: FlagSet) raises -> None:
    var host = flags.get[String]("host")
    var port = flags.get[String]("port")

    if var uri := flags.get[String]("uri"):
        print("URI:", uri[])
    elif host and port:
        print(host[] + ":" + port[])


def tool_func(args: ArgSet, flags: FlagSet) -> None:
    print("My tool!")


def main() -> None:
    var cli = Command(
        name="my",
        usage="This is a dummy command!",
        run=test,
        flags=[
            Flag.new[Bool](
                name="required",
                shorthand="r",
                usage="Always required.",
                required=True,
            ),
            Flag.new[String](
                name="host",
                shorthand="h",
                usage="Host",
            ),
            Flag.new[String](
                name="port",
                shorthand="p",
                usage="Port",
            ),
            Flag.new[String](
                name="uri",
                shorthand="u",
                usage="URI",
            ),
        ],
        mutually_exclusive_flags=["host", "uri"],
        flags_required_together=["host", "port"],
    )
    cli.execute(read_args())
