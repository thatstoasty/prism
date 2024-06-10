from prism import Command, CommandArc


fn printer(command: Arc[Command], args: List[String]) -> None:
    if len(args) == 0:
        print("No args provided.")
        return

    print(args[0])
    return


fn build_printer_command() -> Arc[Command]:
    var cmd = Arc(
        Command(
            name="printer",
            description="Print the first arg.",
            run=printer,
        )
    )
    return cmd
