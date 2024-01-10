from prism.flag import Flag, InputFlags, PositionalArgs, get_args_and_flags
from prism.command import Command


fn printer(args: PositionalArgs, flags: InputFlags) raises -> None:
    print(args[0])


fn build_printer_command() raises -> Command:
    return Command(
        name="printer",
        description="Print the first arg.",
        run=printer,
    )
