from prism import Flag, InputFlags, PositionalArgs, Command


fn printer(args: PositionalArgs, flags: InputFlags) raises -> None:
    print(args[0])


fn build_printer_command() raises -> Command:
    return Command(
        name="printer",
        description="Print the first arg.",
        run=printer,
    )
