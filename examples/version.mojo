from memory import ArcPointer
from prism import Command, Context, Version, Flag


fn test(ctx: Context) -> None:
    print("Pass -v to see the version!")


fn version(ctx: Context) -> String:
    return "MyCLI version: " + ctx.command[].version.value().value


fn main() -> None:
    Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        version=Version("0.1.0", action=version),
    ).execute()
