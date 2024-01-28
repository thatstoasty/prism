from collections.optional import Optional
from prism.flag import (
    Flag,
    Flags,
    InputFlags,
    PositionalArgs,
    get_args_and_flags,
    contains_flag,
)

from prism.stdlib.builtins import dict, StringKey
from prism.stdlib.builtins.vector import contains, to_string

alias CommandFunction = fn (args: PositionalArgs, flags: InputFlags) raises -> None
# alias CommandFunction = fn (command: Command, args: PositionalArgs) raises -> None


# TODO: Add pre run, post run, and persistent flags
@value
struct Command(CollectionElement):
    var name: String
    var description: String
    var run: CommandFunction

    var args: PositionalArgs
    var flags: Flags
    var input_flags: InputFlags

    var commands: DynamicVector[Self]
    var parent: Optional[Self]

    fn __init__(
        inout self, name: String, description: String, run: CommandFunction
    ) raises:
        pass
        self.name = name
        self.description = description
        self.run = run

        self.args = PositionalArgs()
        self.flags = Flags()
        self.flags.append(
            Flag("help", "h", "Displays help information about the command.")
        )
        self.input_flags = InputFlags()
        get_args_and_flags(self.args, self.input_flags)

        self.commands = DynamicVector[Self]()
        self.parent = None

    fn __copyinit__(inout self, existing: Self):
        self.name = existing.name
        self.description = existing.description
        self.run = existing.run

        self.args = existing.args
        self.flags = existing.flags
        self.input_flags = existing.input_flags
        self.commands = existing.commands
        self.parent = existing.parent

    fn __moveinit__(inout self, owned existing: Self):
        self.name = existing.name
        self.description = existing.description
        self.run = existing.run

        self.args = existing.args
        self.flags = existing.flags
        self.input_flags = existing.input_flags
        self.commands = existing.commands ^
        self.parent = existing.parent

    fn __str__(self) -> String:
        return "(Name: " + self.name + ", Description: " + self.description + ")"

    fn __repr__(self) raises -> String:
        var parent: String = ""
        if self.parent:
            parent = self.parent.value().name
        return (
            "Name: "
            + self.name
            + "\nDescription: "
            + self.description
            + "\nArgs: "
            + to_string(self.args)
            + "\nFlags: "
            + to_string(self.flags)
            + "\nCommands: "
            + to_string(self.commands)
            + "\nParent: "
            + parent
        )

    fn full_command(self) raises -> String:
        if self.parent:
            let ancestor: String = self.parent.value().full_command()
            return ancestor + " " + self.name
        else:
            return self.name

    fn help(self) raises -> None:
        """Prints the help information for the command.
        """
        var child_commands: String = ""

        for i in range(len(self.commands)):
            let child = self.commands[i]
            child_commands = child_commands + "  " + child.name + "\n"

        var flags: String = ""
        for i in range(self.flags.size):
            let command = self.flags[i]
            flags = (
                flags
                + "  "
                + "-"
                + command.shorthand
                + ", "
                + "--"
                + command.name
                + "    "
                + command.usage
                + "\n"
            )

        # Build usage statement arguments depending on the command's children and flags.
        var usage_arguments: String = " [args]"
        if len(self.commands) > 0:
            usage_arguments = " [command]" + usage_arguments
        if self.flags.size > 0:
            usage_arguments = usage_arguments + " [flags]"

        var help = self.description + "\n\n"
        let usage = "Usage:\n" + "  " + self.full_command() + usage_arguments + "\n\n"
        let available_commands = "Available commands:\n" + child_commands + "\n"
        let available_flags = "Available flags:\n" + flags + "\n"
        let note = 'Use "' + self.full_command() + ' [command] --help" for more information about a command.'
        help = help + usage + available_commands + available_flags + note
        print(help)

    fn validate_flags(self, input_flags: InputFlags) raises -> None:
        """Validates the flags passed to the command. Raises an error if an invalid flag is passed.
        """
        let length_of_command_flags = self.flags.size
        let length_of_input_flags = len(input_flags)

        if length_of_input_flags > length_of_command_flags:
            raise Error(
                "Specified more flags than the command accepts, please check your"
                " command's flags."
            )

        for input_flag in input_flags.items():
            if not contains_flag(self.flags, input_flag.key.__str__()):
                raise Error(
                    "Invalid flags passed to command: " + input_flag.key.__str__()
                )

    fn execute(inout self) raises -> None:
        """Traverses the arguments passed to the executable and executes the last command in the branch.
        """
        # Traverse the arguments backwards
        # Starting from the last argument passed, check if each arg is a valid child command.
        # If met, all previous args are part of the command tree. All args after the first valid child are arguments.
        var command: Command = self
        var remaining_args = DynamicVector[String]()
        var full_command = self.full_command().split(" ")
        for i in range(self.args.size - 1, -1, -1):
            if contains(full_command, self.args[i]):
                break
            else:
                remaining_args.push_back(self.args[i])

        # Check if the help flag was passed
        for item in self.input_flags.items():
            if item.key == "help":
                command.help()
                return None

        # Check if the flags are valid
        command.validate_flags(self.input_flags)
        command.run(remaining_args, self.input_flags)

    fn add_flag(inout self, flag: Flag) -> None:
        """Adds a flag to the command's flags.

        Args:
            flag: The flag to add to the command's flags.
        """
        self.flags.append(flag)

    fn set_parent(inout self, parent: Self) -> None:
        """Sets the command's parent attribute to the given parent.

        Args:
            parent: The name of the parent command.
        """
        self.parent = parent

    fn add_command(inout self, inout command: Command):
        """Adds child command and set's child's parent attribute to self.

        Args:
            command: The command to add as a child of self.
        """
        self.commands.append(command)
        command.set_parent(self)
