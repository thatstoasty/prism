from memory import Arc
import testing
from prism.command import Command, CommandArc
from prism.flag_set import FlagSet


def test_command_operations():
    fn dummy(command: CommandArc, args: List[String]) -> None:
        return None

    var cmd = Arc(Command(name="root", description="Base command.", run=dummy))

    var flags = cmd[].flags.flags
    for flag in flags:
        testing.assert_equal(String("help"), flag[].name)

    var child_cmd = Arc(Command(name="child", description="Child command.", run=dummy))
    cmd[].add_command(child_cmd)
    child_cmd[].flags.add_string_flag(name="color", shorthand="c", usage="Text color", default="#3464eb")

    testing.assert_equal(child_cmd[]._full_command(), "root child")

    # var help_test = MojoTest("Testing Command.help")
    # cmd.help()
