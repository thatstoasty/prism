from prism import Flag, InputFlags, PositionalArgs, Command, CommandArc


fn printer(command: CommandArc, args: PositionalArgs) raises -> None:
    if len(args) == 0:
        print("No args provided.")
        return None

    print(args[0])


fn build_printer_command() raises -> Command:
    var cmd = Command(
        name="printer",
        description="Print the first arg.",
        run=printer,
    )
    return cmd
