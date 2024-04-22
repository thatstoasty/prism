from sys import argv
from collections.optional import Optional
from collections.dict import Dict, KeyElement
from memory._arc import Arc
from external.gojo.fmt import sprintf
from external.gojo.builtins import panic
from .flag import Flag, FlagSet, get_flags
from .args import arbitrary_args, ArgValidator, get_args
from .vector import join, to_string, contains


fn get_args_as_list() -> List[String]:
    """Returns the arguments passed to the executable as a list of strings."""
    var args = argv()
    var args_list = List[String]()
    var i = 1
    while i < len(args):
        args_list.append(args[i])
        i += 1

    return args_list


alias CommandArc = Arc[Command]
alias CommandFunction = fn (command: Arc[Command], args: List[String]) -> Error


fn parse_command_from_args(start: Command) -> (Command, List[String]):
    var args = get_args_as_list()
    var number_of_args = len(args)
    var command = start
    var children = command.children
    var leftover_args_start_index = 0  # Start at 1 to start slice at the first remaining arg, not the last child command.

    for arg in args:
        for command_ref in children:
            if command_ref[][].name == arg[]:
                command = command_ref[][]
                children = command.children
                leftover_args_start_index += 1
                break

    # If the there are more or equivalent args to the index, then there are remaining args to pass to the command.
    var remaining_args = List[String]()
    if number_of_args >= leftover_args_start_index:
        remaining_args = args[leftover_args_start_index:number_of_args]

    return command, remaining_args


