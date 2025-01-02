from memory import ArcPointer
from prism import Command, Context, Flag
from prism.flag_set import string_flag


fn test(ctx: Context) raises -> None:
    name = ctx.command[].get_string("name")
    print(String("Hello {}").format(name))


fn validate_name(ctx: Context, value: String) raises -> None:
    if value != "Mikhail":
        raise Error("ValueError: Name provided is not permitted.")


fn main() -> None:
    root = Command(
        name="greet",
        usage="Greet a user!",
        raising_run=test,
        flags=List[Flag](
            string_flag(
                name="name",
                shorthand="n",
                usage="The name of the person to greet.",
                default="World",
                action=validate_name,
            )
        ),
    )

    root.execute()
