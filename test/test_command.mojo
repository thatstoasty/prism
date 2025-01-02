from memory import ArcPointer
import testing
from prism.command import Command, Context, Flag
import prism


def test_command_operations():
    fn dummy(ctx: Context) -> None:
        return None

    cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        children=List[ArcPointer[Command]](
            ArcPointer(Command(name="child", usage="Child command.", run=dummy, flags=List[Flag](prism.uint32_flag(name="color", shorthand="c", usage="Text color", default=0x3464eb))))
        )
    )
    for flag in cmd.flags:
        testing.assert_equal("help", flag[].name)

    # testing.assert_equal(child_cmd[].full_name(), "root child")
