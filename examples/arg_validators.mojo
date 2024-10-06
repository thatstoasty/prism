from memory import Arc
from prism import Command, CommandArc, no_args, valid_args, minimum_n_args, maximum_n_args, exact_args, range_args


fn test(command: Arc[Command], args: List[String]) -> None:
    var cmd = command
    for arg in args:
        print("Received", arg[])


fn hello(command: Arc[Command], args: List[String]) -> None:
    var cmd = command
    print(cmd[].name, "Hello from Chromeria!")


fn main() -> None:
    var root_command = Arc(
        Command(
            name="hello",
            description="This is a dummy command!",
            run=test,
        )
    )

    var no_args_command = Arc(
        Command(name="no_args", description="This is a dummy command!", run=hello, arg_validator=no_args)
    )
    var valid_args_command = Arc(
        Command(
            name="valid_args",
            description="This is a dummy command!",
            run=hello,
            arg_validator=valid_args(),
        )
    )
    var minimum_n_args_command = Arc(
        Command(
            name="minimum_n_args", description="This is a dummy command!", run=hello, arg_validator=minimum_n_args[4]()
        )
    )
    var maximum_n_args_command = Arc(
        Command(
            name="maximum_n_args", description="This is a dummy command!", run=hello, arg_validator=maximum_n_args[1]()
        )
    )
    var exact_args_command = Arc(
        Command(name="exact_args", description="This is a dummy command!", run=hello, arg_validator=exact_args[1]())
    )
    var range_args_command = Arc(
        Command(name="range_args", description="This is a dummy command!", run=hello, arg_validator=range_args[0, 1]())
    )

    root_command[].add_command(no_args_command)
    root_command[].add_command(valid_args_command)
    root_command[].add_command(minimum_n_args_command)
    root_command[].add_command(maximum_n_args_command)
    root_command[].add_command(exact_args_command)
    root_command[].add_command(range_args_command)
    root_command[].execute()
