"""Help rendering and the context handed to a help function."""

import mog
from std.memory import ArcPointer
from prism.command import Command
from prism._arg_set import ArgSet
from prism.arg import Arg
from prism.flag import Flag
from prism.opt_type import OptType
from prism.value import LIST_SEPARATOR


@fieldwise_init
struct HelpContext:
    """Everything a help function needs to render help for one command."""

    var full_name: String
    """The command's full name, including its ancestors."""
    var usage: String
    """Description of what the command does."""
    var args: List[Arg]
    """The positional arguments the command declares, if it declares any."""
    var flags: List[Flag]
    """The flags the command accepts, including those inherited from its ancestors."""
    var inherited_flags: List[Flag]
    """The subset of `flags` that came from an ancestor rather than the command itself."""
    var children: List[Tuple[String, String]]
    """The command's subcommands, as `(name, usage)` pairs. The name includes any aliases, as `deploy, d`."""
    var aliases: List[String]
    """Alternative names the command answers to."""


comptime HelpFn = def (HelpContext) raises thin -> String
"""The function to generate help output."""


def _render_default(default: String, type: OptType) -> String:
    """Renders a default for help output, showing a list's elements separated by spaces.

    Args:
        default: The raw default value.
        type: The type of the flag or argument the default belongs to.

    Returns:
        The default as it should be displayed.
    """
    if type.takes_multiple_values():
        return default.replace(LIST_SEPARATOR, " ")
    return default


def _sorted_by_name(var flags: List[Flag]) -> List[Flag]:
    """Sorts flags alphabetically by name.

    Args:
        flags: The flags to sort.

    Returns:
        The same flags in alphabetical order.
    """
    def by_name(a: Flag, b: Flag) -> Bool:
        return a.name < b.name

    sort(flags, by_name)
    return flags^


def _scalar_hint(type: OptType) -> String:
    """Names the kind of value a single flag value holds, for help output.

    Args:
        type: The type of the value.

    Returns:
        A placeholder such as `<int>`.
    """
    if type == OptType.String:
        return "<string>"
    if type == OptType.Bool:
        return "<bool>"
    if type in [OptType.UInt, OptType.UInt8, OptType.UInt16, OptType.UInt32, OptType.UInt64]:
        return "<uint>"
    if type.is_int_type():
        return "<int>"
    if type.is_float_type():
        return "<float>"
    return "<value>"


def _value_hint(type: OptType) -> String:
    """Names the value a flag takes, for help output, so value flags stand apart from switches.

    Args:
        type: The type of the flag.

    Returns:
        A placeholder such as `<int>`, `<string>...` for a repeatable list flag, or an empty string
        for a bool flag, which takes no value.
    """
    if type == OptType.Bool:
        return ""
    if type.takes_multiple_values():
        return String(_scalar_hint(type.element()), "...")
    return _scalar_hint(type)


def _flag_column(flag: Flag, align_long_names: Bool) -> String:
    """Renders a flag's entry in the left column of help output, such as `-p, --port <int>`.

    Args:
        flag: The flag to render.
        align_long_names: Whether to indent a flag without a shorthand so its long name lines up
            with those that have one.

    Returns:
        The rendered entry, indented.
    """
    var option = String("  ")
    if flag.shorthand:
        option.write("-", flag.shorthand, ", ")
    elif align_long_names:
        option.write("    ")
    option.write("--", flag.name)

    var hint = _value_hint(flag.type)
    if hint:
        option.write(" ", hint)
    return option^


def _write_flag_section(
    name: StringSpan,
    flags: List[Flag],
    align_long_names: Bool,
    column: mog.Style,
    mut builder: Some[Writer],
) -> None:
    """Writes one titled section of flags.

    Args:
        name: The section heading, such as `Options`.
        flags: The flags to list, already ordered.
        align_long_names: Whether to line up long names under those with a shorthand.
        column: The style that pads the left column to its width.
        builder: The writer to write the section to.
    """
    builder.write("\n", name, ":")

    for flag in flags:
        # Keep the newline outside the styled span. A leading newline makes `render` pad an empty
        # first line to the column width, which trails whitespace onto the previous line.
        builder.write("\n", column.render(_flag_column(flag, align_long_names)), flag.usage)

        # Trailing annotations: how many values an array flag takes, then what happens if the flag
        # is omitted, or that it cannot be.
        if flag.type.is_array_type():
            builder.write(" (", flag.type.array_length(), " values)")
        if flag.required:
            builder.write(" (required)")
        elif flag.default:
            builder.write(" (default: ", _render_default(flag.default.value(), flag.type), ")")
        if flag.environment_variable:
            builder.write(" [env: ", flag.environment_variable.value(), "]")

    builder.write("\n")


