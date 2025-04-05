from memory import ArcPointer
from prism import Command, Context, Flag
import prism


fn test(ctx: Context) -> None:
    print("Pass tool, object, or thing as a subcommand!")


fn tool_func(ctx: Context) -> None:
    print("My tool!")


fn main() -> None:
    Command(
        name="my",
        usage="This is a dummy command!",
        run=test,
        flags=List[Flag](
            Flag.bool(name="required", shorthand="r", usage="Always required.", required=True, persistent=True),
            Flag.string(
                name="host",
                shorthand="h",
                usage="Host",
                persistent=True,
            ),
            Flag.string(
                name="port",
                shorthand="p",
                usage="Port",
                persistent=True,
            ),
        ),
        children=List[ArcPointer[Command]](
            ArcPointer(
                Command(
                    name="tool",
                    usage="This is a dummy command!",
                    run=tool_func,
                    flags=List[Flag](
                        Flag.bool(
                            name="also",
                            shorthand="a",
                            usage="Also always required.",
                            required=True,
                        ),
                        Flag.string(
                            name="uri",
                            shorthand="u",
                            usage="URI",
                        ),
                    ),
                    # mutually_exclusive_flags=List[String]("host", "uri"),
                    # flags_required_together=List[String]("host", "port"),
                )
            )
        ),
    ).execute()
