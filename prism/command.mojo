from io.io import _fdopen
from sys import argv, env_get_bool, stdin

from memory import ArcPointer, OwnedPointer
from prism._arg_parse import parse_args_from_command_line, parse_args_from_stdin
from prism._flag_set import Annotation, FlagSet
from prism._util import panic
from prism.args import ArgValidatorFn, arbitrary_args
from prism.exit import ExitFn, default_exit
from prism.flag import Flag
from prism.help import Help
from prism.suggest import flag_from_error, suggest_flag
from prism.version import Version
from prism.writer import WriterFn, default_error_writer, default_output_writer


alias ENABLE_TRAVERSE_RUN_HOOKS = env_get_bool["PRISM_TRAVERSE_RUN_HOOKS", False]()
"""Set to True to traverse all parents' persistent pre and post run hooks. If False, it'll only run the first match.
If False, starts from the child command and goes up the parent chain. If True, starts from root and goes down."""


alias CmdFn = fn (args: List[String], flags: FlagSet) -> None
"""The function for a command to run."""
alias RaisingCmdFn = fn (args: List[String], flags: FlagSet) raises -> None
"""The function for a command to run that can error."""
alias ParentVisitorFn = fn (Command) capturing -> None
"""The function for visiting parents of a command."""
alias RaisingParentVisitorFn = fn (Command) capturing raises -> None
"""The function for visiting parents of a command."""


fn _parse_command(owned command: Command, arg: StringSlice, mut leftover_start: Int) -> Command:
    """Traverses the command tree to find the command that matches the given argument.

    Args:
        command: The current command being traversed.
        arg: The argument to match against the command name or aliases.
        leftover_start: The index to start the remaining arguments at.

    Returns:
        The command that matches the argument.
    """
    var argument = String(arg)
    for cmd in command.children:
        if cmd[].name == argument or argument in cmd[].aliases:
            leftover_start += 1
            return cmd[]

    return command^


fn _parse_command_from_args(owned command: Command, owned args: List[String]) -> (Command, List[String]):
    """Traverses the command tree to find the command that matches the given arguments.

    Args:
        command: The root command to start traversing from.
        args: The arguments to traverse the command tree with.

    Returns:
        The command that matches the arguments and the remaining arguments to pass to that command.
    """
    # If there's no children, then the root command is used.
    if not command.children or not args:
        return command^, args^

    var leftover_start = 0  # Start at 1 to start slice at the first remaining arg, not the last child command.
    for arg in args:
        command = _parse_command(command^, arg, leftover_start)

    if leftover_start == 0:
        return command^, args^

    # If the there are more or equivalent args to the index, then there are remaining args to pass to the command.
    var remaining_args = List[String]()
    if len(args) >= leftover_start:
        remaining_args = args[leftover_start : len(args)]

    return command^, remaining_args^


