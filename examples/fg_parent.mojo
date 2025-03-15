from memory import ArcPointer
from prism import Command, Context, Flag
import prism


fn test(ctx: Context) raises -> None:
    var host = ctx.command[].get_string("host")
    var port = ctx.command[].get_string("port")
    var uri = ctx.command[].get_string("uri")

    if uri != "":
        print("URI:", uri)
    else:
        print(host + ":" + port)


fn tool_func(ctx: Context) -> None:
    print("My tool!")


fn main() -> None:
    Command(
        name="my",
        usage="This is a dummy command!",
        raising_run=test,
        flags=List[Flag](
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
        ),
        mutually_exclusive_flags=List[String]("host", "uri"),
        flags_required_together=List[String]("host", "port"),
    ).execute()
