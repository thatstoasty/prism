from tests.wrapper import MojoTest
from prism.command import Command, CommandArc
from prism.flag import FlagSet


fn test_command_operations():
    var test = MojoTest("Testing Command.new")

    fn dummy(command: CommandArc, args: List[String]) -> None:
        return None

    var cmd = Command(name="root", description="Base command.", run=dummy)

    var get_all_flags_test = MojoTest("Testing Command.get_all_flags")
    var flags = cmd.flag_list()
    for flag in flags:
        get_all_flags_test.assert_equal("help", flag[][].name)

    var add_command_test = MojoTest("Testing Command.add_command")
    var child_cmd = Command(name="child", description="Child command.", run=dummy)
    cmd.add_command(child_cmd)
    child_cmd.add_string_flag(name="color", shorthand="c", usage="Text color", default="#3464eb")

    var full_command_test = MojoTest("Testing Command._full_command")
    full_command_test.assert_equal(child_cmd._full_command(), "root child")

    # var help_test = MojoTest("Testing Command.help")
    # cmd.help()


fn main():
    test_command_operations()
