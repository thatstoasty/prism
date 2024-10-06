from sys import argv
from collections import Optional, Dict
from memory.arc import Arc
import mog
import gojo.fmt
from gojo.strings import StringBuilder
from .util import panic, to_string, to_list
from .flag import Flag
from .flag_set import FlagSet, validate_required_flags, REQUIRED, REQUIRED_AS_GROUP, ONE_REQUIRED, MUTUALLY_EXCLUSIVE
from .flag_group import validate_flag_groups
from .args import arbitrary_args, get_args


fn concat_names(flag_names: VariadicListMem[String, _]) -> String:
    var result = String()
    var writer = result._unsafe_to_formatter()
    for i in range(len(flag_names)):
        writer.write(flag_names[i])
        if i != len(flag_names) - 1:
            writer.write(" ")

    return result


fn get_args_as_list() -> List[String]:
    """Returns the arguments passed to the executable as a list of strings."""
    var args = argv()
    var result = List[String](capacity=len(args))
    for arg in args:
        result.append(arg)

    return result


alias NEWLINE = ord("\n")


fn default_help(inout command: Arc[Command]) -> String:
    """Prints the help information for the command.
    TODO: Add padding for commands, options, and aliases.
    """
    var description_style = mog.Style().border(mog.HIDDEN_BORDER)
    var border_style = mog.Style().border(mog.ROUNDED_BORDER).border_foreground(mog.Color(0x383838)).padding(0, 1)
    var option_style = mog.Style().foreground(mog.Color(0x81C8BE))
    var bold_style = mog.Style().bold()

    var cmd = command
    var builder = StringBuilder()
    _ = builder.write_string(mog.Style().bold().foreground(mog.Color(0xE5C890)).render("Usage: "))
    _ = builder.write_string(bold_style.render(cmd[]._full_command()))

    if len(cmd[].flags) > 0:
        _ = builder.write_string(" [OPTIONS]")
    if len(cmd[].children) > 0:
        _ = builder.write_string(" COMMAND")
    _ = builder.write_string(" [ARGS]...")

    var description = description_style.render(mog.join_vertical(mog.left, str(builder), "\n", cmd[].description))

    builder = StringBuilder()
    if cmd[].flags.flags:
        _ = builder.write_string(bold_style.render("Options"))
        for flag in cmd[].flags.flags:
            _ = builder.write_string(option_style.render(fmt.sprintf("\n-%s, --%s", flag[].shorthand, flag[].name)))
            _ = builder.write_string(fmt.sprintf("    %s", flag[].usage))
    var options = border_style.render(str(builder))

    builder = StringBuilder()
    if cmd[].children:
        _ = builder.write_string(bold_style.render("Commands"))
        for i in range(len(cmd[].children)):
            _ = builder.write_string(
                fmt.sprintf(
                    "\n%s    %s", option_style.render(cmd[].children[i][].name), cmd[].children[i][].description
                )
            )

            if i == len(cmd[].children) - 1:
                _ = builder.write_byte(NEWLINE)

    if cmd[].aliases:
        _ = builder.write_string(bold_style.render("Aliases"))
        _ = builder.write_string(fmt.sprintf("\n%s", option_style.render(cmd[].aliases.__str__())))

    var commands = border_style.render(str(builder))
    return mog.join_vertical(mog.left, description, options, commands)


