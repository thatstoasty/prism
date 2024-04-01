from prism import Flag, InputFlags, PositionalArgs, Command, CommandArc
from python import Python, PythonObject
from examples.printer.mist import TerminalStyle


fn printer(command: CommandArc, args: PositionalArgs) raises -> None:
    if len(args) <= 0:
        print("No text to print! Pass in some text as a positional argument.")
        return None

    var flags = command[].get_all_flags()[]
    var color = flags.get_as_string("color")
    var formatting = flags.get_as_string("formatting")
    var style = TerminalStyle()

    if not color:
        color = String("")
    if not formatting:
        formatting = String("")

    if color.value() != "":
        style.color(color.value())
    if formatting.value() == "bold":
        style.bold()
    elif formatting.value() == "underline":
        style.underline()
    elif formatting.value() == "italic":
        style.italic()

    print(style.render(args[0]))


fn pre_hook(command: CommandArc, args: PositionalArgs) raises -> None:
    print("Pre-hook executed!")


fn post_hook(command: CommandArc, args: PositionalArgs) raises -> None:
    print("Post-hook executed!")


fn init() raises -> None:
    var root_command = Command(
        name="printer",
        description="Base command.",
        pre_run=pre_hook,
        run=printer,
        post_run=post_hook,
    )
    root_command.add_flag(
        Flag(name="color", shorthand="c", usage="Text color", default="blue")
    )
    root_command.add_flag(
        Flag(name="formatting", shorthand="f", usage="Text formatting")
    )

    root_command.execute()


fn main() raises -> None:
    init()
