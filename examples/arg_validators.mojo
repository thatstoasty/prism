from memory import ArcPointer
from prism import (
    Command,
    Context,
    no_args,
    valid_args,
    minimum_n_args,
    maximum_n_args,
    exact_args,
    range_args,
)


fn test(ctx: Context) -> None:
    for arg in ctx.args:
        print("Received", arg[])


fn hello(ctx: Context) -> None:
    print(ctx.command[].name, "Hello from Chromeria!")


fn main() -> None:
    var no_args_command = ArcPointer(Command(name="no_args", usage="This is a dummy command!", run=hello, arg_validator=no_args))

    var valid_args_command = ArcPointer(
        Command(name="valid_args", usage="This is a dummy command!", run=hello, valid_args=List[String]("Pineapple"), arg_validator=valid_args)
    )
    var minimum_n_args_command = ArcPointer(Command(name="minimum_n_args", usage="This is a dummy command!", run=hello, arg_validator=minimum_n_args[4]()))
    var maximum_n_args_command = ArcPointer(Command(name="maximum_n_args", usage="This is a dummy command!", run=hello, arg_validator=maximum_n_args[1]()))
    var exact_args_command = ArcPointer(Command(name="exact_args", usage="This is a dummy command!", run=hello, arg_validator=exact_args[1]()))
    var range_args_command = ArcPointer(Command(name="range_args", usage="This is a dummy command!", run=hello, arg_validator=range_args[0, 1]()))

    var root = Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        children=List[ArcPointer[Command]](
            no_args_command,
            valid_args_command,
            minimum_n_args_command,
            maximum_n_args_command,
            exact_args_command,
            range_args_command,
        ),
    )

    root.execute()
