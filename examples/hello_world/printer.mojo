from prism import FlagSet, Command


fn printer(flag_set: FlagSet, args: List[String]) -> None:
    if len(args) == 0:
        print("No args provided.")
        return

    print(args[0])
    return


fn build_printer_command() -> Command:
    var cmd = Command(
        name="printer",
        description="Print the first arg.",
        run=printer,
    )
    return cmd
