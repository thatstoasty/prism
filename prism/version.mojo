"""Version reporting for a command."""

from prism.flag import Flag

comptime VersionFn = def (String, String) thin -> String
"""The function to call when the version flag is passed. Receives the command name and version."""


def default_version_writer(name: String, version: String) -> String:
    """Writes the version information for the CLI.

    Args:
        name: The full name of the command.
        version: The version of the command.

    Returns:
        The version information for the command.
    """
    return String(name, " version ", version)


struct Version(Copyable):
    """A struct representing the version of a command."""

    var value: String
    """The version of the command."""
    var flag: Flag
    """The flag to use for the version command."""
    var action: VersionFn
    """The function to call when the version flag is passed."""

    def __init__(
        out self,
        version: String,
        *,
        var flag: Flag = Flag.new[Bool](name="version", shorthand="v", usage="Displays the version of the command."),
        action: VersionFn = default_version_writer,
    ):
        """Constructs a new `Version` configuration.

        Args:
            version: The version of the command.
            flag: The flag to use for the version command.
            action: The function to call when the version flag is passed.
        """
        self.value = version
        self.flag = flag^
        self.action = action
