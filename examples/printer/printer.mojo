from memory import Arc
from prism import Command, CommandArc, exact_args
from mist import Style


fn printer(inout command: Arc[Command], args: List[String]) -> None:
    var cmd = command
    if len(args) <= 0:
        print("No text to print! Pass in some text as a positional argument.")
        return None

    var color = command[].flags.get_as_uint32("color")
    var formatting = command[].flags.get_as_string("formatting")
    var style = Style()

    if not color:
        color = 0xFFFFFF
    if not formatting:
        formatting = String("")

    if color:
        style = style.foreground(color.value())

    var formatting_value = formatting.or_else("")
    if formatting_value == "":
        print(style.render(args[0]))
        return None

    if formatting.value() == "bold":
        style = style.bold()
    elif formatting.value() == "underline":
        style = style.underline()
    elif formatting.value() == "italic":
        style = style.italic()

    print(style.render(args[0]))
    return None


fn pre_hook(inout command: Arc[Command], args: List[String]) -> None:
    print("Pre-hook executed!")
    return None


fn post_hook(inout command: Arc[Command], args: List[String]) -> None:
    print("Post-hook executed!")
    return None


fn main() -> None:
    var root = Arc(
        Command(
            name="printer",
            description="Base command.",
            run=printer,
            pre_run=pre_hook,
            post_run=post_hook,
            arg_validator=exact_args[1](),
        )
    )

    root[].flags.add_uint32_flag(name="color", shorthand="c", usage="Text color", default=0x3464EB)
    root[].flags.add_string_flag(name="formatting", shorthand="f", usage="Text formatting")

    root[].execute()
