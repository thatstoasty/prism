from memory import ArcPointer
from prism import Command, Context, exact_args, Flag
import prism
import mist


fn printer(ctx: Context) raises -> None:
    if len(ctx.args) <= 0:
        print("No text to print! Pass in some text as a positional argument.")
        return None

    var color = ctx.command[].flags.get_uint32("color")
    var formatting = ctx.command[].flags.get_string("formatting")
    var style = mist.Style().foreground(color.value())

    if not formatting:
        print(style.render(ctx.args[0]))
        return None

    var format = formatting.value()
    if format == "bold":
        style = style.bold()
    elif format == "underline":
        style = style.underline()
    elif format == "italic":
        style = style.italic()

    print(style.render(ctx.args[0]))


fn pre_hook(ctx: Context) -> None:
    print("Pre-hook executed!")


fn post_hook(ctx: Context) -> None:
    print("Post-hook executed!")


fn main() -> None:
    Command(
        name="printer",
        usage="Base command.",
        raising_run=printer,
        pre_run=pre_hook,
        post_run=post_hook,
        arg_validator=exact_args[1](),
        flags=List[Flag](
            Flag.uint32(name="color", shorthand="c", usage="Text color", default=UInt32(0x3464EB)),
            Flag.string(name="formatting", shorthand="f", usage="Text formatting"),
        ),
    ).execute()
