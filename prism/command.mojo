from sys import argv
from collections import Optional, Dict
from memory.arc import Arc
import .gojo.fmt
from .gojo.builtins import panic
from .gojo.strings import StringBuilder
from .flag import Flag, get_flags, REQUIRED, REQUIRED_AS_GROUP, ONE_REQUIRED, MUTUALLY_EXCLUSIVE
from .flag_set import FlagSet, process_flag_for_group_annotation, validate_flag_groups
from .args import arbitrary_args, get_args


fn to_string[T: StringableCollectionElement](vector: List[Arc[T]]) -> String:
    var result = String("[")
    for i in range(vector.size):
        var flag = vector[i]
        result += str(flag[])
        if i < vector.size - 1:
            result += String(", ")
    result += String("]")
    return result


fn get_flag_names(flag_names: VariadicListMem[String, _]) -> String:
    var result: String = ""
    for i in range(len(flag_names)):
        result += flag_names[i]
        if i != len(flag_names) - 1:
            result += " "

    return result


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
    var cmd = command
    """Prints the help information for the command."""
    var builder = StringBuilder()
    _ = builder.write_string(cmd[].description)

    if cmd[].aliases:
        _ = builder.write_string("\n\nAliases:")
        _ = builder.write_string(fmt.sprintf("\n  %s", cmd[].aliases.__str__()))

    # Build usage statement arguments depending on the command's children and flags.
    var full_command = cmd[]._full_command()
    _ = builder.write_string(fmt.sprintf("\n\nUsage:\n  %s%s", full_command, String(" [args]")))
    if len(cmd[].children) > 0:
        _ = builder.write_string(" [command]")
    if len(cmd[].flags) > 0:
        _ = builder.write_string(" [flags]")

    if cmd[].children:
        _ = builder.write_string("\n\nAvailable commands:")
        for child in cmd[].children:
            _ = builder.write_string(fmt.sprintf("\n  %s", str(child[][])))

    if cmd[].flags.flags:
        _ = builder.write_string("\n\nAvailable flags:")
        for flag in cmd[].flags.flags:
            _ = builder.write_string(fmt.sprintf("\n  -%s, --%s    %s", flag[].shorthand, flag[].name, flag[].usage))

    _ = builder.write_string(
        fmt.sprintf('\n\nUse "%s [command] --help" for more information about a command.', full_command)
    )
    return str(builder)


alias CommandArc = Arc[Command]
alias CommandFunction = fn (command: Arc[Command], args: List[String]) -> None
"""The function for a command to run."""
alias CommandFunctionErr = fn (command: Arc[Command], args: List[String]) -> Error
"""The function for a command to run that can error."""
alias HelpFunction = fn (Arc[Command]) -> String
"""The function for a help function."""
alias ArgValidator = fn (command: Arc[Command], args: List[String]) escaping -> Optional[String]
"""The function for an argument validator."""
alias ParentVisitorFn = fn (parent: Command) capturing -> None
"""The function for visiting parents of a command."""

# TODO: For now it's locked to False until file scope variables.
alias ENABLE_TRAVERSE_RUN_HOOKS = False
"""Set to True to traverse all parents' persistent pre and post run hooks. If False, it'll only run the first match.
If False, starts from the child command and goes up the parent chain. If True, starts from root and goes down."""