struct Command(Copyable, ExplicitlyCopyable, Movable, Stringable, Writable):
    """A struct representing a command that can be executed from the command line.

    ```mojo
     from prism import Command, CLI, Flag

     fn test(args: List[String], flags: List[Flag]) -> None:
         print("Hello from Chromeria!")

     fn main():
         var cli = CLI(
             name="hello",
             usage="This is a dummy command!",
             command=Command(
                 name="hello",
                 usage="This is a dummy command!",
                 run=test,
             ),
         )
         cli.run()
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

    var help: Help
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

    var suggest: Bool
    """If True, the command will suggest flags when an unknown flag is passed."""

    var read_from_stdin: Bool
    """If True, the command will read args from stdin as well."""

    fn __init__(
        out self,
        name: String,
        usage: String,
        *,
        owned args_usage: Optional[String] = None,
        owned aliases: List[String] = [],
        help: Help = Help(),
        version: Optional[Version] = None,
        exit: ExitFn = default_exit,
        output_writer: WriterFn = default_output_writer,
        error_writer: WriterFn = default_error_writer,
        read_from_stdin: Bool = False,
        owned valid_args: List[String] = [],
        owned children: List[ArcPointer[Self]] = [],
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
        owned flags: FlagSet = FlagSet(),
        flags_required_together: List[String] = [],
        mutually_exclusive_flags: List[String] = [],
        one_required_flags: List[String] = [],
        arg_validator: ArgValidatorFn = arbitrary_args,
        suggest: Bool = False,
    ):
        """Constructs a new `Command`.

        Args:
            name: The name of the command.
            usage: The usage of the command.
            args_usage: The usage of the arguments for the command.
            aliases: The aliases for the command.
            help: The help information for the command.
            version: The version information for the command.
            exit: The function to call when an error occurs.
            output_writer: The function to call when writing output.
            error_writer: The function to call when writing errors.
            read_from_stdin: If True, the command will read args from stdin as well.
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
            suggest: If True, the command will suggest flags when an unknown flag is passed.
        """
        # TODO: Maybe this should just raise instead of exiting, but it's not really a recoverable error?
        if not run and not raising_run:
            panic("A command must have a `run` or `raising_run` function.")

        self.name = name
        self.usage = usage
        self.args_usage = args_usage^
        self.aliases = aliases^

        self.exit = exit
        self.help = help
        self.version = version
        self.output_writer = output_writer
        self.error_writer = error_writer

        self.read_from_stdin = read_from_stdin

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
        self.suggest = suggest

        self.arg_validator = arg_validator

        self.valid_args = valid_args^
        self.flags = flags^
        self.parent = List[ArcPointer[Self]](capacity=1)
        self.children = children^
        for command in self.children:
            if command[].parent:
                command[].parent[0] = self
            else:
                command[].parent.append(self)

        self.flags.append(help.flag)
        if self.version:
            self.flags.append(self.version.value().flag)
        try:
            if flags_required_together:
                self._mark_flag_group_as[Annotation.REQUIRED_AS_GROUP](flags_required_together)
            if mutually_exclusive_flags:
                self._mark_flag_group_as[Annotation.MUTUALLY_EXCLUSIVE](mutually_exclusive_flags)
            if one_required_flags:
                self._mark_flag_group_as[Annotation.ONE_REQUIRED](one_required_flags)
        except e:
            panic(String("Failed to set flag annotations due to following reason: ", e))

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

        writer.write("Command(Name: ", self.name, ", Usage: ", self.usage)

        if self.aliases:
            writer.write(", Aliases: ", self.aliases.__str__())

        if self.valid_args:
            writer.write(", Valid Args: ", self.valid_args.__str__())
        if self.flags:
            writer.write(", Flags: ", self.flags)
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

    fn root(self) -> ArcPointer[Self]:
        """Returns the root command of the command tree.

        Returns:
            The root command in the tree.
        """
        if self.has_parent():
            return self.parent[0][].root()
        return self

    fn inherited_flags(self) -> FlagSet:
        """Returns the flags for the command and inherited flags from its parent.

        Returns:
            The flags for the command and its parent.
        """
        var flags = List[Flag]()

        @parameter
        fn add_parent_persistent_flags(parent: Self) capturing -> None:
            for flag in parent.flags:
                if flag.persistent:
                    flags.append(flag)

        self.visit_parents[add_parent_persistent_flags]()
        return FlagSet(flags^)

    fn _merge_flags(mut self) -> None:
        """Returns all flags for the command and inherited flags from its parent."""
        self.flags.extend(self.inherited_flags())

    fn _mark_flag_group_as[annotation: Annotation](mut self, flag_names: List[String]) raises -> None:
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
        for name in flag_names:
            self.flags.set_annotation[annotation](name, StaticString(" ").join(flag_names))

    fn has_parent(self) -> Bool:
        """Returns True if the command has a parent, False otherwise.

        Returns:
            True if the command has a parent, False otherwise.
        """
        return Bool(self.parent)

    fn visit_parents[func: ParentVisitorFn, reverse: Bool = False](self) -> None:
        """Visits all parents of the command and invokes func on each parent.

        Parameters:
            func: The function to invoke on each parent.
            reverse: If True, visits parents in reverse order (from child to root).
        """
        if not self.has_parent():
            return

        # If reverse is True, we traverse up the command tree first until we each the root
        # once the base case is reached, we make our way back down the command tree
        # and invoke the function on each parent in reverse order.
        @parameter
        if reverse:
            self.parent[0][].visit_parents[func, reverse]()
            func(self.parent[0][])
        else:
            func(self.parent[0][])
            self.parent[0][].visit_parents[func, reverse]()

    fn visit_parents[func: RaisingParentVisitorFn, reverse: Bool = False](self) raises -> None:
        """Visits all parents of the command and invokes func on each parent.

        Parameters:
            func: The function to invoke on each parent.
            reverse: If True, visits parents in reverse order (from child to root).
        """
        if not self.has_parent():
            return

        # If reverse is True, we traverse up the command tree first until we each the root
        # once the base case is reached, we make our way back down the command tree
        # and invoke the function on each parent in reverse order.
        @parameter
        if reverse:
            self.parent[0][].visit_parents[func, reverse]()
            func(self.parent[0][])
        else:
            func(self.parent[0][])
            self.parent[0][].visit_parents[func, reverse]()

    fn _execute_pre_run_hooks(self, cmd: Self, args: List[String]) raises -> None:
        """Runs the pre-run hooks for the command.

        Args:
            cmd: The command being executed.
            args: The arguments passed to the command.

        Raises:
            Any error that occurs while running the pre-run hooks.
        """

        @parameter
        fn run_action(parent: Self) raises -> None:
            if parent.persistent_raising_post_run:
                parent.persistent_raising_post_run.value()(args, cmd.flags.flags)

                @parameter
                if not ENABLE_TRAVERSE_RUN_HOOKS:
                    return
            elif parent.persistent_post_run:
                parent.persistent_post_run.value()(args, cmd.flags.flags)

                @parameter
                if not ENABLE_TRAVERSE_RUN_HOOKS:
                    return

        try:
            # Run the persistent pre-run hooks.
            cmd.visit_parents[run_action, reverse=ENABLE_TRAVERSE_RUN_HOOKS]()

            # Run the pre-run hooks.
            if cmd.pre_run:
                cmd.pre_run.value()(args, cmd.flags.flags)
            elif cmd.raising_pre_run:
                cmd.raising_pre_run.value()(args, cmd.flags.flags)
        except e:
            self.error_writer("Failed to run pre-run hooks for command: " + cmd.name)
            raise e

    fn _execute_post_run_hooks(self, cmd: Self, args: List[String]) raises -> None:
        """Runs the post-run hooks for the command.

        Args:
            cmd: The command being executed.
            args: The arguments passed to the command.

        Raises:
            Any error that occurs while running the post-run hooks.
        """

        @parameter
        fn run_action(parent: Self) raises -> None:
            if parent.persistent_raising_post_run:
                parent.persistent_raising_post_run.value()(args, cmd.flags.flags)

                @parameter
                if not ENABLE_TRAVERSE_RUN_HOOKS:
                    return
            elif parent.persistent_post_run:
                parent.persistent_post_run.value()(args, cmd.flags.flags)

                @parameter
                if not ENABLE_TRAVERSE_RUN_HOOKS:
                    return

        try:
            # Run the persistent post-run hooks.
            # If ENABLE_TRAVERSE_RUN_HOOKS is True, so we traverse downward from the root command.
            cmd.visit_parents[run_action, reverse=ENABLE_TRAVERSE_RUN_HOOKS]()

            # Run the post-run hooks.
            if cmd.post_run:
                cmd.post_run.value()(args, cmd.flags.flags)
            elif cmd.raising_post_run:
                cmd.raising_post_run.value()(args, cmd.flags.flags)
        except e:
            self.error_writer("Failed to run post-run hooks for command: " + cmd.name)
            raise e

    fn execute(mut self) -> None:
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
                self.exit(String("Failed to read from stdin: ", e))
                return

        command, args = _parse_command_from_args(self, input_args)

        # Merge persistent flags from ancestors.
        command._merge_flags()

        var remaining_args: List[String]
        try:
            remaining_args = command.flags.from_args(args)
        except e:
            # TODO: Move the suggestion checking into a separate function.
            if not command.suggest:
                self.exit(e)
                return

            var flag_name = flag_from_error(e)
            if not flag_name:
                self.exit(e)
                return

            var suggestion = suggest_flag(command.flags.flags, flag_name.value())
            if suggestion == "":
                self.exit(e)
                return

            self.error_writer(String("Unknown flag: ", flag_name.value(), "\nDid you mean: ", suggestion))
            return

        var cmd = OwnedPointer[Command](command^)
        try:
            # Check if the help flag was passed
            if cmd[].flags.get_bool(self.help.flag.name):
                self.output_writer(self.help.action(cmd))
                return

            # Check if the version flag was passed
            if self.version:
                # Check if version is set (not None) and if so, the value must be True.
                var version_flag_passed = cmd[].flags.get_bool(self.version.value().flag.name)
                if version_flag_passed and version_flag_passed.value() == True:
                    self.output_writer(self.version.value().action(self.version.value().value))
                    return

            # Validate individual required flags (eg: flag is required)
            cmd[].flags.validate_required_flags()

            # Validate flag groups (eg: one of required, mutually exclusive, required together)
            cmd[].flags.validate_flag_groups()

            # Run flag actions if they have any
            fn run_action(flag: Flag) raises -> None:
                if flag.action and flag.value:
                    flag.action[](flag.value[])

            cmd[].flags.visit_all[run_action]()

            # Validate the remaining arguments
            cmd[].arg_validator(cmd, remaining_args)

            # Run the function's commands.
            self._execute_pre_run_hooks(cmd[], remaining_args)
            if cmd[].run:
                cmd[].run.value()(remaining_args, cmd[].flags.flags)
            else:
                cmd[].raising_run.value()(remaining_args, cmd[].flags.flags)
            self._execute_post_run_hooks(cmd[], remaining_args)
        except e:
            self.exit(e)
