from memory import ArcPointer
from prism import Command, Context, Flag
import prism
import os


fn test(ctx: Context) raises -> None:
    name = ctx.command[].get_string("name")
    print("Hello {}".format(name))


fn main() -> None:
    _ = os.setenv("NAME", "Mikhail")
    root = Command(
        name="greet",
        usage="Greet a user!",
        raising_run=test,
        flags=List[Flag](
            prism.string_flag(
                name="name",
                shorthand="n",
                usage="The name of the person to greet.",
                environment_variable="NAME",
                file_path="~/.myapp/config",
                default="World",
            )
        ),
    )

    root.execute()
    _ = os.unsetenv("NAME")
