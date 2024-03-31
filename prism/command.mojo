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
from .vector import contains, to_string, join, get_slice, index_of
from memory._arc import Arc


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
        self.flags.append(
            Flag("help", "h", "Displays help information about the command.")
        )
        self.input_flags = InputFlags()
        get_args_and_flags(self.args, self.input_flags)

        self.children = List[Arc[Self]]()
        self.parent = Arc[Optional[Command]](None)

    fn __copyinit__(inout self, existing: Self):
        self.name = existing.name
        self.description = existing.description
        self.run = existing.run

        self.args = existing.args
        self.flags = existing.flags
        self.input_flags = existing.input_flags
        self.children = existing.children
        self.parent = existing.parent

    fn __moveinit__(inout self, owned existing: Self):
        self.name = existing.name ^
        self.description = existing.description ^
        self.run = existing.run

        self.args = existing.args ^
        self.flags = existing.flags ^
        self.input_flags = existing.input_flags ^
        self.children = existing.children ^
        self.parent = existing.parent ^

    fn __str__(self) -> String:
        return "(Name: " + self.name + ", Description: " + self.description + ")"

    fn __repr__(self) raises -> String:
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
            + string(self.flags)
            + "\nCommands: "
            + to_string(self.children)
            + "\nParent: "
            + parent_name
        )

    fn full_command(self) raises -> String:
        if self.parent[]:
            var ancestor: String = self.parent[].value().full_command()
            return ancestor + " " + self.name
        else:
            return self.name

    fn help(self) raises -> None:
        """Prints the help information for the command.
        """
        var child_commands: String = ""

        for i in range(len(self.children)):
            var child = self.children[i]
            child_commands = child_commands + "  " + child[] + "\n"

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
        if len(self.children) > 0:
            usage_arguments = " [command]" + usage_arguments
        if self.flags.size > 0:
            usage_arguments = usage_arguments + " [flags]"

        var help = self.description + "\n\n"
        var usage = "Usage:\n" + "  " + self.full_command() + usage_arguments + "\n\n"
        var available_commands = "Available commands:\n" + child_commands + "\n"
        var available_flags = "Available flags:\n" + flags + "\n"
        var note = 'Use "' + self.full_command() + ' [command] --help" for more information about a command.'
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

    fn _match_command_from_args(self, args: PositionalArgs) -> Optional[Self]:
        """Matches the command from the args passed to the executable.

        Args:
            args: The arguments passed to the executable.

        Returns:
            The command that matches the args passed to the executable.
        """
        var command: Optional[Self] = None
        var remaining_args = List[String]()
        # for arg in self.args:
        #     for command_ref in self.commands:
        #         if command_ref[][].name == arg[]:
        #             current_command += arg[]
                
        #         if command_ref[][].full_command() == current_command:
        #             command = command_ref[][]
        #             return command

        return None

    fn execute(self) raises -> None:
        """Traverses the arguments passed to the executable and executes the last command in the branch.
        """
        # Traverse from the root command through the children to find a match for the current argument.
        # Any additional arguments past the last matched command name are considered arguments.
        # TODO: Tree traversal is new to me, there's probably a better way to do this.
        # TODO: Passing no matching commands should by default run the root command, since the program will be run as a binary.
        var command = self
        var children = command.children
        var leftover_args_start_index = 1 # Start at 1 to start slice at the first remaining arg, not the last child command.

        for arg in self.args:
            for command_ref in children:
                if command_ref[][].name == arg[]:
                    command = command_ref[][]
                    children = command.children
                    leftover_args_start_index += 1
                    break
        
        var remaining_args = self.args[leftover_args_start_index:len(self.args)] 
        
        # Check if the help flag was passed
        for item in self.input_flags.items():
            if item[].key == "help":
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
