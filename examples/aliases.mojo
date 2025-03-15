from memory import ArcPointer
from prism import Context, Command


fn test(ctx: Context) -> None:
    print("Pass tool, object, or thing as a subcommand!")


fn tool_func(ctx: Context) -> None:
    print("My tool!")


fn main() -> None:
    Command(
        name="my",
        usage="This is a dummy command!",
        run=test,
        children=List[ArcPointer[Command]](
            ArcPointer(
                Command(
                    name="tool",
                    usage="This is a dummy command!",
                    run=tool_func,
                    aliases=List[String]("object", "thing")
                )
            )
        ),
    ).execute()
    