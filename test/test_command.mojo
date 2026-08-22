from prism import ArgSet
from std import testing
from std.memory import ArcPointer
from prism.command import Command, Flag, FlagSet, _unknown_command_error, _with_usage_hint
from std.testing import TestSuite

import prism


def test_command_operations() raises:
    def dummy(args: ArgSet, flags: FlagSet) -> None:
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
                flags=[Flag.new[UInt32](name="color", shorthand="c", usage="Text color", default=UInt32(0x3464EB))],
            )
        ],
    )
    for flag in cmd.flags:
        testing.assert_equal("help", flag.name)

    # testing.assert_equal(child_cmd[].full_name(), "root child")


def test_unicode_command_name() raises:
    def dummy(args: ArgSet, flags: FlagSet) -> None:
        return None

    var cmd = Command(
        name="ルート",
        usage="Base command with a unicode name.",
        run=dummy,
    )
    testing.assert_equal(cmd.name, "ルート")


def test_wire_parents_links_the_whole_tree() raises:
    # Regression: parents were linked as each command was constructed, but a child is built before
    # the parent it attaches to exists, so the chain stopped one level up. `full_name` and
    # `inherited_flags` were wrong for anything deeper than a direct child.
    def dummy(args: ArgSet, flags: FlagSet) -> None:
        return None

    var cmd = Command(
        name="app",
        usage="Base command.",
        run=dummy,
        flags=[Flag.new[String](name="region", usage="Region.", persistent=True)],
        children=[
            Command(
                name="deploy",
                usage="Deploy command.",
                run=dummy,
                children=[Command(name="rollback", usage="Rollback command.", run=dummy)],
            )
        ],
    )
    cmd._wire_parents()

    ref deploy = cmd.children[0][]
    ref rollback = deploy.children[0][]

    testing.assert_equal(cmd.full_name(), "app")
    testing.assert_equal(deploy.full_name(), "app deploy")
    testing.assert_equal(rollback.full_name(), "app deploy rollback")

    # A persistent flag on the root must reach a grandchild, not just a direct child.
    var inherited = rollback.inherited_flags()
    testing.assert_true(Bool(inherited.lookup("region")), "grandchild did not inherit `region`")


def test_unknown_command_error_message() raises:
    def dummy(args: ArgSet, flags: FlagSet) -> None:
        return None

    var cmd = Command(
        name="app",
        usage="Base command.",
        run=dummy,
        children=[Command(name="status", usage="Status command.", run=dummy, aliases=["st"])],
    )
    var message = String(_unknown_command_error(cmd, "sttaus"))

    testing.assert_true('Unknown command: "sttaus" for "app".' in message, message)
    # `suggest` defaults to False, so no correction is offered.
    testing.assert_false("Did you mean" in message, message)


def test_usage_hint_names_the_command() raises:
    def dummy(args: ArgSet, flags: FlagSet) -> None:
        return None

    var cmd = Command(name="app", usage="Base command.", run=dummy)
    var message = String(_with_usage_hint(cmd, Error("something went wrong")))

    testing.assert_true("something went wrong" in message, message)
    testing.assert_true("Run 'app --help' for usage." in message, message)


def test_unknown_command_error_suggests_when_enabled() raises:
    def dummy(args: ArgSet, flags: FlagSet) -> None:
        return None

    var cmd = Command(
        name="app",
        usage="Base command.",
        run=dummy,
        suggest=True,
        children=[Command(name="status", usage="Status command.", run=dummy, aliases=["deploy"])],
    )

    var message = String(_unknown_command_error(cmd, "sttaus"))
    testing.assert_true("Did you mean this?" in message, message)
    testing.assert_true("status" in message, message)

    # Aliases are matched during traversal, so they are suggestible too.
    var alias_message = String(_unknown_command_error(cmd, "deploi"))
    testing.assert_true("deploy" in alias_message, alias_message)


def test_hooks_are_optional_and_raising() raises:
    # Hooks are `Optional[CmdFn]`, so a hook function has to be declared `raises` even when it
    # never raises: a non-raising function reaches `CmdFn` in one implicit step but not the
    # Optional beyond it. `run` takes either form. This is a compile-time guarantee -- if the
    # accepted shapes change, this file stops building.
    def non_raising(args: ArgSet, flags: FlagSet) -> None:
        return None

    def raising(args: ArgSet, flags: FlagSet) raises -> None:
        return None

    var cmd = Command(
        name="app",
        usage="Base command.",
        run=non_raising,
        pre_run=raising,
        post_run=raising,
        persistent_pre_run=raising,
        persistent_post_run=raising,
    )
    testing.assert_true(Bool(cmd.pre_run), "pre_run should be set")
    testing.assert_true(Bool(cmd.persistent_post_run), "persistent_post_run should be set")

    # An unsupplied hook stays empty, which is what lets the executor tell it apart from one that
    # was supplied and does nothing.
    var bare = Command(name="bare", usage="Base command.", run=non_raising)
    testing.assert_false(Bool(bare.pre_run), "pre_run should be unset")
    testing.assert_false(Bool(bare.post_run), "post_run should be unset")
    testing.assert_false(Bool(bare.persistent_pre_run), "persistent_pre_run should be unset")
    testing.assert_false(Bool(bare.persistent_post_run), "persistent_post_run should be unset")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
