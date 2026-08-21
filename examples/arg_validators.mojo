from prism import (
    Arg,
    ArgSet,
    Command,
    FlagSet,
    exact_args,
    maximum_n_args,
    minimum_n_args,
    no_args,
    range_args,
    read_args,
)


def test(args: ArgSet, flags: FlagSet) -> None:
    for arg in args:
        print("Received", arg)


def hello(args: ArgSet, flags: FlagSet) -> None:
    print("Hello from Chromeria!")


def main() -> None:
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
                name="valid_values",
                usage="This is a dummy command!",
                run=hello,
                args=[Arg.string(name="fruit", usage="Which fruit.", valid_values=["Pineapple"])],
            ),
            Command(name="no_args", usage="This is a dummy command!", run=hello, arg_validator=no_args),
        ],
    )
    cli.execute(read_args())
