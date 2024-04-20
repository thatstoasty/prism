from prism import Flag, Command
from prism.command import CommandArc


fn printer(command: CommandArc, args: List[String]) -> Error:
    if len(args) == 0:
        print("No args provided.")
        return Error()

    print(args[0])
    return Error()


fn build_printer_command() -> Command:
    var cmd = Command(
        name="printer",
        description="Print the first arg.",
        run=printer,
    )
    return cmd
