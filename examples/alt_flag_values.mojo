from memory import ArcPointer
from prism import Command, Context, Flag
import prism
import os


fn test(ctx: Context) raises -> None:
    var name = ctx.command[].flags.get_string("name")
    if name:
        print("Hello {}".format(name.value()))
    else:
        print("Hello World")


fn main() -> None:
    _ = os.setenv("NAME", "Mikhail")
    Command(
        name="greet",
        usage="Greet a user!",
        raising_run=test,
        flags=List[Flag](
            Flag.string(
                name="name",
                shorthand="n",
                usage="The name of the person to greet.",
                environment_variable=String("NAME"),
                file_path=String("~/.myapp/config"),
                default=String("World"),
            )
        ),
    ).execute()

    _ = os.unsetenv("NAME")
