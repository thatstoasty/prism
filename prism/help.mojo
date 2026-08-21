"""Help rendering and the context handed to a help function."""

import mog
from std.memory import ArcPointer
from prism.command import Command
from prism._arg_set import ArgSet
from prism.arg import Arg
from prism.flag import Flag


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
    """The command's subcommands, as `(name, usage)` pairs."""
    var aliases: List[String]
    """Alternative names the command answers to."""


comptime HelpFn = def (HelpContext) raises thin -> String
"""The function to generate help output."""


def _sorted_by_name(var flags: List[Flag]) -> List[Flag]:
    """Sorts flags alphabetically by name.

    Args:
        flags: The flags to sort.

    Returns:
        The same flags in alphabetical order.
    """

    @parameter
    def by_name(a: Flag, b: Flag) -> Bool:
        return a.name < b.name

    sort[by_name](flags)
    return flags^


def _write_flag_section(
    name: StringSpan, flags: List[Flag], width: Int, style: mog.Style, mut builder: Some[Writer]
) -> None:
    """Writes one titled section of flags.

    Args:
        name: The section heading, such as `Options`.
        flags: The flags to list, already ordered.
        width: The column width to render the flag column at.
        style: The style to render the flag column with.
        builder: The writer to write the section to.
    """
    var flag_style = style.width(UInt16(width))
    builder.write("\n", name, ":")

    for flag in flags:
        # Keep the newline outside the styled span. A leading newline makes `render` pad an empty
        # first line to the column width, which trails whitespace onto the previous line.
        var option = String("  ")
        if flag.shorthand:
            option.write("-", flag.shorthand, ", ")
        option.write("--", flag.name)
        builder.write("\n", flag_style.render(option), flag.usage)

        # Trailing annotations: what happens if the flag is omitted, or that it cannot be.
        if flag.required:
            builder.write(" (required)")
        elif flag.default:
            builder.write(" (default: ", flag.default.value(), ")")

    builder.write("\n")


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

    var option_width = 0
    if cmd.flags:
        var widest_flag = 0
        var widest_shorthand = 0
        for flag in cmd.flags:
            # `count_graphemes` walks the string, so measure once per flag rather than again on
            # every comparison that happens to be a new maximum.
            var name_width = flag.name.count_graphemes()
            if name_width > widest_flag:
                widest_flag = name_width

            var shorthand_width = flag.shorthand.count_graphemes()
            if shorthand_width > widest_shorthand:
                widest_shorthand = shorthand_width

        comptime USAGE_PADDING = 4
        option_width = widest_flag + widest_shorthand + 5 + USAGE_PADDING

    if cmd.args:
        var arg_style = style.width(UInt16(option_width))
        builder.write("\nArguments:")
        for arg in cmd.args:
            var rendered = String("  ", arg.name.upper()) if arg.required else String(
                "  [", arg.name.upper(), "]"
            )
            builder.write("\n", arg_style.render(rendered), arg.usage)
            if arg.default:
                builder.write(" (default: ", arg.default.value(), ")")
        builder.write("\n")

    if local_flags:
        _write_flag_section("Options", _sorted_by_name(local_flags^), option_width, style, builder)

    if cmd.inherited_flags:
        _write_flag_section(
            "Global Options", _sorted_by_name(cmd.inherited_flags.copy()), option_width, style, builder
        )

    if cmd.children:
        var command_style = style.width(UInt16(option_width) - 2) if option_width > 0 else style
        var children = cmd.children.copy()

        @parameter
        def by_command_name(a: Tuple[String, String], b: Tuple[String, String]) -> Bool:
            return a[0] < b[0]

        sort[by_command_name](children)

        builder.write("\nCommands:")
        for i in range(len(children)):
            builder.write(t"\n  {command_style.render(children[i][0])}{children[i][1]}")
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
        var flag: Flag = Flag.bool(name="help", shorthand="h", usage="Displays help information about the command."),
        action: HelpFn = default_help,
    ):
        """Constructs a new `Help` configuration.

        Args:
            flag: The flag to use for the help command.
            action: The function to call when the help flag is passed.
        """
        self.flag = flag^
        self.action = action
