from prism import Flag, Command, CommandArc, exact_args
from external.mist import TerminalStyle


fn printer(command: CommandArc, args: List[String]) raises -> None:
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
        style = style.foreground(style.profile.color(color.value()))
    if formatting.value() == "bold":
        style = style.bold()
    elif formatting.value() == "underline":
        style = style.underline()
    elif formatting.value() == "italic":
        style = style.italic()

    print(style.render(args[0]))


fn pre_hook(command: CommandArc, args: List[String]) raises -> None:
    print("Pre-hook executed!")


fn post_hook(command: CommandArc, args: List[String]) raises -> None:
    print("Post-hook executed!")


fn init() raises -> None:
    var root_command = Command(
        name="printer",
        description="Base command.",
        arg_validator=exact_args[1](),
        pre_run=pre_hook,
        run=printer,
        post_run=post_hook,
    )
    root_command.add_flag(
        Flag(name="color", shorthand="c", usage="Text color", default="#3464eb")
    )
    root_command.add_flag(
        Flag(name="formatting", shorthand="f", usage="Text formatting")
    )

    root_command.execute()


fn main() raises -> None:
    init()
