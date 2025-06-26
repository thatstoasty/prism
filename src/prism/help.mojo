from memory import OwnedPointer
from prism.flag import Flag
from prism.command import Command
import mog


alias HelpFn = fn (OwnedPointer[Command]) raises -> String
"""The function to generate help output."""


fn default_help(cmd: OwnedPointer[Command]) raises -> String:
    """Prints the help information for the command.

    Args:
        cmd: The command to generate help information for.

    Returns:
        The help information for the command.

    Raises:
        Any error that occurs while generating the help information.
    """
    alias style = mog.Style(mog.ASCII_PROFILE)
    var builder = String("Usage: ", cmd[].full_name())

    if len(cmd[].flags) > 0:
        builder.write(" [OPTIONS]")
    if len(cmd[].children) > 0:
        builder.write(" COMMAND")
    builder.write(" [ARGS]...", "\n\n", cmd[].usage, "\n")

    if cmd[].args_usage:
        builder.write("\nArguments:\n  ", cmd[].args_usage.value(), "\n")

    var option_width = 0
    if cmd[].flags:
        var widest_flag = 0
        var widest_shorthand = 0
        for flag in cmd[].flags:
            if len(flag.name) > widest_flag:
                widest_flag = len(flag.name)
            if len(flag.shorthand) > widest_shorthand:
                widest_shorthand = len(flag.shorthand)

        alias USAGE_PADDING = 4
        option_width = widest_flag + widest_shorthand + 5 + USAGE_PADDING
        var options_style = style.width(option_width)

        builder.write("\nOptions:")
        for flag in cmd[].flags:
            var option = String("\n  ")
            if flag.shorthand:
                option.write("-", flag.shorthand, ", ")
            option.write("--", flag.name)
            builder.write(options_style.render(option), flag.usage)

        builder.write("\n")

    if cmd[].children:
        var options_style = style.width(option_width - 2)
        builder.write("\nCommands:")
        for i in range(len(cmd[].children)):
            builder.write("\n  ", options_style.render(cmd[].children[i][].name), cmd[].children[i][].usage)
        builder.write("\n")

    if cmd[].aliases:
        builder.write("\nAliases:\n  ")
        for i in range(len(cmd[].aliases)):
            builder.write(cmd[].aliases[i])

            if i < len(cmd[].aliases) - 1:
                builder.write(", ")
        builder.write("\n")

    return builder^


struct Help(Copyable, ExplicitlyCopyable, Movable):
    """A struct representing the help information for a command."""

    var flag: Flag
    """The flag to use for the help command."""
    var action: HelpFn
    """The function to call when the help flag is passed."""

    fn __init__(
        out self,
        *,
        flag: Flag = Flag.bool(name="help", shorthand="h", usage="Displays help information about the command."),
        action: HelpFn = default_help,
    ):
        """Constructs a new `Help` configuration.

        Args:
            flag: The flag to use for the help command.
            action: The function to call when the help flag is passed.
        """
        self.flag = flag
        self.action = action

    fn __copyinit__(out self, existing: Self):
        """Initializes a new `Help` instance by copying from another.

        Args:
            existing: The `Help` instance to copy from.
        """
        return Help(flag=existing.flag.copy(), action=existing.action)

    fn __moveinit__(out self, owned other: Self):
        """Initializes a new `Help` instance by moving from another.

        Args:
            other: The `Help` instance to move from.
        """
        self.flag = other.flag^
        self.action = other.action

    fn copy(self) -> Self:
        """Returns a copy of the `Help` instance.

        Returns:
            A new `Help` instance with the same flag and action.
        """
        return Help(flag=self.flag.copy(), action=self.action)
