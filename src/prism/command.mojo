from sys import argv, stdin
from sys.param_env import env_get_bool
from builtin.io import _fdopen
from memory import ArcPointer
import mog
from prism._util import panic
from prism._arg_parse import parse_args_from_command_line, parse_args_from_stdin
from prism.flag import Flag, FType
from prism._flag_set import Annotation, FlagSet
from prism.args import arbitrary_args, ArgValidatorFn
from prism.context import Context
from prism.suggest import suggest_flag, flag_from_error
from prism.help import Help
from prism.version import Version
from prism.exit import ExitFn, default_exit
from prism.writer import WriterFn, default_error_writer, default_output_writer


alias CmdFn = fn (ctx: Context) -> None
"""The function for a command to run."""
alias RaisingCmdFn = fn (ctx: Context) raises -> None
"""The function for a command to run that can error."""
alias ParentVisitorFn = fn (parent: ArcPointer[Command]) capturing -> None
"""The function for visiting parents of a command."""


alias ENABLE_TRAVERSE_RUN_HOOKS = env_get_bool["PRISM_TRAVERSE_RUN_HOOKS", False]()
"""Set to True to traverse all parents' persistent pre and post run hooks. If False, it'll only run the first match.
If False, starts from the child command and goes up the parent chain. If True, starts from root and goes down."""


