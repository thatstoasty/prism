from memory import Arc
from prism import Command, Context


fn test(ctx: Context) raises -> None:
    name = ctx.command[].flags.get_string_list("name")
    print(String("Hello {}").format(" ".join(name)))


fn main() -> None:
    root = Command(
        name="greet",
        usage="Greet a user!",
        raising_run=test,
    )

    root.flags.string_list_flag(
        name="name",
        shorthand="n",
        usage="The name of the person to greet.",
        default=List[String]("Mikhail Tavarez"),
    )

    root.execute()
