from prism.stdlib.builtins import dict, HashableStr, list
from prism.flag import Flag, Flags, InputFlags, PositionalArgs


alias CommandFunction = fn (args: PositionalArgs, flags: InputFlags) raises -> None


fn dummy(args: PositionalArgs, flags: InputFlags) raises -> None:
    pass


# child command name : parent command name
alias CommandTree = dict[HashableStr, String]
alias CommandMap = dict[HashableStr, Command]


@value
struct Command(CollectionElement):
    var name: String
    var description: String
    var run: CommandFunction

    var args: PositionalArgs
    var flags: Flags

    # var parent: Pointer[Self]
    # var commands: Tuple[Pointer[Self]]
    var commands: list[String]

    fn __init__(
        inout self,
        name: String,
        description: String,
        run: CommandFunction,
        args: PositionalArgs = PositionalArgs(),
        flags: Flags = Flags(),
    ):
        self.name = name
        self.description = description
        self.run = run

        self.args = args
        self.flags = flags
        # self.parent = Pointer[Command].get_null()
        # self.commands = Tuple(Pointer[Command].get_null())
        self.commands = list[String]()

    fn __copyinit__(inout self, existing: Self):
        self.name = existing.name
        self.description = existing.description
        self.run = existing.run

        self.args = existing.args
        self.flags = existing.flags
        # self.parent = existing.parent
        self.commands = existing.commands

    fn __moveinit__(inout self, owned existing: Self):
        self.name = existing.name
        self.description = existing.description
        self.run = existing.run

        self.args = existing.args
        self.flags = existing.flags
        # self.parent = existing.parent
        self.commands = existing.commands

    fn execute(
        self, inout args: PositionalArgs, flags: InputFlags, command_map: CommandMap
    ) raises -> None:
        # Check if the flags are valid
        # TODO: Clean this up
        let length_of_command_flags = len(self.flags)
        let length_of_input_flags = len(self.flags)
        for input_flag in flags.items():
            let valid = False
            for i in range(length_of_command_flags):
                let command_flag = self.flags[i]
                if input_flag.key == command_flag.name:
                    break

                if i == length_of_command_flags - 1:
                    if valid == False:
                        raise Error("Invalid flag: " + input_flag.key.__str__())

        # Because it's difficult to use recursive references to Command, I'm using an external command map to find the child command
        # If the first arg matches the name of one of the child commands, get the child command and pop that arg off the list.
        for name in self.commands:
            if args[0] == name:
                let command = command_map[args[0]]
                _ = args.pop_back()
                command.run(args, flags)

                return None

        self.run(args, flags)

    fn add_flag(inout self, flag: Flag):
        self.flags.append(flag)

    fn add_command(inout self, inout command: Command):
        """Adds command as a child of self, by setting child's parent attribute to self.
        """
        # command.parent = Pointer[Command].address_of(self)
        self.commands.append(command.name)


fn main():
    pass
