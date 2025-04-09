from memory import ArcPointer
from prism import Command, Context, Flag, Help, Version


fn test(ctx: Context) -> None:
    print("Pass -ch to see helpful information!")


fn main() -> None:
    Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        help=Help(flag=Flag.bool(name="custom-help", shorthand="ch", usage="My Cool Help Flag.")),
        version=Version("0.1.0", flag=Flag.bool(name="custom-version", shorthand="cv", usage="My Cool Version Flag.")),
    ).execute()
