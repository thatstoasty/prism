from prism import Command, Flag, FlagSet
import os


fn test(args: List[String], flags: FlagSet) raises -> None:
    var name = flags.get_string("name")
    if name:
        print("Hello", name.value())
    else:
        print("Hello World")


fn main() -> None:
    _ = os.setenv("NAME", "Mikhail")
    var cli = Command(
        name="greet",
        usage="Greet a user!",
        raising_run=test,
        flags=[
            Flag.string(
                name="name",
                shorthand="n",
                usage="The name of the person to greet.",
                environment_variable=String("NAME"),
                file_path=String("~/.myapp/config"),
                default=String("World"),
            )
        ],
    )
    cli.execute()

    _ = os.unsetenv("NAME")
