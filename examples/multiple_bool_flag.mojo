from memory import ArcPointer
from prism import Command, Context, Flag
import prism


fn test(ctx: Context) raises -> None:
    var required = ctx.command[].flags.get_bool("required")
    var automation = ctx.command[].flags.get_bool("automation")
    var secure = ctx.command[].flags.get_bool("secure")
    var verbose = ctx.command[].flags.get_bool("verbose")

    if required:
        print("Required flag is set!")
    if automation:
        print("Automation flag is set!")
    if secure:
        print("Secure flag is set!")
    if verbose:
        print("Verbose flag is set!")

    if len(ctx.args) > 0:
        print("Arguments:", ctx.args.__str__())

fn main() -> None:
    alias cmd = Command(
        name="my",
        usage="This is a dummy command!",
        raising_run=test,
        flags=List[Flag](
            Flag.bool(
                name="required",
                shorthand="r0",
                usage="Always required.",
                required=True,
            ),
            Flag.bool(
                name="automation",
                shorthand="a",
                usage="In automation?",
            ),
            Flag.bool(
                name="secure",
                shorthand="s",
                usage="Use SSL?",
            ),
            Flag.bool(
                name="verbose",
                shorthand="vv",
                usage="Verbose output.",
            ),
        ),
    )
    cmd.execute()
