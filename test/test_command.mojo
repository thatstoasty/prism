from memory import ArcPointerPointer
import testing
from prism.command import Command, Context
from prism.flag_set import FlagSet


def test_command_operations():
    fn dummy(ctx: Context) -> None:
        return None

    cmd = Command(name="root", usage="Base command.", run=dummy)
    for flag in cmd.flags.flags:
        testing.assert_equal("help", flag[].name)

    child_cmd = ArcPointer(Command(name="child", usage="Child command.", run=dummy))
    cmd.add_subcommand(child_cmd)
    child_cmd[].flags.string_flag(name="color", shorthand="c", usage="Text color", default="#3464eb")

    testing.assert_equal(child_cmd[].full_name(), "root child")

    # help_test = MojoTest("Testing Command.help")
    # cmd.help()
