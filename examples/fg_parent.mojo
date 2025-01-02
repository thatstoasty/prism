from memory import ArcPointer
from prism import Command, Context
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
    var root = Command(
        name="my",
        usage="This is a dummy command!",
        raising_run=test,
        flags=List[prism.Flag](
            prism.bool_flag(
                name="required",
                shorthand="r",
                usage="Always required.",
                required=True,
            ),
            prism.string_flag(
                name="host",
                shorthand="h",
                usage="Host",
            ),
            prism.string_flag(
                name="port",
                shorthand="p",
                usage="Port",
            ),
            prism.string_flag(
                name="uri",
                shorthand="u",
                usage="URI",
            ),
        ),
        mutually_exclusive_flags=List[String]("host", "uri"),
        flags_required_together=List[String]("host", "port"),
    )

    root.execute()
