from memory import ArcPointer
from prism import Command, Context, Flag
import prism


fn test(ctx: Context) raises -> None:
    var name = ctx.command[].flags.get_string("name")
    if name:
        print("Hello", name.value())
    else:
        print("Hello World")


fn validate_name(ctx: Context, value: String) raises -> None:
    if value != "Mikhail":
        raise Error("ValueError: Name provided is not permitted.")


fn main() -> None:
    Command(
        name="greet",
        usage="Greet a user!",
        raising_run=test,
        flags=List[Flag](
            Flag.string(
                name="name",
                shorthand="n",
                usage="The name of the person to greet.",
                default=String("World"),
                action=validate_name,
            )
        ),
    ).execute()
