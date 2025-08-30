import prism
from prism import Command, Flag, FlagSet


fn test(args: List[String], flags: FlagSet) raises -> None:
    var host = flags.get_string("host")
    var port = flags.get_string("port")

    if uri := flags.get_string("uri"):
        print("URI:", uri[])
    elif host and port:
        print(host[] + ":" + port[])


fn tool_func(args: List[String], flags: FlagSet) -> None:
    print("My tool!")


fn main() -> None:
    var cli = Command(
        name="my",
        usage="This is a dummy command!",
        raising_run=test,
        flags=[
            Flag.bool(
                name="required",
                shorthand="r",
                usage="Always required.",
                required=True,
            ),
            Flag.string(
                name="host",
                shorthand="h",
                usage="Host",
            ),
            Flag.string(
                name="port",
                shorthand="p",
                usage="Port",
            ),
            Flag.string(
                name="uri",
                shorthand="u",
                usage="URI",
            ),
        ],
        mutually_exclusive_flags=["host", "uri"],
        flags_required_together=["host", "port"],
    )
    cli.execute()
