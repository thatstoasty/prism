from memory import ArcPointer
from prism import Command, Context


fn test(ctx: Context) -> None:
    print("Pass -v to see the version!")


fn version() -> String:
    return "MyCLI version 0.1.0"


fn main() -> None:
    Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        version=version,
    ).execute()
