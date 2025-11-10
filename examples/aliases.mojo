from sys import argv

from memory import ArcPointer

from prism import Command, Flag, FlagSet, read_args


fn test(args: List[String], flags: FlagSet) -> None:
    print("Pass tool, object, or thing as a subcommand!")


fn tool_func(args: List[String], flags: FlagSet) -> None:
    print("My tool!")


fn main() -> None:
    var cli = Command(
        name="my_command",
        usage="This is a dummy command!",
        run=test,
        children=[
            ArcPointer(Command(name="tool", usage="This is a dummy command!", run=tool_func, aliases=["object", "thing"]))
        ],
    )

    cli.execute(read_args())
