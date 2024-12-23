from memory import ArcPointer
from prism import Command, Context, exact_args
import mist


fn printer(ctx: Context) raises -> None:
    if len(ctx.args) <= 0:
        print("No text to print! Pass in some text as a positional argument.")
        return None

    var color = ctx.command[].flags.get_uint32("color")
    var formatting = ctx.command[].flags.get_string("formatting")
    var style = mist.Style().foreground(color)

    if formatting == "":
        print(style.render(ctx.args[0]))
        return None

    if formatting == "bold":
        style = style.bold()
    elif formatting == "underline":
        style = style.underline()
    elif formatting == "italic":
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
        usage="Base command.",
        raising_run=printer,
        pre_run=pre_hook,
        post_run=post_hook,
    )
    root.arg_validator = exact_args[1]()

    root.flags.uint32_flag(name="color", shorthand="c", usage="Text color", default=0x3464EB)
    root.flags.string_flag(name="formatting", shorthand="f", usage="Text formatting")

    root.execute()
