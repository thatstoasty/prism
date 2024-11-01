from memory import Arc
from prism import Command, Context


fn test(ctx: Context) raises -> None:
    name = ctx.command[].flags.get_string("name")
    print(String("Hello {}").format(name))


fn validate_name(ctx: Context, value: String) raises -> None:
    if value != "Mikhail":
        raise Error("ValueError: Name provided is not permitted.")


fn main() -> None:
    root = Command(
        name="greet",
        usage="Greet a user!",
        raising_run=test,
    )

    root.flags.string_flag(
        name="name",
        shorthand="n",
        usage="The name of the person to greet.",
        default="World",
        action=validate_name
    )

    root.execute()
