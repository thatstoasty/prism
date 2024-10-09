from memory import Arc
from prism import Command, Context


fn test(ctx: Context) -> None:
    var host = ctx.command[].flags.get_string("host")
    var port = ctx.command[].flags.get_string("port")
    var uri = ctx.command[].flags.get_string("uri")

    if uri:
        print("URI: ", uri.value())
    else:
        print(host.value(), ":", port.value())


fn tool_func(ctx: Context) -> None:
    print("My tool!")


fn main() -> None:
    var root = Command(
        name="my",
        description="This is a dummy command!",
        run=test,
    )
    root.persistent_flags.bool_flag(name="required", shorthand="r", usage="Always required.")
    root.persistent_flags.string_flag(name="host", shorthand="h", usage="Host")
    root.persistent_flags.string_flag(name="port", shorthand="p", usage="Port")
    root.persistent_flags.string_flag(name="uri", shorthand="u", usage="URI")
    root.mark_flags_required_together("host", "port")
    root.mark_flags_mutually_exclusive("host", "uri")
    root.mark_flag_required("required")

    root.execute()
