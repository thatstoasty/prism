from prism.stdlib.builtins import dict, HashableStr, list
from prism.stdlib.builtins.vector import contains
from prism.flag import Flag, Flags, InputFlags, PositionalArgs, get_args_and_flags


alias CommandFunction = fn (args: PositionalArgs, flags: InputFlags) raises -> None


fn dummy(args: PositionalArgs, flags: InputFlags) raises -> None:
    pass


# child command name : parent command name
alias CommandTree = dict[HashableStr, String]
alias CommandMap = dict[HashableStr, Command]


fn validate_flags(input_flags: InputFlags, command_flags: Flags) raises -> None:
    let length_of_command_flags = len(command_flags)
    let length_of_input_flags = len(input_flags)

    if length_of_input_flags > length_of_command_flags:
        raise Error(
            "Specified more flags than the command accepts, please check your command's"
            " flags."
        )

    for input_flag in input_flags.items():
        for i in range(length_of_command_flags):
            if input_flag.key == command_flags[i].name:
                break

        raise Error("Invalid flags passed to command: " + input_flag.key.__str__())


fn print_help(command: Command, command_map: CommandMap) -> None:
    var child_commands: String = ""
    for child in command_map.items():
        if child.value.parent == command.name:
            child_commands = child_commands + "  " + child.key.__str__() + "\n"

    var flags: String = ""
    for i in range(command.flags.size):
        let command = command.flags[i]
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

    var help = command.description + "\n\n"
    let usage = "Usage:\n" + "  " + command.name + " [command] [args] [flags]\n\n"
    let available_commands = "Available commands:\n" + child_commands + "\n"
    let available_flags = "Available flags:\n" + flags + "\n"
    let note = 'Use "' + command.name + ' [command] --help" for more information about a command.'
    help = help + usage + available_commands + available_flags + note
    print(help)


@value
struct Command(CollectionElement):
    var name: String
    var description: String
    var run: CommandFunction

    var args: PositionalArgs
    var flags: Flags
    var input_flags: InputFlags

    var commands: list[String]
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

        self.commands = list[String]()
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
        self.name = existing.name
        self.description = existing.description
        self.run = existing.run

        self.args = existing.args
        self.flags = existing.flags
        self.input_flags = existing.input_flags
        self.commands = existing.commands
        self.parent = existing.parent

    fn execute(inout self, command_map: CommandMap) raises -> None:
        # Traverse the arguments backwards
        # Starting from the last argument passed, check if each arg is a valid child command.
        # If met, all previous args are part of the command tree. All args after the first valid child are arguments.
        var command: Command = self
        var remaining_args: DynamicVector[String] = DynamicVector[String]()
        for i in range(self.args.size - 1, -1, -1):
            if contains(command_map._keys, self.args[i]):
                command = command_map.__getitem__(self.args[i])
                break
            else:
                remaining_args.push_back(self.args[i])

        # Check if the help flag was passed
        for item in self.input_flags.items():
            if item.key == "help":
                print_help(command, command_map)
                return None

        # Check if the flags are valid
        validate_flags(self.input_flags, command.flags)
        command.run(remaining_args, self.input_flags)
        # self.run(self.args, self.input_flags)

    fn add_flag(inout self, flag: Flag):
        self.flags.append(flag)

    fn set_parent(inout self, parent: String):
        self.parent = parent

    fn add_command(inout self, inout command: Command):
        """Adds command as a child of self, by setting child's parent attribute to self.
        """
        self.commands.append(command.name)
        command.set_parent(self.name)


fn main():
    pass
