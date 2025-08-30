alias VersionFn = fn (String) -> String
"""The function to call when the version flag is passed."""


fn default_version_writer(version: String) -> String:
    """Writes the version information for the CLI.

    Args:
        version: The version of the command.

    Returns:
        The version information for the command.
    """
    return version.copy()


struct Version(Copyable, ExplicitlyCopyable, Movable):
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

    fn copy(self) -> Self:
        """Returns a copy of the `Version` instance.

        Returns:
            A new `Version` instance with the same value, flag, and action.
        """
        return Version(self.value.copy(), flag=self.flag.copy(), action=self.action)
