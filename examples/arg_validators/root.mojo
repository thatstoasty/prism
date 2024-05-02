from prism import Flag, Command, CommandArc, no_args, valid_args, minimum_n_args, maximum_n_args, exact_args, range_args


fn test(command: CommandArc, args: List[String]) -> None:
    for arg in args:
        print("Received", arg[])


fn hello(command: CommandArc, args: List[String]) -> None:
    print(command[].name, "Hello from Chromeria!")


fn init() -> None:
    var root_command = Command(
        name="hello",
        description="This is a dummy command!",
        run=test,
    )

    var no_args_command = Command(
        name="no_args", description="This is a dummy command!", run=hello, arg_validator=no_args
    )
    var valid_args_command = Command(
        name="valid_args",
        description="This is a dummy command!",
        run=hello,
        arg_validator=valid_args[List[String]("Red", "Blue")](),
    )
    var minimum_n_args_command = Command(
        name="minimum_n_args", description="This is a dummy command!", run=hello, arg_validator=minimum_n_args[4]()
    )
    var maximum_n_args_command = Command(
        name="maximum_n_args", description="This is a dummy command!", run=hello, arg_validator=maximum_n_args[1]()
    )
    var exact_args_command = Command(
        name="exact_args", description="This is a dummy command!", run=hello, arg_validator=exact_args[1]()
    )
    var range_args_command = Command(
        name="range_args", description="This is a dummy command!", run=hello, arg_validator=range_args[0, 1]()
    )

    root_command.add_command(no_args_command)
    root_command.add_command(valid_args_command)
    root_command.add_command(minimum_n_args_command)
    root_command.add_command(maximum_n_args_command)
    root_command.add_command(exact_args_command)
    root_command.add_command(range_args_command)
    root_command.execute()


fn main() -> None:
    init()
