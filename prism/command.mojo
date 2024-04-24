from sys import argv
from collections.optional import Optional
from collections.dict import Dict, KeyElement
from memory._arc import Arc
from external.gojo.fmt import sprintf
from external.gojo.builtins import panic
from external.gojo.strings import StringBuilder
from .flag import Flag, FlagSet, get_flags
from .args import arbitrary_args, get_args
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


fn default_help(command: Arc[Command]) -> String:
    """Prints the help information for the command."""
    var cmd = command[]
    var builder = StringBuilder()
    _ = builder.write_string(cmd.description)
    _ = builder.write_string("\n\n")

    # Build usage statement arguments depending on the command's children and flags.
    var full_command = cmd._full_command()
    _ = builder.write_string(sprintf("Usage:\n  %s%s", full_command, String(" [args]")))
    if len(cmd.children) > 0:
        _ = builder.write_string(" [command]")
    if len(cmd.flags[]) > 0:
        _ = builder.write_string(" [flags]")

    _ = builder.write_string("\n\nAvailable commands:\n")
    for child in cmd.children:
        _ = builder.write_string(sprintf("  %s\n", str(child[][])))

    _ = builder.write_string("\nAvailable flags:\n")
    for flag in cmd.flag_list():
        _ = builder.write_string(sprintf("  -%s, --%s    %s\n", flag[][].shorthand, flag[][].name, flag[][].usage))

    _ = builder.write_string(sprintf('Use "%s [command] --help" for more information about a command.', full_command))
    return str(builder)


alias CommandArc = Arc[Command]
alias CommandFunction = fn (command: Arc[Command], args: List[String]) -> None
alias CommandFunctionErr = fn (command: Arc[Command], args: List[String]) -> Error
alias HelpFunction = fn (Arc[Command]) -> String
alias ArgValidator = fn (command: Arc[Command], args: List[String]) escaping -> Optional[String]

# Set to True to traverse all parents' persistent pre and post run hooks. If False, it'll only run the first match.
# If False, starts from the child command and goes up the parent chain. If True, starts from root and goes down.
# TODO: For now it's locked to False until file scope variables.
alias ENABLE_TRAVERSE_RUN_HOOKS = False


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