alias CommandArc = Arc[Command]
alias CommandFunction = fn (inout command: Arc[Command], args: List[String]) -> None
"""The function for a command to run."""
alias CommandFunctionErr = fn (inout command: Arc[Command], args: List[String]) raises -> None
"""The function for a command to run that can error."""
alias HelpFunction = fn (inout command: Arc[Command]) -> String
"""The function for a help function."""
alias ArgValidator = fn (inout command: Arc[Command], args: List[String]) raises -> None
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

    fn test(inout command: Arc[Command], args: List[String]) -> None:
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

    fn __moveinit__(inout self, owned existing: Self):
        self.name = existing.name^
        self.description = existing.description^
        self.aliases = existing.aliases^

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

        self.arg_validator = existing.arg_validator
        self.valid_args = existing.valid_args^
        self.flags = existing.flags^
        self.local_flags = existing.local_flags^
        self.persistent_flags = existing.persistent_flags^
        self._inherited_flags = existing._inherited_flags^

        self.children = existing.children^
        self.parent = existing.parent^

    fn __str__(self) -> String:
        var output = String()
        var writer = output._unsafe_to_formatter()
        self.format_to(writer)
        return output

    fn format_to(self, inout writer: Formatter):
        """Write Flag string representation to a `Formatter`.

        Args:
            writer: The formatter to write to.
        """

        @parameter
        fn write_optional(opt: Optional[String]):
            if opt:
                writer.write(repr(opt.value()))
            else:
                writer.write(repr(None))

        writer.write("Command(Name: ")
        writer.write(self.name)
        writer.write(", Description: ")
        writer.write(self.description)

        if self.aliases:
            writer.write(", Aliases: ")
            writer.write(self.aliases.__str__())

        if self.valid_args:
            writer.write(", Valid Args: ")
            writer.write(self.valid_args.__str__())
        if self.flags:
            writer.write(", Flags: ")
            writer.write(self.flags)
        writer.write(")")

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

    fn _execute_pre_run_hooks(
        self, inout command: Arc[Command], parents: List[Command], args: List[String]
    ) raises -> None:
        """Runs the pre-run hooks for the command."""
        try:
            # Run the persistent pre-run hooks.
            for parent in parents:
                if parent[].persistent_erroring_pre_run:
                    parent[].persistent_erroring_pre_run.value()(command, args)

                    @parameter
                    if not ENABLE_TRAVERSE_RUN_HOOKS:
                        break
                else:
                    if parent[].persistent_pre_run:
                        parent[].persistent_pre_run.value()(command, args)

                        @parameter
                        if not ENABLE_TRAVERSE_RUN_HOOKS:
                            break

            # Run the pre-run hooks.
            if command[].pre_run:
                command[].pre_run.value()(command, args)
            elif command[].erroring_pre_run:
                command[].erroring_pre_run.value()(command, args)
        except e:
            print("Failed to run pre-run hooks for command: " + command[].name)
            raise e

    fn _execute_post_run_hooks(
        self, inout command: Arc[Command], parents: List[Command], args: List[String]
    ) raises -> None:
        """Runs the pre-run hooks for the command."""
        try:
            # Run the persistent post-run hooks.
            for parent in parents:
                if parent[].persistent_erroring_post_run:
                    parent[].persistent_erroring_post_run.value()(command, args)

                    @parameter
                    if not ENABLE_TRAVERSE_RUN_HOOKS:
                        break
                else:
                    if parent[].persistent_post_run:
                        parent[].persistent_post_run.value()(command, args)

                        @parameter
                        if not ENABLE_TRAVERSE_RUN_HOOKS:
                            break

            # Run the post-run hooks.
            if command[].post_run:
                command[].post_run.value()(command, args)
            elif command[].erroring_post_run:
                command[].erroring_post_run.value()(command, args)
        except e:
            print("Failed to run post-run hooks for command: " + command[].name, file=2)
            raise e

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
        try:
            remaining_args = command_ref[].flags.from_args(remaining_args)
        except e:
            panic(e)

        # Check if the help flag was passed
        var help_passed = command_ref[].flags.get_as_bool("help")
        if help_passed.value() == True:
            print(command_ref[].help(command_ref))
            return None

        try:
            # Validate individual required flags (eg: flag is required)
            validate_required_flags(command_ref[].flags)
            # Validate flag groups (eg: one of required, mutually exclusive, required together)
            validate_flag_groups(command_ref[].flags)
            # Validate the remaining arguments
            command_ref[].arg_validator(command_ref, remaining_args)

            # Run the function's commands.
            self._execute_pre_run_hooks(command_ref, parents, remaining_args)
            if command_ref[].run:
                command_ref[].run.value()(command_ref, remaining_args)
            else:
                command_ref[].erroring_run.value()(command_ref, remaining_args)
            self._execute_post_run_hooks(command_ref, parents, remaining_args)
        except e:
            panic(e)

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
        self.flags += self.persistent_flags
        self._inherited_flags = self.inherited_flags()
        self.flags += self._inherited_flags

    fn add_subcommand(inout self: Self, inout command: Arc[Command]):
        """Adds child command and set's child's parent attribute to self.

        Args:
            command: The command to add as a child of self.
        """
        self.children.append(command)
        command[].parent = self

    fn mark_flag_required(inout self, flag_name: String) -> None:
        """Marks the given flag with annotations so that Prism errors
        if the command is invoked without the flag.

        Args:
            flag_name: The name of the flag to mark as required.
        """
        try:
            self.flags.set_required(flag_name)
        except e:
            panic(e)

    fn mark_flags_required_together(inout self, *flag_names: String) -> None:
        """Marks the given flags with annotations so that Prism errors
        if the command is invoked with a subset (but not all) of the given flags.

        Args:
            flag_names: The names of the flags to mark as required together.
        """
        self._merge_flags()
        var names = concat_names(flag_names)

        try:
            for flag_name in flag_names:
                self.flags.set_as[REQUIRED_AS_GROUP](flag_name[], names)
        except e:
            panic(e)

    fn mark_flags_one_required(inout self, *flag_names: String) -> None:
        """Marks the given flags with annotations so that Prism errors
        if the command is invoked without at least one flag from the given set of flags.

        Args:
            flag_names: The names of the flags to mark as required.
        """
        self._merge_flags()
        var names = concat_names(flag_names)
        try:
            for flag_name in flag_names:
                self.flags.set_as[ONE_REQUIRED](flag_name[], names)
        except e:
            panic(e)

    fn mark_flags_mutually_exclusive(inout self, *flag_names: String) -> None:
        """Marks the given flags with annotations so that Prism errors
        if the command is invoked with more than one flag from the given set of flags.

        Args:
            flag_names: The names of the flags to mark as mutually exclusive.
        """
        self._merge_flags()
        var names = concat_names(flag_names)

        try:
            for flag_name in flag_names:
                self.flags.set_as[MUTUALLY_EXCLUSIVE](flag_name[], names)
        except e:
            panic(e)

    fn mark_persistent_flag_required(inout self, flag_name: String) -> None:
        """Marks the given persistent flag with annotations so that Prism errors
        if the command is invoked without the flag.

        Args:
            flag_name: The name of the flag to mark as required.
        """
        try:
            self.persistent_flags.set_required(flag_name)
        except e:
            panic(e)

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
