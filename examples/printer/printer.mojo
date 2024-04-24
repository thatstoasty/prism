from time import now
from prism import Flag, Command, CommandArc, exact_args
from external.mist import TerminalStyle


fn printer(command: CommandArc, args: List[String]) -> None:
    if len(args) <= 0:
        print("No text to print! Pass in some text as a positional argument.")
        return None

    var color = command[].flags[].get_as_string("color")
    var formatting = command[].flags[].get_as_string("formatting")
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
    return None


fn pre_hook(command: CommandArc, args: List[String]) -> None:
    print("Pre-hook executed!")
    return None


fn post_hook(command: CommandArc, args: List[String]) -> None:
    print("Post-hook executed!")
    return None


fn init() -> None:
    var start = now()
    var root_command = Command(
        name="printer",
        description="Base command.",
        run=printer,
        pre_run=pre_hook,
        post_run=post_hook,
        arg_validator=exact_args[1](),
    )

    root_command.add_string_flag(name="color", shorthand="c", usage="Text color", default="#3464eb")
    root_command.add_string_flag(name="formatting", shorthand="f", usage="Text formatting")

    root_command.execute()
    print("duration", (now() - start) / 1e9)


fn main() -> None:
    init()
