from prism.context import Context


alias VersionFn = fn (Context) -> String
"""The function to call when the version flag is passed."""


fn default_version_writer(ctx: Context) -> String:
    """Writes the version information for the command.

    Args:
        ctx: The context of the command to generate version information for.

    Returns:
        The version information for the command.
    """
    return String(ctx.command[].name, ": ", ctx.command[].version.value().value)


@value
struct Version(CollectionElement):
    """A struct representing the version of a command."""

    var value: String
    """The version of the command."""
    var flag: Flag
    """The flag to use for the version command."""
    var action: VersionFn
    """The function to call when the version flag is passed."""

    fn __init__(
        out self,
        version: String,
        *,
        flag: Flag = Flag.bool(name="version", shorthand="v", usage="Displays the version of the command."),
        action: VersionFn = default_version_writer,
    ):
        """Constructs a new `Version` configuration.

        Args:
            version: The version of the command.
            flag: The flag to use for the version command.
            action: The function to call when the version flag is passed.
        """
        self.value = version
        self.flag = flag
        self.action = action
