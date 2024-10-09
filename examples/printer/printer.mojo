from memory import Arc
from prism import Command, Context, exact_args
from mist import Style


fn printer(ctx: Context) -> None:
    if len(ctx.args) <= 0:
        print("No text to print! Pass in some text as a positional argument.")
        return None

    var color = ctx.command[].flags.get_as_uint32("color")
    var formatting = ctx.command[].flags.get_as_string("formatting")
    var style = Style()

    if not color:
        color = 0xFFFFFF
    if not formatting:
        formatting = String("")

    if color:
        style = style.foreground(color.value())

    var formatting_value = formatting.or_else("")
    if formatting_value == "":
        print(style.render(ctx.args[0]))
        return None

    if formatting.value() == "bold":
        style = style.bold()
    elif formatting.value() == "underline":
        style = style.underline()
    elif formatting.value() == "italic":
        style = style.italic()

    print(style.render(ctx.args[0]))
    return None


fn pre_hook(ctx: Context) -> None:
    print("Pre-hook executed!")
    return None


fn post_hook(ctx: Context) -> None:
    print("Post-hook executed!")
    return None


fn main() -> None:
    var root = Command(
        name="printer",
        description="Base command.",
        run=printer,
        pre_run=pre_hook,
        post_run=post_hook,
    )
    root.arg_validator = exact_args[1]()

    root.flags.add_uint32_flag(name="color", shorthand="c", usage="Text color", default=0x3464EB)
    root.flags.add_string_flag(name="formatting", shorthand="f", usage="Text formatting")

    root.execute()