# TODO: For parent Arc[Optional[Self]] works but Optional[Arc[Self]] causes compiler issues.
@value
struct Command(CollectionElement):
    """A struct representing a command that can be executed from the command line.

    Args:
        name: The name of the command.
        description: The description of the command.
        arg_validator: The function to validate the arguments passed to the command.
        valid_args: The valid arguments for the command.
        run: The function to run when the command is executed.
        pre_run: The function to run before the command is executed.
        post_run: The function to run after the command is executed.
        erroring_run: The function to run when the command is executed that returns an error.
        erroring_pre_run: The function to run before the command is executed that returns an error.
        erroring_post_run: The function to run after the command is executed that returns an error.
        help: The function to generate help text for the command.
    """

    var name: String
    var description: String

    # Generates help text.
    var help: HelpFunction

    var pre_run: Optional[CommandFunction]
    var run: Optional[CommandFunction]
    var post_run: Optional[CommandFunction]

    var erroring_pre_run: Optional[CommandFunctionErr]
    var erroring_run: Optional[CommandFunctionErr]
    var erroring_post_run: Optional[CommandFunctionErr]

    var persistent_pre_run: Optional[CommandFunction]
    var persistent_post_run: Optional[CommandFunction]

    var persistent_erroring_pre_run: Optional[CommandFunctionErr]
    var persistent_erroring_post_run: Optional[CommandFunctionErr]

    var arg_validator: ArgValidator
    var valid_args: List[String]

    # Local flags for the command.
    var local_flags: Arc[FlagSet]

    # Local flags that also persist to children.
    var persistent_flags: Arc[FlagSet]

    # Cached results from self._merge_flags(). It is all local, persistent, and inherited flags.
    var flags: Arc[FlagSet]

    # Cached results from self._merge_flags().
    var _inherited_flags: Arc[FlagSet]

    var children: List[Arc[Self]]
    var parent: Arc[Optional[Self]]

    fn __init__(
        inout self,
        name: String,
        description: String,
        valid_args: List[String] = List[String](),
        run: Optional[CommandFunction] = None,
        pre_run: Optional[CommandFunction] = None,
        post_run: Optional[CommandFunction] = None,
        erroring_run: Optional[CommandFunctionErr] = None,
        erroring_pre_run: Optional[CommandFunctionErr] = None,
        erroring_post_run: Optional[CommandFunctionErr] = None,
        persistent_pre_run: Optional[CommandFunction] = None,
        persistent_post_run: Optional[CommandFunction] = None,
        persistent_erroring_pre_run: Optional[CommandFunctionErr] = None,
        persistent_erroring_post_run: Optional[CommandFunctionErr] = None,
        help: HelpFunction = default_help,
    ):
        if not run and not erroring_run:
            panic("A command must have a run or erroring_run function.")

        self.name = name
        self.description = description

        self.help = help

        self.pre_run = pre_run
        self.run = run
        self.post_run = post_run

        self.erroring_pre_run = erroring_pre_run
        self.erroring_run = erroring_run
        self.erroring_post_run = erroring_post_run

        self.persistent_pre_run = persistent_pre_run
        self.persistent_post_run = persistent_post_run
        self.persistent_erroring_pre_run = persistent_erroring_pre_run
        self.persistent_erroring_post_run = persistent_erroring_post_run

        self.arg_validator = arbitrary_args
        self.valid_args = valid_args

        self.children = List[Arc[Self]]()
        self.parent = Arc[Optional[Command]](None)

        # These need to be mutable so we can add flags to them.
        self.flags = Arc(FlagSet())
        self.local_flags = Arc(FlagSet())
        self.persistent_flags = Arc(FlagSet())
        self._inherited_flags = Arc(FlagSet())
        self.local_flags[].add_bool_flag(
            name="help", shorthand="h", usage="Displays help information about the command."
        )

    # TODO: Why do we have 2 almost indentical init functions? Setting a default arg_validator value, breaks the compiler as of 24.2.
    fn __init__(
        inout self,
        name: String,
        description: String,
        arg_validator: ArgValidator,
        valid_args: List[String] = List[String](),
        run: Optional[CommandFunction] = None,
        pre_run: Optional[CommandFunction] = None,
        post_run: Optional[CommandFunction] = None,
        erroring_run: Optional[CommandFunctionErr] = None,
        erroring_pre_run: Optional[CommandFunctionErr] = None,
        erroring_post_run: Optional[CommandFunctionErr] = None,
        persistent_pre_run: Optional[CommandFunction] = None,
        persistent_post_run: Optional[CommandFunction] = None,
        persistent_erroring_pre_run: Optional[CommandFunctionErr] = None,
        persistent_erroring_post_run: Optional[CommandFunctionErr] = None,
        help: HelpFunction = default_help,
    ):
        if not run and not erroring_run:
            panic("A command must have a run or erroring_run function.")

        self.name = name
        self.description = description

        self.help = help

        self.pre_run = pre_run
        self.run = run
        self.post_run = post_run

        self.erroring_pre_run = erroring_pre_run
        self.erroring_run = erroring_run
        self.erroring_post_run = erroring_post_run

        self.persistent_pre_run = persistent_pre_run
        self.persistent_post_run = persistent_post_run
        self.persistent_erroring_pre_run = persistent_erroring_pre_run
        self.persistent_erroring_post_run = persistent_erroring_post_run

        self.children = List[Arc[Self]]()
        self.parent = Arc[Optional[Command]](None)

        self.arg_validator = arg_validator
        self.valid_args = valid_args
        self.flags = Arc(FlagSet())
        self.local_flags = Arc(FlagSet())
        self.persistent_flags = Arc(FlagSet())
        self._inherited_flags = Arc(FlagSet())
        self.local_flags[].add_bool_flag(
            name="help", shorthand="h", usage="Displays help information about the command."
        )

    fn __copyinit__(inout self, existing: Self):
        self.name = existing.name
        self.description = existing.description

        self.help = existing.help

        self.pre_run = existing.pre_run
        self.run = existing.run
        self.post_run = existing.post_run

        self.erroring_pre_run = existing.erroring_pre_run
        self.erroring_run = existing.erroring_run
        self.erroring_post_run = existing.erroring_post_run

        self.persistent_pre_run = existing.persistent_pre_run
        self.persistent_post_run = existing.persistent_post_run
        self.persistent_erroring_pre_run = existing.persistent_erroring_pre_run
        self.persistent_erroring_post_run = existing.persistent_erroring_post_run

        self.arg_validator = existing.arg_validator
        self.valid_args = existing.valid_args
        self.flags = existing.flags
        self.local_flags = existing.local_flags
        self.persistent_flags = existing.persistent_flags
        self._inherited_flags = existing._inherited_flags

        self.children = existing.children
        self.parent = existing.parent

    fn __moveinit__(inout self, owned existing: Self):
        self.name = existing.name^
        self.description = existing.description^

        self.help = existing.help

        self.pre_run = existing.pre_run^
        self.run = existing.run^
        self.post_run = existing.post_run^

        self.erroring_pre_run = existing.erroring_pre_run^
        self.erroring_run = existing.erroring_run^
        self.erroring_post_run = existing.erroring_post_run^

        self.persistent_pre_run = existing.persistent_pre_run^
        self.persistent_post_run = existing.persistent_post_run^
        self.persistent_erroring_pre_run = existing.persistent_erroring_pre_run^
        self.persistent_erroring_post_run = existing.persistent_erroring_post_run^

        self.arg_validator = existing.arg_validator^
        self.valid_args = existing.valid_args^
        self.flags = existing.flags^
        self.local_flags = existing.local_flags^
        self.persistent_flags = existing.persistent_flags^
        self._inherited_flags = existing._inherited_flags^

        self.children = existing.children^
        self.parent = existing.parent^

    fn __str__(self) -> String:
        return "(Name: " + self.name + ", Description: " + self.description + ")"

    fn __repr__(inout self) -> String:
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
            + str(self.flags[])
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

    fn _root(self) -> Arc[Command]:
        """Returns the root command of the command tree."""
        if self.parent[]:
            return self.parent[].value()._root()

        return self

    fn execute(inout self) -> None:
        """Traverses the arguments passed to the executable and executes the last command in the branch."""
        # Traverse from the root command through the children to find a match for the current argument.
        # Any additional arguments past the last matched command name are considered arguments.
        # TODO: Tree traversal is new to me, there's probably a better way to do this.

        # Always execute from the root command, regardless of what command was executed in main.
        if self.parent[]:
            return self._root()[].execute()

        var remaining_args: List[String]
        var command: Self
        command, remaining_args = parse_command_from_args(self)
        var command_ref = Arc(command)

        # Merge local and inherited flags
        command_ref[]._merge_flags()

        var parents = List[Arc[Optional[Command]]]()
        var parent = Arc[Optional[Command]](command)

        # Add all parents to the list to check if they have persistent pre/post hooks.
        while True:
            parents.append(parent)
            if not parent[].value().parent[]:
                break
            parent = parent[].value().parent[]

        # If ENABLE_TRAVERSE_RUN_HOOKS is True, reverse the list to start from the root command rather than
        # from the child. This is because all of the persistent hooks will be run.
        @parameter
        if ENABLE_TRAVERSE_RUN_HOOKS:
            parents.reverse()

        # Get the flags for the command to be executed.
        # store flags as a mutable ref
        var flags = command_ref[].flags
        var err: Error
        remaining_args, err = get_flags(flags, remaining_args)
        if err:
            panic(err)

        # Check if the help flag was passed
        var help_passed = command_ref[].flags[].get_as_bool("help")
        if help_passed.value() == True:
            print(command.help(command_ref))
            return None

        # Validate the remaining arguments
        var error_message = self.arg_validator(command_ref, remaining_args)
        if error_message:
            panic(error_message.value())

        # Run the persistent pre-run hooks.
        for parent in parents:
            if parent[][]:
                var cmd = parent[][].value()
                if cmd.persistent_erroring_pre_run:
                    err = cmd.persistent_erroring_pre_run.value()(command_ref, remaining_args)
                    if err:
                        panic(err)
                    if not ENABLE_TRAVERSE_RUN_HOOKS:
                        break
                else:
                    if cmd.persistent_pre_run:
                        cmd.persistent_pre_run.value()(command_ref, remaining_args)
                        if not ENABLE_TRAVERSE_RUN_HOOKS:
                            break

        # Run the pre-run hooks.
        if command_ref[].pre_run:
            command.pre_run.value()(command_ref, remaining_args)
        elif command_ref[].erroring_pre_run:
            err = command.erroring_pre_run.value()(command_ref, remaining_args)
            if err:
                panic(err)

        # Run the function's commands.
        if command_ref[].run:
            command_ref[].run.value()(command_ref, remaining_args)
        else:
            err = command_ref[].erroring_run.value()(command_ref, remaining_args)
            if err:
                panic(err)

        # Run the persistent post-run hooks.
        for parent in parents:
            if parent[][]:
                var cmd = parent[][].value()
                if cmd.persistent_erroring_post_run:
                    err = cmd.persistent_erroring_post_run.value()(command_ref, remaining_args)
                    if err:
                        panic(err)
                    if not ENABLE_TRAVERSE_RUN_HOOKS:
                        break
                else:
                    if cmd.persistent_post_run:
                        cmd.persistent_post_run.value()(command_ref, remaining_args)
                        if not ENABLE_TRAVERSE_RUN_HOOKS:
                            break

        # Run the post-run hooks.
        if command_ref[].post_run:
            command.post_run.value()(command_ref, remaining_args)
        elif command_ref[].erroring_post_run:
            err = command.erroring_post_run.value()(command_ref, remaining_args)
            if err:
                panic(err)

    fn inherited_flags(self) -> Arc[FlagSet]:
        """Returns the flags for the command and inherited flags from its parent.

        Returns:
            The flags for the command and its parent.
        """
        # Set mutability of flag set by initializing it as a var.
        var i_flags = FlagSet()
        if len(self._inherited_flags[]) == 0:
            if self.parent[]:
                var cmd = self.parent[].value()
                i_flags += cmd.inherited_flags()[]

            i_flags += self.persistent_flags[]
            return Arc(i_flags)

        return self._inherited_flags

    fn _merge_flags(inout self):
        """Returns all flags for the command and inherited flags from its parent."""
        # Set mutability of flag set by initializing it as a var.
        if len(self.flags[]) == 0:
            var all_flags = Arc(FlagSet())
            all_flags[] += self.local_flags[]
            all_flags[] += self.persistent_flags[]
            self._inherited_flags = self.inherited_flags()
            all_flags[] += self._inherited_flags[]

            self.flags = all_flags

    fn add_command(inout self, inout command: Command):
        """Adds child command and set's child's parent attribute to self.

        Args:
            command: The command to add as a child of self.
        """
        self.children.append(Arc(command))
        command.parent[] = self

    # NOTE: These wrappers are just nice to have. Feels good to call Command().add_flag()
    # instead of Command().flags[].add_flag()
    fn flag_list(self) -> List[Arc[Flag]]:
        """Returns a list of references to all flags in the merged flag set (local, persistent, inherited).

        This is just a convenience function to avoid having to call Command().flags[].get_flags().
        """
        return self.flags[].flags

    fn add_bool_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: Bool = False,
    ) -> None:
        """Adds a Bool flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.local_flags[].add_bool_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_string_flag(
        inout self,
        name: String,
        usage: String,
        shorthand: String = "",
        default: String = "",
    ) -> None:
        """Adds a String flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.local_flags[].add_string_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_int_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int = 0) -> None:
        """Adds an Int flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.local_flags[].add_int_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_int8_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int8 = 0) -> None:
        """Adds an Int8 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.local_flags[].add_int8_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_int16_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int16 = 0) -> None:
        """Adds an Int16 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.local_flags[].add_int16_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_int32_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int32 = 0) -> None:
        """Adds an Int32 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.local_flags[].add_int32_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_int64_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int64 = 0) -> None:
        """Adds an Int64 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.local_flags[].add_int64_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_uint8_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt8 = 0) -> None:
        """Adds a UInt8 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.local_flags[].add_uint8_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_uint16_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt16 = 0) -> None:
        """Adds a UInt16 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.local_flags[].add_uint16_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_uint32_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt32 = 0) -> None:
        """Adds a UInt32 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.local_flags[].add_uint32_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_uint64_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt64 = 0) -> None:
        """Adds a UInt64 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.local_flags[].add_uint64_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_float16_flag(inout self, name: String, usage: String, shorthand: String = "", default: Float16 = 0) -> None:
        """Adds a Float16 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.local_flags[].add_float16_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_float32_flag(inout self, name: String, usage: String, shorthand: String = "", default: Float32 = 0) -> None:
        """Adds a Float32 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.local_flags[].add_float32_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_float64_flag(inout self, name: String, usage: String, shorthand: String = "", default: Float64 = 0) -> None:
        """Adds a Float64 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.local_flags[].add_float64_flag(name=name, usage=usage, default=default, shorthand=shorthand)
