from memory import ArcPointer
from prism.command import Command


struct Context:
    """The context of the command being executed, a pointer to the command and the args to use."""

    var command: ArcPointer[Command]
    """The command being executed."""
    var args: List[String]
    """The arguments passed to the command."""

    def __init__(out self, args: List[String], command: ArcPointer[Command]):
        """Initializes a new Context.

        Args:
            args: The arguments passed to the command.
            command: The command being executed.
        """
        self.command = command
        self.args = args
