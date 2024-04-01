from collections.optional import Optional
from collections.dict import Dict, KeyElement
from .flag import (
    Flag,
    Flags,
    FlagSet,
    InputFlags,
    PositionalArgs,
    StringKey,
    get_args_and_flags
)
from .vector import join, to_string
from memory._arc import Arc


# alias CommandFunction = fn (args: PositionalArgs, flags: InputFlags) raises -> None
alias CommandFunction = fn(command: Arc[Command], args: PositionalArgs) raises -> None
alias CommandArc = Arc[Command]

# TODO: Add pre run, post run, and persistent flags
@value
struct Command(CollectionElement):
    var name: String
    var description: String
    var run: CommandFunction

    var args: PositionalArgs
    var flags: FlagSet

    var children: List[Arc[Self]]
    var parent: Arc[Optional[Self]]

    fn __init__(
        inout self, name: String, description: String, run: CommandFunction
    ) raises:
        self.name = name
        self.description = description
        self.run = run

        self.args = PositionalArgs()
        self.flags = Flags()
        self.flags.add_flag(
            Flag("help", "h", "Displays help information about the command.")
        )

        self.children = List[Arc[Self]]()
        self.parent = Arc[Optional[Command]](None)

    fn __copyinit__(inout self, existing: Self):
        self.name = existing.name
        self.description = existing.description
        self.run = existing.run

        self.args = existing.args
        self.flags = existing.flags
        self.children = existing.children
        self.parent = existing.parent

    fn __moveinit__(inout self, owned existing: Self):
        self.name = existing.name ^
        self.description = existing.description ^
        self.run = existing.run

        self.args = existing.args ^
        self.flags = existing.flags ^
        self.children = existing.children ^
        self.parent = existing.parent ^

    fn __str__(self) -> String:
        return "(Name: " + self.name + ", Description: " + self.description + ")"

    fn __repr__(self) -> String:
        var parent_name: String = ""
        if self.parent[]:
            parent_name = self.parent[].value().name
        return (
            "Name: "
            + self.name
            + "\nDescription: "
            + self.description
            + "\nArgs: "
            + to_string(self.args)
            + "\nFlags: "
            + str(self.flags)
            + "\nCommands: "
            + to_string(self.children)
            + "\nParent: "
            + parent_name
        )

    fn full_command(self) -> String:
        """Traverses up the parent command tree to build the full command as a string."""
        if self.parent[]:
            var ancestor: String = self.parent[].value().full_command()
            return ancestor + " " + self.name
        else:
            return self.name

    fn help(self) -> None:
        """Prints the help information for the command."""
        var child_commands: String = ""
        for child in self.children:
            child_commands = child_commands + "  " + child[][] + "\n"

        var flags: String = ""
        for command in self.flags.get_flags():
            flags = (
                flags
                + "  "
                + "-"
                + command[][].shorthand
                + ", "
                + "--"
                + command[][].name
                + "    "
                + command[][].usage
                + "\n"
            )

        # Build usage statement arguments depending on the command's children and flags.
        var usage_arguments: String = " [args]"
        if len(self.children) > 0:
            usage_arguments = " [command]" + usage_arguments
        if len(self.flags) > 0:
            usage_arguments = usage_arguments + " [flags]"

        var full_command = self.full_command()
        var help = self.description + "\n\n"
        var usage = "Usage:\n" + "  " + full_command + usage_arguments + "\n\n"
        var available_commands = "Available commands:\n" + child_commands + "\n"
        var available_flags = "Available flags:\n" + flags + "\n"
        var note = 'Use "' + full_command + ' [command] --help" for more information about a command.'
        help = help + usage + available_commands + available_flags + note
        print(help)

    fn validate_flag_set(self, flag_set: FlagSet) raises -> None:
        """Validates the flags passed to the command. Raises an error if an invalid flag is passed.

        Args:
            flag_set: The flags passed to the command.
        """
        var length_of_command_flags = len(self.flags)
        var length_of_input_flags = len(flag_set)

        if length_of_input_flags > length_of_command_flags:
            raise Error(
                "Specified more flags than the command accepts, please check your"
                " command's flags."
            )

        for flag in flag_set.flags:
            if flag[] not in self.flags:
                raise Error(String("Invalid flags passed to command: ") + flag[].name)

    fn execute(inout self) raises -> None:
        """Traverses the arguments passed to the executable and executes the last command in the branch.
        """
        # Traverse from the root command through the children to find a match for the current argument.
        # Any additional arguments past the last matched command name are considered arguments.
        # TODO: Tree traversal is new to me, there's probably a better way to do this.
        get_args_and_flags(self.args, self.flags)
        var command = self
        var children = command.children
        var leftover_args_start_index = 1  # Start at 1 to start slice at the first remaining arg, not the last child command.

        for arg in self.args:
            for command_ref in children:
                if command_ref[][].name == arg[]:
                    command = command_ref[][]
                    children = command.children
                    leftover_args_start_index += 1
                    break

        # If the there are more or equivalent args to the index, then there are remaining args to pass to the command.
        var remaining_args = List[String]()
        if len(self.args) >= leftover_args_start_index:
            remaining_args = self.args[leftover_args_start_index : len(self.args)]

        # Check if the help flag was passed
        for flag in self.flags.get_flags_with_values():
            if flag[][].name == "help":
                command.help()
                return None

        # Check if the flags are valid
        command.validate_flag_set(command.flags)
        command.run(Arc(self), remaining_args)

    fn add_flag(inout self, *, name: String, shorthand: String = "", usage: String = "") -> None:
        """Adds a flag to the command's flags.

        Args:
            name: The name of the flag.
            shorthand: The shorthand name of the flag.
            usage: The usage information for the flag.
        """
        self.flags.add_flag(Flag(name, shorthand, usage))
    
    fn get_all_flags(self) -> Arc[FlagSet]:
        """Returns all flags for the command and persistent flags from its parent.

        Returns:
            The flags for the command and its children.
        """
        return Arc(self.flags)

    fn set_parent(inout self, inout parent: Command) -> None:
        """Sets the command's parent attribute to the given parent.

        Args:
            parent: The name of the parent command.
        """
        self.parent[] = parent

    fn add_command(inout self, inout command: Command):
        """Adds child command and set's child's parent attribute to self.

        Args:
            command: The command to add as a child of self.
        """
        self.children.append(Arc(command))
        command.set_parent(self)