def _arg_column(arg: Arg, is_last: Bool) -> String:
    """Renders an argument's entry in the left column of help output, such as `[TARGET]`.

    Args:
        arg: The argument to render.
        is_last: Whether it is the last declared argument, which a list argument makes variadic.

    Returns:
        The rendered entry, indented.
    """
    var name = arg.name.upper()
    var rendered = String("  ", name) if arg.required else String("  [", name, "]")
    if is_last and arg.type.is_list_type():
        rendered.write("...")
    return rendered^


def default_help(cmd: HelpContext) raises -> String:
    """Prints the help information for the command.

    Args:
        cmd: The command to generate help information for.

    Returns:
        The help information for the command.

    Raises:
        Any error that occurs while generating the help information.
    """
    comptime style = mog.Style(mog.Profile.ASCII)
    comptime COLUMN_GAP = 4

    # Split the command's own flags from the ones it inherits, so the reader can tell which are
    # specific to this command and which apply across the tree.
    var local_flags = List[Flag]()
    for flag in cmd.flags:
        var inherited = False
        for parent_flag in cmd.inherited_flags:
            if parent_flag.name == flag.name:
                inherited = True
                break
        if not inherited:
            local_flags.append(flag.copy())

    var builder = String(t"Usage: {cmd.full_name}")
    if len(cmd.flags) > 0:
        builder.write(" [OPTIONS]")
    if len(cmd.children) > 0:
        builder.write(" COMMAND")

    # Name the arguments when the command declares or documents them. A command with subcommands
    # dispatches rather than taking arguments of its own, so it gets no placeholder at all.
    if cmd.args:
        builder.write(" ", ArgSet(cmd.args.copy()).usage())
    elif not cmd.children:
        builder.write(" [ARGS]...")

    builder.write(t"\n\n{cmd.usage}\n")

    # Size one left column to fit every entry in every section, arguments, flags and commands
    # alike, so no entry wraps and the descriptions line up down the whole page. Sizing it from the
    # flags alone wrapped any subcommand name longer than the widest flag.
    var align_long_names = False
    for flag in cmd.flags:
        if flag.shorthand:
            align_long_names = True
            break

    var widest = 0
    for flag in cmd.flags:
        widest = max(widest, _flag_column(flag, align_long_names).count_graphemes())
    for i in range(len(cmd.args)):
        widest = max(widest, _arg_column(cmd.args[i], i == len(cmd.args) - 1).count_graphemes())
    for child in cmd.children:
        widest = max(widest, child[0].count_graphemes() + 2)
    var column = style.width(UInt16(widest + COLUMN_GAP))

    if cmd.args:
        builder.write("\nArguments:")
        for i in range(len(cmd.args)):
            ref arg = cmd.args[i]
            builder.write("\n", column.render(_arg_column(arg, i == len(cmd.args) - 1)), arg.usage)
            if arg.default:
                builder.write(" (default: ", _render_default(arg.default.value(), arg.type), ")")
        builder.write("\n")

    if local_flags:
        _write_flag_section("Options", _sorted_by_name(local_flags^), align_long_names, column, builder)

    if cmd.inherited_flags:
        _write_flag_section(
            "Global Options", _sorted_by_name(cmd.inherited_flags.copy()), align_long_names, column, builder
        )

    if cmd.children:
        var children = cmd.children.copy()

        def by_command_name(a: Tuple[String, String], b: Tuple[String, String]) -> Bool:
            return a[0] < b[0]

        sort(children, by_command_name)

        builder.write("\nCommands:")
        for i in range(len(children)):
            builder.write("\n", column.render(String("  ", children[i][0])), children[i][1])
        builder.write("\n")

    if cmd.aliases:
        builder.write("\nAliases:\n  ")
        for i in range(len(cmd.aliases)):
            builder.write(cmd.aliases[i])

            if i < len(cmd.aliases) - 1:
                builder.write(", ")
        builder.write("\n")

    return builder^


struct Help(Copyable):
    """A struct representing the help information for a command."""

    var flag: Flag
    """The flag to use for the help command."""
    var action: HelpFn
    """The function to call when the help flag is passed."""

    def __init__(
        out self,
        *,
        var flag: Flag = Flag.new[Bool](name="help", shorthand="h", usage="Displays help information about the command."),
        action: HelpFn = default_help,
    ):
        """Constructs a new `Help` configuration.

        Args:
            flag: The flag to use for the help command.
            action: The function to call when the help flag is passed.
        """
        self.flag = flag^
        self.action = action
