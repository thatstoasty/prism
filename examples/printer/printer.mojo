from prism import Command, CommandArc, exact_args
from external.mist import TerminalStyle


fn printer(command: Arc[Command], args: List[String]) -> None:
    var cmd = command
    if len(args) <= 0:
        print("No text to print! Pass in some text as a positional argument.")
        return None

    var color = cmd[].flags.get_as_string("color")
    var formatting = cmd[].flags.get_as_string("formatting")
    var style = TerminalStyle()

    if not color:
        color = String("")
    if not formatting:
        formatting = String("")

    if color.or_else("") != "":
        style = style.foreground(style.profile.color(color.value()[]))

    var formatting_value = formatting.or_else("")
    if formatting_value == "":
        print(style.render(args[0]))
        return None

    if formatting.value()[] == "bold":
        style = style.bold()
    elif formatting.value()[] == "underline":
        style = style.underline()
    elif formatting.value()[] == "italic":
        style = style.italic()

    print(style.render(args[0]))
    return None


fn pre_hook(command: Arc[Command], args: List[String]) -> None:
    print("Pre-hook executed!")
    return None


fn post_hook(command: Arc[Command], args: List[String]) -> None:
    print("Post-hook executed!")
    return None


fn init() -> None:
    var root_command = Arc(
        Command(
            name="printer",
            description="Base command.",
            run=printer,
            pre_run=pre_hook,
            post_run=post_hook,
            arg_validator=exact_args[1](),
        )
    )

    root_command[].flags.add_string_flag(name="color", shorthand="c", usage="Text color", default="#3464eb")
    root_command[].flags.add_string_flag(name="formatting", shorthand="f", usage="Text formatting")

    root_command[].execute()


fn main() -> None:
    init()
