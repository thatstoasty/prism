from prism import ArgSet
from std import testing
from std.memory import ArcPointer
from prism.command import Command, Flag, FlagSet, HelpContext, _command_column, _duplicate_flag_problem, _reserved_flag_problem, _parse_command_from_args, _unknown_command_error, _with_usage_hint
from std.testing import TestSuite
from prism.help import default_help

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
                flags=[Flag.new[UInt32](name="color", shorthand="c", usage="Text color", default=Optional[UInt32](UInt32(0x3464EB)))],
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
        suggest=False,
    )
    var message = String(_unknown_command_error(cmd, "sttaus"))

    testing.assert_true('Unknown command: "sttaus" for "app".' in message, message)
    # With `suggest=False`, no correction is offered.
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


def test_execute_leaves_the_callers_tree_untouched() raises:
    # Regression: `execute` copied the root but shared its children, so parsing merged inherited
    # flags into the caller's subcommand and left values on it. A second `execute` saw the first
    # run's values, and every run added another copy of the inherited flags.
    def dummy(args: ArgSet, flags: FlagSet) raises -> None:
        return None

    var cli = Command(
        name="app",
        usage="Base command.",
        run=dummy,
        flags=[Flag.new[Bool](name="verbose", usage="Verbose.", persistent=True)],
        children=[
            Command(
                name="child",
                usage="Child command.",
                run=dummy,
                flags=[Flag.new[List[String]](name="tags", usage="Tags.")],
            )
        ],
    )
    var flag_count = len(cli.children[0][].flags)

    cli.execute(["child", "--tags", "a", "--verbose"])
    cli.execute(["child", "--tags", "b"])

    ref child = cli.children[0][]
    testing.assert_equal(len(child.flags), flag_count)
    testing.assert_false(Bool(child.flags.lookup("tags").value()[].value))
    testing.assert_false(child.has_parent())


def test_builtin_flag_yields_its_shorthand() raises:
    # Regression: `Version` added `-v` after the command's own `--verbose -v`, and the first match
    # won, so the version shorthand was silently unreachable. The command's flag now keeps it.
    def dummy(args: ArgSet, flags: FlagSet) raises -> None:
        return None

    var cmd = Command(
        name="app",
        usage="Base command.",
        run=dummy,
        version=prism.Version("1.0"),
        flags=[Flag.new[Bool](name="verbose", shorthand="v", usage="Verbose.")],
    )
    testing.assert_equal(cmd.flags.lookup_shorthand("v").value()[].name, "verbose")
    testing.assert_equal(cmd.flags.lookup("version").value()[].shorthand, "")


def test_dash_is_positional_during_subcommand_traversal() raises:
    # `app - child` must not skip over `-` as a flag and dispatch to `child`.
    def dummy(args: ArgSet, flags: FlagSet) raises -> None:
        return None

    var cmd = ArcPointer(
        Command(
            name="app",
            usage="Base command.",
            run=dummy,
            children=[Command(name="child", usage="Child command.", run=dummy)],
        )
    )
    var args: List[String] = ["-", "child"]
    # Only the root is on the path: nothing matched.
    testing.assert_equal(len(_parse_command_from_args(cmd, args)), 1)


def _help_for(cmd: Command) raises -> String:
    return default_help(
        HelpContext(
            full_name=cmd.full_name(),
            usage=cmd.usage,
            args=cmd.args.copy(),
            flags=cmd.flags.flags.copy(),
            inherited_flags=[],
            children=[(_command_column(child[]), child[].usage) for child in cmd.children],
            aliases=cmd.aliases.copy(),
        )
    )


def test_help_shows_value_hints_and_environment_variables() raises:
    def dummy(args: ArgSet, flags: FlagSet) raises -> None:
        return None

    var cmd = Command(
        name="app",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.new[Int](name="port", shorthand="p", usage="Port."),
            Flag.new[List[String]](name="tag", usage="Tags."),
            Flag.new[String](name="token", usage="Token.", environment_variable=String("APP_TOKEN")),
        ],
    )
    var help = _help_for(cmd)
    testing.assert_true("-p, --port <int>" in help, help)
    testing.assert_true("    --tag <string>..." in help, help)
    testing.assert_true("[env: APP_TOKEN]" in help, help)


def test_help_fits_long_subcommand_names() raises:
    # Regression: the command column was sized from the flags, so a longer subcommand name wrapped
    # onto a second line and ran into its description.
    def dummy(args: ArgSet, flags: FlagSet) raises -> None:
        return None

    var cmd = Command(
        name="app",
        usage="Base command.",
        run=dummy,
        children=[Command(name="a-very-long-subcommand-name", usage="Long.", run=dummy, aliases=["l"])],
    )
    var help = _help_for(cmd)
    testing.assert_true("  a-very-long-subcommand-name, l    Long." in help, help)


def test_duplicate_flag_names_are_reported() raises:
    var flags = FlagSet([Flag.new[Bool](name="verbose", usage="V."), Flag.new[String](name="verbose", usage="V.")])
    testing.assert_equal(_duplicate_flag_problem(flags).value(), "The flag `--verbose` is defined more than once.")


def test_duplicate_shorthands_are_reported() raises:
    var flags = FlagSet(
        [Flag.new[Bool](name="verbose", shorthand="v", usage="V."), Flag.new[String](name="value", shorthand="v", usage="V.")]
    )
    testing.assert_equal(
        _duplicate_flag_problem(flags).value(), "The shorthand `-v` is given to both `--verbose` and `--value`."
    )


def test_distinct_flags_have_no_problem() raises:
    var flags = FlagSet(
        [Flag.new[Bool](name="verbose", shorthand="v", usage="V."), Flag.new[String](name="value", shorthand="x", usage="V.")]
    )
    testing.assert_false(Bool(_duplicate_flag_problem(flags)))


def test_reserved_flag_names_are_reported() raises:
    var flags = FlagSet([Flag.new[String](name="help", usage="Mine.")])
    var builtin = Flag.new[Bool](name="help", shorthand="h", usage="Help.")
    testing.assert_true("`--help` is defined, but that name is reserved" in _reserved_flag_problem(flags, builtin).value())

    var free = FlagSet([Flag.new[Bool](name="hello", shorthand="h", usage="Mine.")])
    testing.assert_false(Bool(_reserved_flag_problem(free, builtin)), "a clashing shorthand is not a problem")


def test_help_shows_array_flags() raises:
    def dummy(args: ArgSet, flags: FlagSet) raises -> None:
        return None

    var default: Array[Int, 2] = [800, 600]
    var cmd = Command(
        name="app",
        usage="Base command.",
        run=dummy,
        flags=[Flag.new[Array[Int, 2]](name="size", shorthand="s", usage="Window size.", default=default^)],
    )
    var help = _help_for(cmd)
    testing.assert_true("-s, --size <int>...    Window size. (2 values) (default: 800 600)" in help, help)

def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
