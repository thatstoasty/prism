from memory import ArcPointer
from prism import Command, Context


fn test(ctx: Context) -> None:
    print("Pass -v to see the version!")


fn version(version: String) -> String:
    return "MyCLI version: " + version


fn main() -> None:
    Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        version=String("0.1.0"),
        version_writer=version,
    ).execute()
