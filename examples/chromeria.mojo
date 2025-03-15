from memory import ArcPointer
from prism import Command, Context


fn test(ctx: Context) -> None:
    print("Pass chromeria as a subcommand!")


fn hello(ctx: Context) -> None:
    print("Hello from Chromeria!")


fn main() -> None:
    Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        children=List[ArcPointer[Command]](
            ArcPointer(Command(name="chromeria", usage="This is a dummy command!", run=hello))
        ),
    ).execute()
