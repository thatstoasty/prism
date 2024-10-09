from memory import Arc
import testing
from prism.command import Command, Context
from prism.flag_set import FlagSet


def test_command_operations():
    fn dummy(ctx: Context) -> None:
        return None

    var cmd = Arc(Command(name="root", usage="Base command.", run=dummy))

    var flags = cmd[].flags.flags
    for flag in flags:
        testing.assert_equal(String("help"), flag[].name)

    var child_cmd = Arc(Command(name="child", usage="Child command.", run=dummy))
    cmd[].add_subcommand(child_cmd)
    child_cmd[].flags.string_flag(name="color", shorthand="c", usage="Text color", default="#3464eb")

    testing.assert_equal(child_cmd[].full_name(), "root child")

    # var help_test = MojoTest("Testing Command.help")
    # cmd.help()
