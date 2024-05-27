from prism import FlagSet, Command
import prism
from external.mist import TerminalStyle


fn printer(flags: FlagSet, args: List[String]) -> None:
    if len(args) <= 0:
        print("No text to print! Pass in some text as a positional argument.")
        return None

    var color = flags.get_as_string("color")
    var formatting = flags.get_as_string("formatting")
    var style = TerminalStyle()

    if not color:
        color = String("")
    if not formatting:
        formatting = String("")

    if color.value()[] != "":
        style = style.foreground(style.profile.color(color.value()[]))
    if formatting.value()[] == "bold":
        style = style.bold()
    elif formatting.value()[] == "underline":
        style = style.underline()
    elif formatting.value()[] == "italic":
        style = style.italic()

    print(style.render(args[0]))


fn pre_hook(flags: FlagSet, args: List[String]) -> None:
    print("Pre-hook executed!")


fn post_hook(flags: FlagSet, args: List[String]) -> None:
    print("Post-hook executed!")


fn init() -> None:
    var root_command = Command(
        name="printer",
        description="Base command.",
        run=printer,
        pre_run=pre_hook,
        post_run=post_hook,
        arg_validator=prism.exact_args[1](),
    )

    root_command.add_string_flag(name="color", shorthand="c", usage="Text color", default="#3464eb")
    root_command.add_string_flag(name="formatting", shorthand="f", usage="Text formatting")

    root_command.execute()


fn main() -> None:
    init()