fn parse_command_from_args(start: Command) -> (Command, List[String]):
    var args = get_args_as_list()
    var number_of_args = len(args)
    var command = start
    var children = command.children
    var leftover_args_start_index = 0  # Start at 1 to start slice at the first remaining arg, not the last child command.

    for arg in args:
        for command_ref in children:
            if command_ref[][].name == arg[] or arg[] in command_ref[][].aliases:
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

    ```mojo
    from memory import Arc
    from prism import Command

    fn test(command: Arc[Command], args: List[String]) -> None:
        print("Hello from Chromeria!")

    fn main():
        var command = Arc(Command(
            name="hello",
            description="This is a dummy command!",
            run=test,
        ))
        command[].execute()
    ```

    Then execute the command by running the mojo file or binary.
    ```sh
    > mojo run hello.mojo
    Hello from Chromeria!
    ```
    """

    var name: String
    """The name of the command."""
    var description: String
    """Description of the command."""
    var aliases: List[String]
    """Aliases that can be used instead of the first word in name."""
    var help: HelpFunction
    """Generates help text."""
    var group_id: String
    """The group id under which this subcommand is grouped in the 'help' output of its parent."""

    var pre_run: Optional[CommandFunction]
    """A function to run before the run function is executed."""
    var run: Optional[CommandFunction]
    """A function to run when the command is executed."""
    var post_run: Optional[CommandFunction]
    """A function to run after the run function is executed."""

    var erroring_pre_run: Optional[CommandFunctionErr]
    """A raising function to run before the run function is executed."""
    var erroring_run: Optional[CommandFunctionErr]
    """A raising function to run when the command is executed."""
    var erroring_post_run: Optional[CommandFunctionErr]
    """A raising function to run after the run function is executed."""

    var persistent_pre_run: Optional[CommandFunction]
    """A function to run before the run function is executed. This persists to children."""
    var persistent_post_run: Optional[CommandFunction]
    """A function to run after the run function is executed. This persists to children."""

    var persistent_erroring_pre_run: Optional[CommandFunctionErr]
    """A raising function to run before the run function is executed. This persists to children."""
    var persistent_erroring_post_run: Optional[CommandFunctionErr]
    """A raising function to run after the run function is executed. This persists to children."""

    var arg_validator: ArgValidator
    """Function to validate arguments passed to the command."""
    var valid_args: List[String]
    """Valid arguments for the command."""

    var local_flags: FlagSet
    """Local flags for the command. TODO: Use this field to store cached results for local flags."""

    var persistent_flags: FlagSet
    """Local flags that also persist to children."""

    var flags: FlagSet
    """It is all local, persistent, and inherited flags."""

    var _inherited_flags: FlagSet
    """Cached results from self._merge_flags()."""

    var children: List[Arc[Self]]
    """Child commands."""
    var parent: Arc[Optional[Self]]
    """Parent command."""

    fn __init__(
        inout self,
        name: String,
        description: String,
        aliases: List[String] = List[String](),
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
        """
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
            persisting_pre_run: The function to run before the command is executed. This persists to children.
            persisting_post_run: The function to run after the command is executed. This persists to children.
            persisting_erroring_pre_run: The function to run before the command is executed that returns an error. This persists to children.
            persisting_erroring_post_run: The function to run after the command is executed that returns an error. This persists to children.
            help: The function to generate help text for the command.
        """
        if not run and not erroring_run:
            panic("A command must have a run or erroring_run function.")

        self.name = name
        self.description = description
        self.aliases = aliases

        self.help = help
        self.group_id = ""

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
        self.flags = FlagSet()
        self.local_flags = FlagSet()
        self.persistent_flags = FlagSet()
        self._inherited_flags = FlagSet()
        self.flags.add_bool_flag(name="help", shorthand="h", usage="Displays help information about the command.")

    # TODO: Why do we have 2 almost indentical init functions? Setting a default arg_validator value, breaks the compiler as of 24.2.
    fn __init__(
        inout self,
        name: String,
        description: String,
        arg_validator: ArgValidator,
        aliases: List[String] = List[String](),
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
        """
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
            persisting_pre_run: The function to run before the command is executed. This persists to children.
            persisting_post_run: The function to run after the command is executed. This persists to children.
            persisting_erroring_pre_run: The function to run before the command is executed that returns an error. This persists to children.
            persisting_erroring_post_run: The function to run after the command is executed that returns an error. This persists to children.
            help: The function to generate help text for the command.
        """
        if not run and not erroring_run:
            panic("A command must have a run or erroring_run function.")

        self.name = name
        self.description = description
        self.aliases = aliases

        self.help = help
        self.group_id = ""

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
        self.flags = FlagSet()
        self.local_flags = FlagSet()
        self.persistent_flags = FlagSet()
        self._inherited_flags = FlagSet()
        self.flags.add_bool_flag(name="help", shorthand="h", usage="Displays help information about the command.")

    fn __copyinit__(inout self, existing: Self):
        self.name = existing.name
        self.description = existing.description
        self.aliases = existing.aliases

        self.help = existing.help
        self.group_id = existing.group_id

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
        self.aliases = existing.aliases^

        self.help = existing.help
        self.group_id = existing.group_id^

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
        return fmt.sprintf("(Name: %s, Description: %s)", self.name, self.description)

    fn __repr__(inout self) -> String:
        var parent_name: String = ""
        if self.has_parent():
            parent_name = self.parent[].value().name
        return (
            "Name: "
            + self.name
            + "\nDescription: "
            + self.description
            + "\nArgs: "
            + self.valid_args.__str__()
            + "\nFlags: "
            + str(self.flags)
            + "\nCommands: "
            + to_string(self.children)
            + "\nParent: "
            + parent_name
        )

    fn _full_command(self) -> String:
        """Traverses up the parent command tree to build the full command as a string."""
        if self.has_parent():
            var ancestor: String = self.parent[].value()._full_command()
            return ancestor + " " + self.name
        else:
            return self.name

    fn _root(self) -> Arc[Command]:
        """Returns the root command of the command tree."""
        if self.has_parent():
            return self.parent[].value()._root()

        return self

    fn validate_flag_groups(self):
        var group_status = Dict[String, Dict[String, Bool]]()
        var one_required_group_status = Dict[String, Dict[String, Bool]]()
        var mutually_exclusive_group_status = Dict[String, Dict[String, Bool]]()

        @always_inline
        fn flag_checker(flag: Flag) capturing:
            var err = process_flag_for_group_annotation(self.flags, flag, REQUIRED_AS_GROUP, group_status)
            if err:
                panic("Failed to process flag for REQUIRED_AS_GROUP annotation: " + str(err))
            err = process_flag_for_group_annotation(self.flags, flag, ONE_REQUIRED, one_required_group_status)
            if err:
                panic("Failed to process flag for ONE_REQUIRED annotation: " + str(err))
            err = process_flag_for_group_annotation(
                self.flags, flag, MUTUALLY_EXCLUSIVE, mutually_exclusive_group_status
            )
            if err:
                panic("Failed to process flag for MUTUALLY_EXCLUSIVE annotation: " + str(err))

        self.flags.visit_all[flag_checker]()

        # Validate required flag groups
        validate_flag_groups(group_status, one_required_group_status, mutually_exclusive_group_status)

    fn execute(inout self) -> None:
        """Traverses the arguments passed to the executable and executes the last command in the branch."""
        # Traverse from the root command through the children to find a match for the current argument.
        # Any additional arguments past the last matched command name are considered arguments.
        # TODO: Tree traversal is new to me, there's probably a better way to do this.

        # Always execute from the root command, regardless of what command was executed in main.
        if self.has_parent():
            var root = self._root()
            return root[].execute()

        var remaining_args: List[String]
        var command: Self
        command, remaining_args = parse_command_from_args(self)
        var command_ref = Arc(command)

        # Merge local and inherited flags
        command_ref[]._merge_flags()

        # Add all parents to the list to check if they have persistent pre/post hooks.
        var parents = List[Self]()

        @parameter
        fn append_parents(parent: Self) capturing -> None:
            parents.append(parent)

        command_ref[].visit_parents[append_parents]()

        # If ENABLE_TRAVERSE_RUN_HOOKS is True, reverse the list to start from the root command rather than
        # from the child. This is because all of the persistent hooks will be run.
        @parameter
        if ENABLE_TRAVERSE_RUN_HOOKS:
            parents.reverse()

        # Get the flags for the command to be executed.
        # store flags as a mutable ref
        var err: Error
        remaining_args, err = get_flags(command_ref[].flags, remaining_args)
        if err:
            panic(err)

        # Check if the help flag was passed
        var help_passed = command_ref[].flags.get_as_bool("help")
        if help_passed.value() == True:
            print(command.help(command_ref))
            return None

        # Validate individual required flags (eg: flag is required)
        err = command_ref[].validate_required_flags()
        if err:
            panic(err)

        # Validate flag groups (eg: one of required, mutually exclusive, required together)
        command_ref[].validate_flag_groups()

        # Validate the remaining arguments
        var error_message = command_ref[].arg_validator(command_ref, remaining_args)
        if error_message:
            panic(error_message.value())

        # Run the persistent pre-run hooks.
        for parent in parents:
            if parent[].persistent_erroring_pre_run:
                err = parent[].persistent_erroring_pre_run.value()(command_ref, remaining_args)
                if err:
                    panic(err)

                @parameter
                if not ENABLE_TRAVERSE_RUN_HOOKS:
                    break
            else:
                if parent[].persistent_pre_run:
                    parent[].persistent_pre_run.value()(command_ref, remaining_args)

                    @parameter
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
            if parent[].persistent_erroring_post_run:
                err = parent[].persistent_erroring_post_run.value()(command_ref, remaining_args)
                if err:
                    panic(err)

                @parameter
                if not ENABLE_TRAVERSE_RUN_HOOKS:
                    break
            else:
                if parent[].persistent_post_run:
                    parent[].persistent_post_run.value()(command_ref, remaining_args)

                    @parameter
                    if not ENABLE_TRAVERSE_RUN_HOOKS:
                        break

        # Run the post-run hooks.
        if command_ref[].post_run:
            command.post_run.value()(command_ref, remaining_args)
        elif command_ref[].erroring_post_run:
            err = command.erroring_post_run.value()(command_ref, remaining_args)
            if err:
                panic(err)

    fn inherited_flags(self) -> FlagSet:
        """Returns the flags for the command and inherited flags from its parent.

        Returns:
            The flags for the command and its parent.
        """
        var i_flags = FlagSet()

        @always_inline
        fn add_parent_persistent_flags(parent: Self) capturing -> None:
            if parent.persistent_flags:
                i_flags += parent.persistent_flags

        self.visit_parents[add_parent_persistent_flags]()

        return i_flags

    fn _merge_flags(inout self):
        """Returns all flags for the command and inherited flags from its parent."""
        # Set mutability of flag set by initializing it as a var.
        self.flags += self.persistent_flags
        self._inherited_flags = self.inherited_flags()
        self.flags += self._inherited_flags

    fn add_command(inout self: Self, inout command: Arc[Command]):
        """Adds child command and set's child's parent attribute to self.

        Args:
            command: The command to add as a child of self.
        """
        var cmd = command
        self.children.append(command)
        cmd[].parent = self

    fn mark_flag_required(inout self, flag_name: String) -> None:
        """Marks the given flag with annotations so that Prism errors
        if the command is invoked without the flag.

        Args:
            flag_name: The name of the flag to mark as required.
        """
        var err = self.flags.set_annotation(flag_name, REQUIRED, List[String]("true"))
        if err:
            panic(err)

    fn mark_flags_required_together(inout self, *flag_names: String) -> None:
        """Marks the given flags with annotations so that Prism errors
        if the command is invoked with a subset (but not all) of the given flags.

        Args:
            flag_names: The names of the flags to mark as required together.
        """
        self._merge_flags()
        for flag_name in flag_names:
            var maybe_flag = self.flags.lookup(flag_name[])
            if not maybe_flag:
                panic(fmt.sprintf("Failed to find flag %s and mark it as being required in a flag group", flag_name[]))

            var flag = maybe_flag.value()
            var result = get_flag_names(flag_names)

            flag[].annotations[REQUIRED_AS_GROUP] = List[String](result)
            var err = self.flags.set_annotation(
                flag_name[], REQUIRED_AS_GROUP, flag[].annotations.get(REQUIRED_AS_GROUP, List[String]())
            )
            if err:
                panic(err)

    fn mark_flags_one_required(inout self, *flag_names: String) -> None:
        """Marks the given flags with annotations so that Prism errors
        if the command is invoked without at least one flag from the given set of flags.

        Args:
            flag_names: The names of the flags to mark as required.
        """
        self._merge_flags()
        for flag_name in flag_names:
            var maybe_flag = self.flags.lookup(flag_name[])
            if not maybe_flag:
                panic(
                    fmt.sprintf("Failed to find flag %s and mark it as being in a one-required flag group", flag_name[])
                )

            var flag = maybe_flag.value()
            var result = get_flag_names(flag_names)

            flag[].annotations[ONE_REQUIRED] = result
            var err = self.flags.set_annotation(
                flag_name[], ONE_REQUIRED, flag[].annotations.get(ONE_REQUIRED, List[String]())
            )
            if err:
                panic(err)

    fn mark_flags_mutually_exclusive(inout self, *flag_names: String) -> None:
        """Marks the given flags with annotations so that Prism errors
        if the command is invoked with more than one flag from the given set of flags.

        Args:
            flag_names: The names of the flags to mark as mutually exclusive.
        """
        self._merge_flags()
        for flag_name in flag_names:
            var maybe_flag = self.flags.lookup(flag_name[])
            if not maybe_flag:
                panic(
                    fmt.sprintf(
                        "Failed to find flag %s and mark it as being in a mutually exclusive flag group", flag_name[]
                    )
                )

            var flag = maybe_flag.value()
            var result = get_flag_names(flag_names)
            flag[].annotations[MUTUALLY_EXCLUSIVE] = result
            var err = self.flags.set_annotation(
                flag_name[], MUTUALLY_EXCLUSIVE, flag[].annotations.get(MUTUALLY_EXCLUSIVE, List[String]())
            )
            if err:
                panic(err)

    fn mark_persistent_flag_required(inout self, flag_name: String) -> None:
        """Marks the given persistent flag with annotations so that Prism errors
        if the command is invoked without the flag.

        Args:
            flag_name: The name of the flag to mark as required.
        """
        # self._merge_flags()
        var err = self.persistent_flags.set_annotation(flag_name, REQUIRED, List[String]("true"))
        if err:
            panic(err)

    fn has_parent(self) -> Bool:
        """Returns True if the command has a parent, False otherwise."""
        return self.parent[].__bool__()

    fn visit_parents[func: ParentVisitorFn](self) -> None:
        """Visits all parents of the command and invokes func on each parent.

        Params:
            func: The function to invoke on each parent.
        """
        if self.has_parent():
            func(self.parent[].value())
            self.parent[].value().visit_parents[func]()

    fn validate_required_flags(self) -> Error:
        """Validates all required flags are present and returns an error otherwise."""
        var missing_flag_names = List[String]()

        fn check_required_flag(flag: Flag) capturing -> None:
            var required_annotation = flag.annotations.get(REQUIRED, List[String]())
            if required_annotation:
                if required_annotation[0] == "true" and not flag.changed:
                    missing_flag_names.append(flag.name)

        self.flags.visit_all[check_required_flag]()

        if len(missing_flag_names) > 0:
            return Error("required flag(s) " + missing_flag_names.__str__() + " not set")
        return Error()