# TODO: Add persistent flags
# TODO: For parent Arc[Optional[Self]] works but Optional[Arc[Self]] causes compiler issues.
@value
struct Command(CollectionElement):
    var name: String
    var description: String

    var pre_run: Optional[CommandFunction]
    var run: CommandFunction
    var post_run: Optional[CommandFunction]

    var arg_validator: ArgValidator
    var valid_args: List[String]
    var flags: FlagSet

    var children: List[Arc[Self]]
    var parent: Arc[Optional[Self]]

    fn __init__(
        inout self,
        name: String,
        description: String,
        run: CommandFunction,
        valid_args: List[String] = List[String](),
        pre_run: Optional[CommandFunction] = None,
        post_run: Optional[CommandFunction] = None,
    ):
        self.name = name
        self.description = description

        self.pre_run = pre_run
        self.run = run
        self.post_run = post_run

        self.arg_validator = arbitrary_args
        self.valid_args = valid_args
        self.flags = FlagSet()
        self.flags.add_bool_flag[name="help", shorthand="h", usage="Displays help information about the command."]()

        self.children = List[Arc[Self]]()
        self.parent = Arc[Optional[Command]](None)

    # TODO: Why do we have 2 almost indentical init functions? Setting a default arg_validator value, breaks the compiler as of 24.2.
    fn __init__(
        inout self,
        name: String,
        description: String,
        run: CommandFunction,
        arg_validator: ArgValidator,
        valid_args: List[String] = List[String](),
        pre_run: Optional[CommandFunction] = None,
        post_run: Optional[CommandFunction] = None,
    ):
        self.name = name
        self.description = description

        self.pre_run = pre_run
        self.run = run
        self.post_run = post_run

        self.arg_validator = arg_validator
        self.valid_args = valid_args
        self.flags = FlagSet()
        self.flags.add_bool_flag[name="help", shorthand="h", usage="Displays help information about the command."]()

        self.children = List[Arc[Self]]()
        self.parent = Arc[Optional[Command]](None)

    @staticmethod
    fn new[
        name: String,
        description: String,
        run: CommandFunction,
        valid_args: List[String] = List[String](),
        pre_run: Optional[CommandFunction] = None,
        post_run: Optional[CommandFunction] = None,
    ](arg_validator: ArgValidator) -> Self:
        """Experimental function to create a new Command by using parameters to offload some work to compile time.

        Params:
            name: The name of the command.
            description: The description of the command.
            run: The function to run when the command is executed.
            valid_args: The valid arguments for the command.
            pre_run: The function to run before the command is executed.
            post_run: The function to run after the command is executed.

        Args:
            arg_validator: The function to validate the arguments passed to the command.

        Returns:
            A new Command instance.
        """
        return Command(
            name,
            description,
            run,
            valid_args,
            pre_run,
            post_run,
        )

    @staticmethod
    fn new[
        name: String,
        description: String,
        run: CommandFunction,
        valid_args: List[String] = List[String](),
        pre_run: Optional[CommandFunction] = None,
        post_run: Optional[CommandFunction] = None,
    ]() -> Self:
        """Experimental function to create a new Command by using parameters to offload some work to compile time.

        Params:
            name: The name of the command.
            description: The description of the command.
            run: The function to run when the command is executed.
            valid_args: The valid arguments for the command.
            pre_run: The function to run before the command is executed.
            post_run: The function to run after the command is executed.

        Returns:
            A new Command instance.
        """
        return Command(
            name,
            description,
            run,
            arbitrary_args,
            valid_args,
            pre_run,
            post_run,
        )

    fn __copyinit__(inout self, existing: Self):
        self.name = existing.name
        self.description = existing.description

        self.pre_run = existing.pre_run
        self.run = existing.run
        self.post_run = existing.post_run

        self.arg_validator = existing.arg_validator
        self.valid_args = existing.valid_args
        self.flags = existing.flags
        self.children = existing.children
        self.parent = existing.parent

    fn __moveinit__(inout self, owned existing: Self):
        self.name = existing.name^
        self.description = existing.description^

        self.pre_run = existing.pre_run^
        self.run = existing.run
        self.post_run = existing.post_run^

        self.arg_validator = existing.arg_validator^
        self.valid_args = existing.valid_args^
        self.flags = existing.flags^
        self.children = existing.children^
        self.parent = existing.parent^

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

    fn _full_command(self) -> String:
        """Traverses up the parent command tree to build the full command as a string."""
        if self.parent[]:
            var ancestor: String = self.parent[].value()._full_command()
            return ancestor + " " + self.name
        else:
            return self.name

    fn _help(self) -> None:
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

        var _full_command = self._full_command()
        var help = self.description + "\n\n"
        var usage = "Usage:\n" + "  " + _full_command + usage_arguments + "\n\n"
        var available_commands = "Available commands:\n" + child_commands + "\n"
        var available_flags = "Available flags:\n" + flags + "\n"
        var note = 'Use "' + _full_command + ' [command] --help" for more information about a command.'
        help = help + usage + available_commands + available_flags + note
        print(help)

    fn execute(inout self) -> None:
        """Traverses the arguments passed to the executable and executes the last command in the branch."""
        # Traverse from the root command through the children to find a match for the current argument.
        # Any additional arguments past the last matched command name are considered arguments.
        # TODO: Tree traversal is new to me, there's probably a better way to do this.
        var remaining_args: List[String]
        var command: Self
        command, remaining_args = parse_command_from_args(self)

        # Get the flags for the command to be executed.
        var err: Error
        remaining_args, err = get_flags(command.flags, remaining_args)
        if err:
            panic(err)

        # Check if the help flag was passed
        var help = command.flags.get_as_bool("help")
        if help.value() == True:
            command._help()
            return None

        # Validate the remaining arguments
        var error_message = self.arg_validator(remaining_args)
        if error_message:
            panic(error_message.value())

        # Run the function's commands.
        if command.pre_run:
            err = command.pre_run.value()(Arc(command), remaining_args)
            if err:
                panic(err)

        err = command.run(Arc(command), remaining_args)
        if err:
            panic(err)

        if command.post_run:
            err = command.post_run.value()(Arc(command), remaining_args)
            if err:
                panic(err)

    fn get_all_flags(self) -> Arc[FlagSet]:
        """Returns all flags for the command and persistent flags from its parent.

        Returns:
            The flags for the command and its children.
        """
        return Arc(self.flags)

    fn add_command(inout self, inout command: Command):
        """Adds child command and set's child's parent attribute to self.

        Args:
            command: The command to add as a child of self.
        """
        self.children.append(Arc(command))
        command.parent[] = self
