from memory import ArcPointer
from prism import Command, Context
import prism


fn test(ctx: Context) -> None:
    print("Pass tool, object, or thing as a subcommand!")


fn tool_func(ctx: Context) -> None:
    print("My tool!")


fn main() -> None:
    var root = Command(
        name="my",
        usage="This is a dummy command!",
        run=test,
        flags=List[prism.Flag](
            prism.bool_flag(
                name="required",
                shorthand="r",
                usage="Always required.",
                required=True,
                persistent=True,
            ),
            prism.string_flag(
                name="host",
                shorthand="h",
                usage="Host",
                persistent=True,
            ),
            prism.string_flag(
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
                    flags=List[prism.Flag](
                        prism.bool_flag(
                            name="also",
                            shorthand="a",
                            usage="Also always required.",
                            required=True,
                        ),
                        prism.string_flag(
                            name="uri",
                            shorthand="u",
                            usage="URI",
                        ),
                    ),
                    # mutally_exclusive_flags=List[String]("host", "uri"),
                    # flags_required_together=List[String]("host", "port"),
                )
            )
        ),
    )

    root.execute()
