from memory import ArcPointer
import testing
from prism.command import Command, FlagSet, Flag
import prism


def test_command_operations():
    fn dummy(args: List[String], flags: FlagSet) -> None:
        return None

    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        children=[
            Command(
                name="child",
                usage="Child command.",
                run=dummy,
                flags=[Flag.uint32(name="color", shorthand="c", usage="Text color", default=UInt32(0x3464EB))],
            )
        ],
    )
    for flag in cmd.flags:
        testing.assert_equal("help", flag.name)

    # testing.assert_equal(child_cmd[].full_name(), "root child")
