from memory import ArcPointer
from prism import (
    Command,
    FlagSet,
    no_args,
    valid_args,
    minimum_n_args,
    maximum_n_args,
    exact_args,
    range_args,
)


fn test(args: List[String], flags: FlagSet) -> None:
    for arg in args:
        print("Received", arg)


fn hello(args: List[String], flags: FlagSet) -> None:
    print("Hello from Chromeria!")


fn main() -> None:
    var cli = Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        children=[
            Command(
                name="minimum_n_args", usage="This is a dummy command!", run=hello, arg_validator=minimum_n_args[4]()
            ),
            Command(
                name="maximum_n_args", usage="This is a dummy command!", run=hello, arg_validator=maximum_n_args[1]()
            ),
            Command(name="exact_args", usage="This is a dummy command!", run=hello, arg_validator=exact_args[1]()),
            Command(name="range_args", usage="This is a dummy command!", run=hello, arg_validator=range_args[0, 1]()),
            Command(
                name="valid_args",
                usage="This is a dummy command!",
                run=hello,
                valid_args=List[String]("Pineapple"),
                arg_validator=valid_args,
            ),
            Command(name="no_args", usage="This is a dummy command!", run=hello, arg_validator=no_args),
        ],
    )
    cli.execute()
