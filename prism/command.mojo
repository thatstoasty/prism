from collections.optional import Optional
from collections.dict import Dict, KeyElement
from .flag import (
    Flag,
    Flags,
    InputFlags,
    PositionalArgs,
    StringKey,
    get_args_and_flags,
    contains_flag,
    string,
)
from .vector import contains, to_string, join, get_slice


alias CommandFunction = fn (args: PositionalArgs, flags: InputFlags) raises -> None

# child command name : parent command name
alias CommandMap = Dict[StringKey, Command]


# TODO: Make this command map population more ergonomic. Difficult without having some sort of global context or top level scope.
fn add_command(
    inout command: Command, inout parent_command: Command, inout command_map: CommandMap
) -> None:
    """Sets the command's parent field to the name of the parent command, and adds the command to the command map.

    Args:
        command: The command to add to the command map.
        parent_command: The parent command of the command to add.
        command_map: The command map to add the command to.

    """
    parent_command.add_command(command)
    command_map[command.name] = command


# TODO: Add pre run, post run, and persistent flags
@value
struct Command(CollectionElement):
    var name: String
    var description: String
    var run: CommandFunction

    var args: PositionalArgs
    var flags: Flags
    var input_flags: InputFlags

    var commands: List[String]
    var parent: String

    fn __init__(
        inout self, name: String, description: String, run: CommandFunction
    ) raises:
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

        self.commands = List[String]()
        self.parent = ""

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
        self.name = existing.name ^
        self.description = existing.description ^
        self.run = existing.run

        self.args = existing.args ^
        self.flags = existing.flags ^
        self.input_flags = existing.input_flags ^
        self.commands = existing.commands ^
        self.parent = existing.parent ^

    fn __str__(self) -> String:
        return "(Name: " + self.name + ", Description: " + self.description + ")"

    fn __repr__(self) raises -> String:
        return (
            "Name: "
            + self.name
            + "\nDescription: "
            + self.description
            + "\nArgs: "
            + to_string(self.args)
            + "\nFlags: "
            + string(self.flags)
            + "\nCommands: "
            + to_string(self.commands)
            + "\nParent: "
            + self.parent
        )

    fn full_command(self, command_map: CommandMap) raises -> String:
        if self.parent != "":
            var ancestor: String = command_map[self.parent].full_command(command_map)
            return ancestor + " " + self.name

        return self.name

    fn help(self, command_map: CommandMap) raises -> None:
        """Prints the help information for the command.

        Args:
            command_map: The command map to use to find the command's children.
        """
        var child_commands: String = ""
        for child in command_map.items():
            if child[].value.parent == self.name:
                child_commands = child_commands + "  " + str(child[].key) + "\n"

        var flags: String = ""
        for i in range(self.flags.size):
            var command = self.flags[i]
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
        var usage = "Usage:\n" + "  " + self.full_command(
            command_map
        ) + usage_arguments + "\n\n"
        var available_commands = "Available commands:\n" + child_commands + "\n"
        var available_flags = "Available flags:\n" + flags + "\n"
        var note = 'Use "' + self.full_command(
            command_map
        ) + ' [command] --help" for more information about a command.'
        help = help + usage + available_commands + available_flags + note
        print(help)

    fn validate_flags(self, input_flags: InputFlags) raises -> None:
        """Validates the flags passed to the command. Raises an error if an invalid flag is passed.

        Args:
            input_flags: The flags passed to the command.
        """
        var length_of_command_flags = self.flags.size
        var length_of_input_flags = len(input_flags)

        if length_of_input_flags > length_of_command_flags:
            raise Error(
                "Specified more flags than the command accepts, please check your"
                " command's flags."
            )

        for input_flag in input_flags.items():
            if not contains_flag(self.flags, str(input_flag[].key)):
                raise Error(
                    "Invalid flags passed to command: " + str(input_flag[].key)
                )

    fn execute(self, command_map: CommandMap) raises -> None:
        """Traverses the arguments passed to the executable and executes the last command in the branch.

        Args:
            command_map: The command map to use to find the command's children.
        """
        # Traverse the arguments backwards
        # Starting from the last argument passed, check if each arg is a valid child command.
        # If met, all previous args are part of the command tree. All args after the first valid child are arguments.
        var remaining_args = List[String]()
        for i in range(len(self.args) - 1, -1, -1):
            if contains(command_map, self.args[i]):
                var command = command_map[self.args[i]]

                # Check if the full command branch of the child command matches what was passed in.
                # full_command will traverse the parent commands to get the full command, while join is just joining the args.
                if join(" ", get_slice(self.args, Slice(0, i+1))) == command.full_command(command_map):
                    # Check if the help flag was passed
                    for item in self.input_flags.items():
                        if item[].key == "help":
                            command.help(command_map)
                            return None

                    # Check if the flags are valid
                    command.validate_flags(self.input_flags)
                    command.run(remaining_args, self.input_flags)
            else:
                remaining_args.append(self.args[i])



    fn add_flag(inout self, flag: Flag) -> None:
        """Adds a flag to the command's flags.

        Args:
            flag: The flag to add to the command's flags.
        """
        self.flags.append(flag)

    fn set_parent(inout self, parent: String) -> None:
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
        self.commands.append(command.name)
        command.set_parent(self.name)