@value
struct Command(CollectionElement, Writable, Stringable):
    """A struct representing a command that can be executed from the command line.

    ```mojo
    from memory import ArcPointer
    from prism import Command, Context

    fn test(ctx: Context) -> None:
        print("Hello from Chromeria!")

    fn main():
        command = Command(
            name="hello",
            usage="This is a dummy command!",
            run=test,
        )
        command.execute()
    ```

    Then execute the command by running the mojo file or binary.
    ```sh
    > mojo run hello.mojo
    Hello from Chromeria!
    ```
    """

    var name: String
    """The name of the command."""
    var usage: String
    """Description of the command."""
    var args_usage: Optional[String]
    """The usage of the arguments for the command. This is used to generate help text."""
    var aliases: List[String]
    """Aliases that can be used instead of the first word in name."""

    var help: Optional[Help]
    """Help information for the command."""
    var version: Optional[Version]
    """Version information for the command."""
    var exit: ExitFn
    """Function to call when an error occurs."""
    var output_writer: WriterFn
    """Function to call when writing output."""
    var error_writer: WriterFn
    """Function to call when writing errors."""

    var pre_run: Optional[CmdFn]
    """A function to run before the run function is executed."""
    var run: Optional[CmdFn]
    """A function to run when the command is executed."""
    var post_run: Optional[CmdFn]
    """A function to run after the run function is executed."""

    var raising_pre_run: Optional[RaisingCmdFn]
    """A raising function to run before the run function is executed."""
    var raising_run: Optional[RaisingCmdFn]
    """A raising function to run when the command is executed."""
    var raising_post_run: Optional[RaisingCmdFn]
    """A raising function to run after the run function is executed."""

    var persistent_pre_run: Optional[CmdFn]
    """A function to run before the run function is executed. This persists to children."""
    var persistent_post_run: Optional[CmdFn]
    """A function to run after the run function is executed. This persists to children."""

    var persistent_raising_pre_run: Optional[RaisingCmdFn]
    """A raising function to run before the run function is executed. This persists to children."""
    var persistent_raising_post_run: Optional[RaisingCmdFn]
    """A raising function to run after the run function is executed. This persists to children."""

    var arg_validator: ArgValidatorFn
    """Function to validate arguments passed to the command."""
    var valid_args: List[String]
    """Valid arguments for the command."""

    var flags: FlagSet
    """It is all local, persistent, and inherited flags."""

    var children: List[ArcPointer[Self]]
    """Child commands."""
    # TODO: An optional pointer would be great, but it breaks the compiler. So a list of 0-1 pointers is used.
    var parent: List[ArcPointer[Self]]
    """Parent command."""

    var read_from_stdin: Bool
    """If True, the command will read args from stdin as well."""
    var suggest: Bool
    """If True, the command will suggest flags when an unknown flag is passed."""

    fn __init__(
        out self,
        name: String,
        usage: String,
        *,
        args_usage: Optional[String] = None,
        aliases: List[String] = List[String](),
        help: Optional[Help] = Help(),
        version: Optional[Version] = None,
        exit: ExitFn = default_exit,
        output_writer: WriterFn = default_output_writer,
        error_writer: WriterFn = default_error_writer,
        valid_args: List[String] = List[String](),
        children: List[ArcPointer[Self]] = List[ArcPointer[Self]](),
        run: Optional[CmdFn] = None,
        pre_run: Optional[CmdFn] = None,
        post_run: Optional[CmdFn] = None,
        raising_run: Optional[RaisingCmdFn] = None,
        raising_pre_run: Optional[RaisingCmdFn] = None,
        raising_post_run: Optional[RaisingCmdFn] = None,
        persistent_pre_run: Optional[CmdFn] = None,
        persistent_post_run: Optional[CmdFn] = None,
        persistent_raising_pre_run: Optional[RaisingCmdFn] = None,
        persistent_raising_post_run: Optional[RaisingCmdFn] = None,
        flags: FlagSet = FlagSet(),
        flags_required_together: Optional[List[String]] = None,
        mutually_exclusive_flags: Optional[List[String]] = None,
        one_required_flags: Optional[List[String]] = None,
        arg_validator: Optional[ArgValidatorFn] = None,
        read_from_stdin: Bool = False,
        suggest: Bool = False,
    ):
        """Constructs a new `Command`.

        Args:
            name: The name of the command.
            usage: The usage of the command.
            args_usage: The usage of the arguments for the command.
            aliases: The aliases for the command.
            help: The help information for the command.
            version: The version of the command.
            exit: The function to call when an error occurs.
            output_writer: The function to call when writing output.
            error_writer: The function to call when writing errors.
            valid_args: The valid arguments for the command.
            children: The child commands.
            run: The function to run when the command is executed.
            pre_run: The function to run before the command is executed.
            post_run: The function to run after the command is executed.
            raising_run: The function to run when the command is executed that returns an error.
            raising_pre_run: The function to run before the command is executed that returns an error.
            raising_post_run: The function to run after the command is executed that returns an error.
            persistent_pre_run: The function to run before the command is executed. This persists to children.
            persistent_post_run: The function to run after the command is executed. This persists to children.
            persistent_raising_pre_run: The function to run before the command is executed that returns an error. This persists to children.
            persistent_raising_post_run: The function to run after the command is executed that returns an error. This persists to children.
            flags: The flags for the command.
            flags_required_together: The flags that are required together.
            mutually_exclusive_flags: The flags that are mutually exclusive.
            one_required_flags: The flags where at least one is required.
            arg_validator: The function to validate arguments passed to the command.
            read_from_stdin: If True, the command will read args from stdin as well.
            suggest: If True, the command will suggest flags when an unknown flag is passed.
        """
        # TODO: Maybe this should just raise instead of exiting, but it's not really a recoverable error?
        if not run and not raising_run:
            panic("A command must have a run or raising_run function.")

        self.name = name
        self.usage = usage
        self.args_usage = args_usage
        self.aliases = aliases

        self.exit = exit
        self.help = help
        self.version = version
        self.output_writer = output_writer
        self.error_writer = error_writer

        self.pre_run = pre_run
        self.run = run
        self.post_run = post_run

        self.raising_pre_run = raising_pre_run
        self.raising_run = raising_run
        self.raising_post_run = raising_post_run

        self.persistent_pre_run = persistent_pre_run
        self.persistent_post_run = persistent_post_run
        self.persistent_raising_pre_run = persistent_raising_pre_run
        self.persistent_raising_post_run = persistent_raising_post_run
        self.read_from_stdin = read_from_stdin
        self.suggest = suggest

        if arg_validator:
            self.arg_validator = arg_validator.value()
        else:
            self.arg_validator = arbitrary_args

        self.valid_args = valid_args

        self.flags = flags

        # TODO: Again, panic is not ideal. I may need to change the constructor to be raising instead of exiting.
        if help:
            if help.value().flag.type != FType.Bool:
                panic("Help flag must be a Boolean flag.")
            self.flags.append(help.value().flag)
        if version:
            if version.value().flag.type != FType.Bool:
                panic("Version flag must be a Boolean flag.")
            self.flags.append(version.value().flag)

        self.parent = List[ArcPointer[Self]](capacity=1)
        self.children = children
        for command in children:
            if command[][].parent:
                command[][].parent[0] = self
            else:
                command[][].parent.append(self)

        if flags_required_together:
            self._mark_flag_group_as[Annotation.REQUIRED_AS_GROUP](flags_required_together.value())
        if mutually_exclusive_flags:
            self._mark_flag_group_as[Annotation.MUTUALLY_EXCLUSIVE](mutually_exclusive_flags.value())
        if one_required_flags:
            self._mark_flag_group_as[Annotation.ONE_REQUIRED](one_required_flags.value())

    fn __moveinit__(out self, owned existing: Self):
        """Initializes a new `Command` by moving the fields from an existing `Command`.

        Args:
            existing: The existing `Command` to move the fields from.
        """
        self.name = existing.name^
        self.usage = existing.usage^
        self.args_usage = existing.args_usage^
        self.aliases = existing.aliases^

        self.help = existing.help
        self.exit = existing.exit
        self.version = existing.version^
        self.output_writer = existing.output_writer
        self.error_writer = existing.error_writer

        self.pre_run = existing.pre_run^
        self.run = existing.run^
        self.post_run = existing.post_run^

        self.raising_pre_run = existing.raising_pre_run^
        self.raising_run = existing.raising_run^
        self.raising_post_run = existing.raising_post_run^

        self.persistent_pre_run = existing.persistent_pre_run^
        self.persistent_post_run = existing.persistent_post_run^
        self.persistent_raising_pre_run = existing.persistent_raising_pre_run^
        self.persistent_raising_post_run = existing.persistent_raising_post_run^

        self.read_from_stdin = existing.read_from_stdin
        self.suggest = existing.suggest

        self.arg_validator = existing.arg_validator
        self.valid_args = existing.valid_args^
        self.flags = existing.flags^

        self.children = existing.children^
        self.parent = existing.parent^

    fn __str__(self) -> String:
        """Returns a string representation of the `Command`.

        Returns:
            The string representation of the `Command`.
        """
        return String.write(self)

    fn write_to[W: Writer, //](self, mut writer: W):
        """Write Flag string representation to a `Writer`.

        Parameters:
            W: The type of writer to write to.

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
        writer.write(", usage: ")
        writer.write(self.usage)

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

    fn full_name(self) -> String:
        """Traverses up the parent command tree to build the full command as a string.

        Returns:
            The full command name.
        """
        if self.has_parent():
            return String.write(self.parent[0][].full_name(), " ", self.name)
        else:
            return self.name

    fn root(self) -> ArcPointer[Command]:
        """Returns the root command of the command tree.

        Returns:
            The root command in the tree.
        """
        if self.has_parent():
            return self.parent[0][].root()
        return self

    fn _parse_command(
        self, command: Self, arg: String, children: List[ArcPointer[Self]], mut leftover_start: Int
    ) -> (Self, List[ArcPointer[Self]]):
        """Traverses the command tree to find the command that matches the given argument.

        Args:
            command: The current command being traversed.
            arg: The argument to match against the command name or aliases.
            children: The children of the current command.
            leftover_start: The index to start the remaining arguments at.

        Returns:
            The command that matches the argument and the remaining children to traverse.
        """
        var argument = String(arg)
        for cmd in children:
            if cmd[][].name == argument or argument in cmd[][].aliases:
                leftover_start += 1
                return cmd[][], cmd[][].children

        return command, children

    fn _parse_command_from_args(self, args: List[String]) -> (Self, List[String]):
        """Traverses the command tree to find the command that matches the given arguments.

        Args:
            args: The arguments to traverse the command tree with.

        Returns:
            The command that matches the arguments and the remaining arguments to pass to that command.
        """
        # If there's no children, then the root command is used.
        if not self.children or not args:
            return self, args

        var command = self
        var children = self.children
        var leftover_start = 0  # Start at 1 to start slice at the first remaining arg, not the last child command.
        for arg in args:
            command, children = self._parse_command(command, arg[], children, leftover_start)

        if leftover_start == 0:
            return self, args

        # If the there are more or equivalent args to the index, then there are remaining args to pass to the command.
        var remaining_args = List[String]()
        if len(args) >= leftover_start:
            remaining_args = args[leftover_start : len(args)]

        return command, remaining_args^

    fn _execute_pre_run_hooks(self, ctx: Context, parents: List[ArcPointer[Self]]) raises -> None:
        """Runs the pre-run hooks for the command.

        Args:
            ctx: The context of the command being executed.
            parents: The parents of the command to check for persistent pre-run hooks.

        Raises:
            Any error that occurs while running the pre-run hooks.
        """
        try:
            # Run the persistent pre-run hooks.
            for parent in parents:
                if parent[][].persistent_raising_pre_run:
                    parent[][].persistent_raising_pre_run.value()(ctx)

                    @parameter
                    if not ENABLE_TRAVERSE_RUN_HOOKS:
                        break
                else:
                    if parent[][].persistent_pre_run:
                        parent[][].persistent_pre_run.value()(ctx)

                        @parameter
                        if not ENABLE_TRAVERSE_RUN_HOOKS:
                            break

            # Run the pre-run hooks.
            if ctx.command[].pre_run:
                ctx.command[].pre_run.value()(ctx)
            elif ctx.command[].raising_pre_run:
                ctx.command[].raising_pre_run.value()(ctx)
        except e:
            self.error_writer("Failed to run pre-run hooks for command: " + ctx.command[].name)
            raise e

    fn _execute_post_run_hooks(self, ctx: Context, parents: List[ArcPointer[Self]]) raises -> None:
        """Runs the post-run hooks for the command.

        Args:
            ctx: The context of the command being executed.
            parents: The parents of the command to check for persistent post-run hooks.

        Raises:
            Any error that occurs while running the post-run hooks.
        """
        try:
            # Run the persistent post-run hooks.
            for parent in parents:
                if parent[][].persistent_raising_post_run:
                    parent[][].persistent_raising_post_run.value()(ctx)

                    @parameter
                    if not ENABLE_TRAVERSE_RUN_HOOKS:
                        break
                else:
                    if parent[][].persistent_post_run:
                        parent[][].persistent_post_run.value()(ctx)

                        @parameter
                        if not ENABLE_TRAVERSE_RUN_HOOKS:
                            break

            # Run the post-run hooks.
            if ctx.command[].post_run:
                ctx.command[].post_run.value()(ctx)
            elif ctx.command[].raising_post_run:
                ctx.command[].raising_post_run.value()(ctx)
        except e:
            self.error_writer("Failed to run post-run hooks for command: " + ctx.command[].name)
            raise e

    fn execute(self) -> None:
        """Traverses the arguments passed to the executable and executes the last command in the branch."""
        # Traverse from the root command through the children to find a match for the current argument.
        # Any additional arguments past the last matched command name are considered arguments.
        # TODO: Tree traversal is new to me, there's probably a better way to do this.

        # Always execute from the root command, regardless of what command was executed in main.
        if self.has_parent():
            return self.root()[].execute()

        var input_args = parse_args_from_command_line(argv())

        # Read from stdin and parse the arguments.
        if self.read_from_stdin:
            try:
                # TODO: Switch from readline to reading until EOF
                input_args.extend(parse_args_from_stdin(_fdopen["r"](stdin).readline()))
            except e:
                # TODO: The compiler doesn't like just having the exit function.
                # In case the user provided exit function does NOT exit, we return early since we have no input args.
                self.exit("Failed to read from stdin: " + String(e))
                return

        command, args = self._parse_command_from_args(input_args)
        var command_ptr = ArcPointer(command^)  # Give ownership to the pointer, for consistency.

        # Merge persistent flags from ancestors.
        command_ptr[]._merge_flags()

        # Add all parents to the list to check if they have persistent pre/post hooks.
        var parents = List[ArcPointer[Self]]()

        @parameter
        fn append_parents(parent: ArcPointer[Self]) capturing -> None:
            parents.append(parent)

        command_ptr[].visit_parents[append_parents]()

        # If ENABLE_TRAVERSE_RUN_HOOKS is True, reverse the list to start from the root command rather than
        # from the child. This is because all of the persistent hooks will be run.
        @parameter
        if ENABLE_TRAVERSE_RUN_HOOKS:
            parents.reverse()

        var remaining_args: List[String]
        try:
            # Parse the flags for the command to be executed.
            remaining_args = command_ptr[].flags.from_args(args)
        except e:
            # TODO: Move the suggestion checking into a separate function.
            if not self.suggest:
                self.exit(e)
                return

            var flag_name = flag_from_error(e)
            if not flag_name:
                self.exit(e)
                return

            var suggestion = suggest_flag(command_ptr[].flags.flags, flag_name.value())
            if suggestion == "":
                self.exit(e)
                return

            self.error_writer(String("Unknown flag: ", flag_name.value(), "\nDid you mean: ", suggestion))
            return

        try:
            var ctx = Context(remaining_args, command_ptr)

            # Check if the help flag was passed
            if self.help:
                if command_ptr[].flags.get_bool(self.help.value().flag.name):
                    self.output_writer(self.help.value().action(ctx))
                    return

            # Check if the version flag was passed
            if self.version:
                # Check if version is set (not None) and if so, the value must be True.
                var version_flag_passed = command_ptr[].flags.get_bool(self.version.value().flag.name)
                if version_flag_passed and version_flag_passed.value() == True:
                    self.output_writer(self.version.value().action(ctx))
                    return

            # Validate individual required flags (eg: flag is required)
            command_ptr[].flags.validate_required_flags()

            # Validate flag groups (eg: one of required, mutually exclusive, required together)
            command_ptr[].flags.validate_flag_groups()

            # Run flag actions if they have any
            @parameter
            fn run_action(flag: Flag) raises -> None:
                if flag.action and flag.value:
                    flag.action.value()(ctx, flag.value.value())

            command_ptr[].flags.visit_all[run_action]()

            # Validate the remaining arguments
            command_ptr[].arg_validator(ctx)

            # Run the function's commands.
            self._execute_pre_run_hooks(ctx, parents)
            if command_ptr[].run:
                command_ptr[].run.value()(ctx)
            else:
                command_ptr[].raising_run.value()(ctx)
            self._execute_post_run_hooks(ctx, parents)
        except e:
            self.exit(e)

    fn inherited_flags(self) -> FlagSet:
        """Returns the flags for the command and inherited flags from its parent.

        Returns:
            The flags for the command and its parent.
        """
        var flags = List[Flag]()

        @parameter
        fn add_parent_persistent_flags(parent: ArcPointer[Self]) capturing -> None:
            for flag in parent[].flags:
                if flag[].persistent:
                    flags.append(flag[])

        self.visit_parents[add_parent_persistent_flags]()
        return FlagSet(flags^)

    fn _merge_flags(mut self):
        """Returns all flags for the command and inherited flags from its parent."""
        self.flags.extend(self.inherited_flags())

    fn _mark_flag_group_as[annotation: Annotation](mut self, flag_names: List[String]) -> None:
        """Marks the given flags with annotations so that `Prism` errors

        Parameters:
            annotation: The annotation to set on the flags.

        Args:
            flag_names: The names of the flags to mark as required together.

        #### Notes:
        - If the annotation is `REQUIRED_AS_GROUP`, then all the flags in the group must be set.
        - If the annotation is `ONE_REQUIRED`, then at least one flag in the group must be set.
        - If the annotation is `MUTUALLY_EXCLUSIVE`, then only one flag in the group can be set.
        """
        self._merge_flags()
        try:
            for name in flag_names:
                self.flags.set_annotation[annotation](name[], StaticString(" ").join(flag_names))
        except e:
            self.exit(e)

    fn has_parent(self) -> Bool:
        """Returns True if the command has a parent, False otherwise.

        Returns:
            True if the command has a parent, False otherwise.
        """
        return Bool(self.parent)

    fn visit_parents[func: ParentVisitorFn](self) -> None:
        """Visits all parents of the command and invokes func on each parent.

        Parameters:
            func: The function to invoke on each parent.
        """
        if self.has_parent():
            func(self.parent[0][])
            self.parent[0][].visit_parents[func]()
