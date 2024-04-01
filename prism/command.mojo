from collections.optional import Optional
from collections.dict import Dict, KeyElement
from memory._arc import Arc
from .flag import Flag, Flags, FlagSet, InputFlags, StringKey, get_args_and_flags

# from .args import arbitrary_args
from .vector import join, to_string, contains
from .fmt import sprintf


alias CommandFunction = fn (command: Arc[Command], args: List[String]) raises -> None
alias CommandArc = Arc[Command]


# TODO: Add pre run, post run, and persistent flags
@value
struct Command(CollectionElement):
    var name: String
    var description: String

    var pre_run: Optional[CommandFunction]
    var run: CommandFunction
    var post_run: Optional[CommandFunction]

    var args: PositionalArgs
    var valid_args: List[String]
    var flags: FlagSet

    var children: List[Arc[Self]]
    var parent: Arc[Optional[Self]]

    fn __init__(
        inout self,
        name: String,
        description: String,
        run: CommandFunction,
        args: PositionalArgs = arbitrary_args,
        valid_args: List[String] = List[String](),
        pre_run: Optional[CommandFunction] = None,
        post_run: Optional[CommandFunction] = None,
    ) raises:
        self.name = name
        self.description = description

        self.pre_run = pre_run
        self.run = run
        self.post_run = post_run

        self.args = args
        self.valid_args = valid_args
        self.flags = Flags()
        self.flags.add_flag(
            Flag("help", "h", "Displays help information about the command.")
        )

        self.children = List[Arc[Self]]()
        self.parent = Arc[Optional[Command]](None)

    fn __copyinit__(inout self, existing: Self):
        self.name = existing.name
        self.description = existing.description

        self.pre_run = existing.pre_run
        self.run = existing.run
        self.post_run = existing.post_run

        self.args = existing.args
        self.valid_args = existing.valid_args
        self.flags = existing.flags
        self.children = existing.children
        self.parent = existing.parent

    fn __moveinit__(inout self, owned existing: Self):
        self.name = existing.name ^
        self.description = existing.description ^

        self.pre_run = existing.pre_run ^
        self.run = existing.run
        self.post_run = existing.post_run ^

        self.args = existing.args ^
        self.valid_args = existing.valid_args ^
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
            + to_string(self.valid_args)
            + "\nFlags: "
            + str(self.flags)
            + "\nCommands: "
            + to_string(self.children)
            + "\nParent: "
            + parent_name
        )

    fn full_command(self) -> String:
        """Traverses up the parent command tree to build the full command as a string.
        """
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
        var args = get_args_and_flags(self.flags)
        var command = self
        var children = command.children
        var leftover_args_start_index = 1  # Start at 1 to start slice at the first remaining arg, not the last child command.

        for arg in args:
            for command_ref in children:
                if command_ref[][].name == arg[]:
                    command = command_ref[][]
                    children = command.children
                    leftover_args_start_index += 1
                    break

        # If the there are more or equivalent args to the index, then there are remaining args to pass to the command.
        var remaining_args = List[String]()
        if len(args) >= leftover_args_start_index:
            remaining_args = args[leftover_args_start_index : len(args)]

        # Check if the help flag was passed
        for flag in self.flags.get_flags_with_values():
            if flag[][].name == "help":
                command.help()
                return None

        # Check if the flags are valid
        command.validate_flag_set(command.flags)

        # Run the function's commands.
        if command.pre_run:
            command.pre_run.value()(Arc(command), remaining_args)
        command.run(Arc(command), remaining_args)
        if command.post_run:
            command.post_run.value()(Arc(command), remaining_args)

    fn add_flag(inout self, flag: Flag) -> None:
        """Adds a flag to the command's flags.

        Args:
            flag: The flag to add to the command.
        """
        self.flags.add_flag(flag)

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


alias PositionalArgs = fn (
    command: Arc[Command], args: List[String]
) escaping -> Optional[Error]


fn no_args(command: Arc[Command], args: List[String]) -> Optional[Error]:
    """Returns an error if the command has any arguments.

    Args:
        command: The command to check.
        args: The arguments to check.
    """
    if len(args) > 0:
        return Error("Command " + command[].name + "does not take any arguments")
    return None


fn valid_args(command: Arc[Command], args: List[String]) -> Optional[Error]:
    """Returns an error if threre are any positional args that are not in the command's valid_args.

    Args:
        command: The command to check.
        args: The arguments to check.
    """
    if len(command[].valid_args) > 0:
        for arg in args:
            if not contains(command[].valid_args, arg[]):
                return Error(
                    "Invalid argument " + arg[] + " for command " + command[].name
                )
    return None


fn arbitrary_args(command: Arc[Command], args: List[String]) -> Optional[Error]:
    """Never returns an error.

    Args:
        command: The command to check.
        args: The arguments to check.
    """
    return None


fn minimum_n_args[n: Int]() -> PositionalArgs:
    """Returns an error if there is not at least n arguments.

    Params:
        n: The minimum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn less_than_n_args(command: Arc[Command], args: List[String]) -> Optional[Error]:
        if len(args) < n:
            return Error(
                sprintf(
                    "Command %s accepts at least %d arguments. Received: %d.",
                    command[].name,
                    n,
                    len(args),
                )
            )
        return None

    return less_than_n_args


fn maximumn_args[n: Int]() -> PositionalArgs:
    """Returns an error if there are more than n arguments.

    Params:
        n: The maximum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn more_than_n_args(command: Arc[Command], args: List[String]) -> Optional[Error]:
        if len(args) > n:
            return Error(
                "Command "
                + command[].name
                + " accepts at most "
                + n
                + " arguments. Received: "
                + len(args)
            )
        return None

    return more_than_n_args


fn exact_args[n: Int]() -> PositionalArgs:
    """Returns an error if there are not exactly n arguments.

    Params:
        n: The number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn exactly_n_args(command: Arc[Command], args: List[String]) -> Optional[Error]:
        if len(args) == n:
            return Error(
                "Command "
                + command[].name
                + " accepts exactly "
                + n
                + " arguments. Received: "
                + len(args)
            )
        return None

    return exactly_n_args


fn range_args[minimum: Int, maximum: Int]() -> PositionalArgs:
    """Returns an error if there are not exactly n arguments.

    Params:
        minimum: The minimum number of arguments.
        maximum: The maximum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn range_n_args(command: Arc[Command], args: List[String]) -> Optional[Error]:
        if len(args) < minimum or len(args) > maximum:
            return Error(
                "Command "
                + command[].name
                + " accepts between "
                + str(minimum)
                + "and "
                + str(maximum)
                + " arguments. Received: "
                + len(args)
            )
        return None

    return range_n_args


# fn match_all[*arg_validators: PositionalArgs]() -> PositionalArgs:
#     fn match_all_args(command: Arc[Command], args: List[String]) -> Optional[Error]:
#         for arg_validator in arg_validators:
#             var error = arg_validator(command, args):
#             if error:
#                 return error
#         return None
#     return match_all_args
