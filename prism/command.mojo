from std.sys import env_get_bool
from std.memory import ArcPointer
from std.sys import get_defined_bool
from std.utils import Variant
from prism._arg_parse import parse_args_from_command_line, parse_args_from_stdin
from prism._flag_set import Annotation, FlagSet
from prism._util import panic
from prism.args import ArgValidatorFn, arbitrary_args
from prism.exit import ExitFn, default_exit
from prism.flag import Flag
from prism.help import Help, HelpContext
from prism.completion import default_completion
from prism.suggest import flag_from_error, suggest_flag
from prism.version import Version
from prism.writer import WriterFn, default_error_writer, default_output_writer


comptime ENABLE_TRAVERSE_RUN_HOOKS = get_defined_bool["PRISM_TRAVERSE_RUN_HOOKS", False]()
"""Set to True to traverse all parents' persistent pre and post run hooks. If False, it'll only run the first match.
If False, starts from the child command and goes up the parent chain. If True, starts from root and goes down."""


comptime CmdFn = def (args: List[String], flags: FlagSet) raises -> None
"""The function for a command to run."""
comptime ParentVisitorFn = def (Command) capturing -> None
"""The function for visiting parents of a command."""
comptime RaisingParentVisitorFn = def (Command) capturing raises -> None
"""The function for visiting parents of a command."""


def _parse_command(command: Command, arg: StringSlice, mut leftover_start: Int) -> Optional[ArcPointer[Command]]:
    """Traverses the command tree to find the command that matches the given argument.

    Args:
        command: The current command being traversed.
        arg: The argument to match against the command name or aliases.
        leftover_start: The index to start the remaining arguments at.

    Returns:
        The command that matches the argument.
    """
    def contains_arg(aliases: List[String], arg: StringSlice) -> Bool:
        for name in aliases:
            if name == arg:
                return True
        return False

    for cmd in command.children:
        if cmd[].name == arg or contains_arg(cmd[].aliases, arg):
            leftover_start += 1
            return cmd

    return None


def _parse_command_from_args(command: Command, args: List[String]) -> Optional[Tuple[ArcPointer[Command], Int]]:
    """Traverses the command tree to find the command that matches the given arguments.

    Args:
        command: The root command to start traversing from.
        args: The arguments to traverse the command tree with.

    Returns:
        The command that matches the arguments and the remaining arguments to pass to that command.
    """
    var new_command: Optional[ArcPointer[Command]] = None
    var leftover_start = 0  # Start at 1 to start slice at the first remaining arg, not the last child command.
    for arg in args:
        var result = _parse_command(command, arg, leftover_start)
        if not result:
            break

        new_command = result.value()

    # No subcommands matched, this is a root command execution.
    if not new_command:
        return None

    # If the there are more or equivalent args to the index, then there are remaining args to pass to the command.
    return new_command.take(), leftover_start


# Run flag actions if they have any
def _run_flag_action(flag: Flag) raises -> None:
    if flag.action and flag.value:
        flag.action.value()(flag.value.value())


@fieldwise_init
struct Command(Copyable, Writable):
    """A struct representing a command that can be executed from the command line.

    ```mojo
     from prism import Command, FlagSet, read_args

     def test(args: List[String], flags: FlagSet) -> None:
         print("Hello from Chromeria!")

     def main():
         var cli = Command(
             name="hello",
             usage="This is a dummy command!",
             run=test,
         )
         cli.execute(read_args())
    ```

    Then execute the command by running the mojo file or binary.
    ```sh
    > mojo hello.mojo
    Hello from Chromeria!

    > mojo build hello.mojo && ./hello
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
    var run: CmdFn
    """A function to run when the command is executed."""
    var post_run: Optional[CmdFn]
    """A function to run after the run function is executed."""

    var persistent_pre_run: Optional[CmdFn]
    """A function to run before the run function is executed. This persists to children."""
    var persistent_post_run: Optional[CmdFn]
    """A function to run after the run function is executed. This persists to children."""

    var arg_validator: ArgValidatorFn
    """Function to validate arguments passed to the command."""
    var valid_args: List[String]
    """Valid arguments for the command."""

    var flags: FlagSet
    """It is all local, persistent, and inherited flags."""

    var children: List[ArcPointer[Self]]
    """Child commands."""
    # TODO: An optional pointer would be great, but it breaks the compiler. So a list of 0-1 pointers is used.
    var parent: ArcPointer[Optional[Self]]
    """Parent command."""

    var suggest: Bool
    """If True, the command will suggest flags when an unknown flag is passed."""

    def __init__(
        out self,
        name: String,
        usage: String,
        run: CmdFn,
        *,
        var args_usage: Optional[String] = None,
        var aliases: List[String] = [],
        var help: Help = Help(),
        var version: Optional[Version] = None,
        exit: ExitFn = default_exit,
        output_writer: WriterFn = default_output_writer,
        error_writer: WriterFn = default_error_writer,
        var valid_args: List[String] = [],
        var children: List[Self] = [],
        pre_run: Optional[CmdFn] = None,
        post_run: Optional[CmdFn] = None,
        persistent_pre_run: Optional[CmdFn] = None,
        persistent_post_run: Optional[CmdFn] = None,
        var flags: FlagSet = FlagSet(),
        flags_required_together: List[String] = [],
        mutually_exclusive_flags: List[String] = [],
        one_required_flags: List[String] = [],
        arg_validator: ArgValidatorFn = arbitrary_args,
        suggest: Bool = False,
        enable_completion: Bool = False,
    ):
        """Constructs a new `Command`.

        Args:
            name: The name of the command.
            usage: The usage of the command.
            run: The function to run when the command is executed.
            args_usage: The usage of the arguments for the command.
            aliases: The aliases for the command.
            help: The help information for the command.
            version: The version information for the command.
            exit: The function to call when an error occurs.
            output_writer: The function to call when writing output.
            error_writer: The function to call when writing errors.
            valid_args: The valid arguments for the command.
            children: The child commands.
            pre_run: The function to run before the command is executed.
            post_run: The function to run after the command is executed.
            persistent_pre_run: The function to run before the command is executed. This persists to children.
            persistent_post_run: The function to run after the command is executed. This persists to children.
            flags: The flags for the command.
            flags_required_together: The flags that are required together.
            mutually_exclusive_flags: The flags that are mutually exclusive.
            one_required_flags: The flags where at least one is required.
            arg_validator: The function to validate arguments passed to the command.
            suggest: If True, the command will suggest flags when an unknown flag is passed.
            enable_completion: If True, the command will have a completion subcommand.
        """
        self.name = name
        self.usage = usage
        self.args_usage = args_usage^
        self.aliases = aliases^

        self.exit = exit
        self.help = help^
        self.version = version^
        self.output_writer = output_writer
        self.error_writer = error_writer

        self.pre_run = pre_run
        self.run = run
        self.post_run = post_run

        self.persistent_pre_run = persistent_pre_run
        self.persistent_post_run = persistent_post_run
        self.suggest = suggest

        self.arg_validator = arg_validator

        self.valid_args = valid_args^
        self.flags = flags^
        self.parent = ArcPointer(Optional[Self](None))
        self.children = [ArcPointer(child.copy()) for child in children]
        for command in self.children:
            command[].parent = ArcPointer(Optional(self.copy()))

        self.flags.append(self.help.flag.copy())
        if self.version:
            self.flags.append(self.version.value().flag.copy())

        # Auto-add completion subcommand
        if enable_completion:
            def _completion_noop(args: List[String], flags: FlagSet) raises -> None:
                pass

            self.children.append(
                ArcPointer(
                    Command(
                        name="completion",
                        usage="Generate shell completion scripts.",
                        run=_completion_noop,
                        args_usage="SHELL",
                        valid_args=["zsh", "bash"],
                        enable_completion=False,
                    )
                )
            )
            self.children[len(self.children) - 1][].parent = ArcPointer(Optional(self.copy()))

        try:
            if not flags_required_together and not mutually_exclusive_flags and not one_required_flags:
                return

            # TODO: Children are created before the parent, so inherited flags aren't working for
            # these flag groups. Will revisit this at some point.
            # self._merge_flags()
            if flags_required_together:
                self._mark_flag_group_as[Annotation.REQUIRED_AS_GROUP](flags_required_together)
            if mutually_exclusive_flags:
                self._mark_flag_group_as[Annotation.MUTUALLY_EXCLUSIVE](mutually_exclusive_flags)
            if one_required_flags:
                self._mark_flag_group_as[Annotation.ONE_REQUIRED](one_required_flags)
        except e:
            panic(t"Failed to set flag annotations due to following reason: {e}")

    def write_to(self, mut writer: Some[Writer]):
        """Write string representation to a `Writer`.

        Args:
            writer: The formatter to write to.
        """
        writer.write("Command(Name: ", self.name, ", Usage: ", self.usage)

        if self.aliases:
            writer.write(", Aliases: ", self.aliases)
        if self.valid_args:
            writer.write(", Valid Args: ", self.valid_args)
        if self.flags:
            writer.write(", Flags: ", self.flags)
        writer.write(")")

    def full_name(self) -> String:
        """Traverses up the parent command tree to build the full command as a string.

        Returns:
            The full command name.
        """
        if self.has_parent():
            return String(self.parent[].value().full_name(), " ", self.name)
        return self.name

    def inherited_flags(self) -> FlagSet:
        """Returns the flags for the command and inherited flags from its parent.

        Returns:
            The flags for the command and its parent.
        """
        var flags = List[Flag]()

        @parameter
        def add_parent_persistent_flags(parent: Self) capturing -> None:
            for flag in parent.flags:
                if flag.persistent:
                    flags.append(flag.copy())

        self.visit_parents[add_parent_persistent_flags]()
        return FlagSet(flags^)

    def _merge_flags(mut self) -> None:
        """Returns all flags for the command and inherited flags from its parent."""
        self.flags.extend(self.inherited_flags())

    def _mark_flag_group_as[annotation: Annotation](mut self, flag_names: List[String]) raises -> None:
        """Marks the given flags with annotations so that `Prism` errors.

        Parameters:
            annotation: The annotation to set on the flags.

        Args:
            flag_names: The names of the flags to mark as required together.

        #### Notes:
        - If the annotation is `REQUIRED_AS_GROUP`, then all the flags in the group must be set.
        - If the annotation is `ONE_REQUIRED`, then at least one flag in the group must be set.
        - If the annotation is `MUTUALLY_EXCLUSIVE`, then only one flag in the group can be set.
        """
        for name in flag_names:
            self.flags.set_annotation[annotation](name, " ".join(flag_names))

    def has_parent(self) -> Bool:
        """Returns True if the command has a parent, False otherwise.

        Returns:
            True if the command has a parent, False otherwise.
        """
        return Bool(self.parent[])

    def visit_parents[func: ParentVisitorFn, reverse: Bool = False](self) -> None:
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
        comptime if reverse:
            self.parent[].value().visit_parents[func, reverse]()
            func(self.parent[].value())
        else:
            func(self.parent[].value())
            self.parent[].value().visit_parents[func, reverse]()

    def visit_parents[func: RaisingParentVisitorFn, reverse: Bool = False](self) raises -> None:
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
        comptime if reverse:
            self.parent[].value().visit_parents[func, reverse]()
            func(self.parent[].value())
        else:
            func(self.parent[].value())
            self.parent[].value().visit_parents[func, reverse]()

    def _execute_pre_run_hooks(self, cmd: Self, args: List[String]) raises -> None:
        """Runs the pre-run hooks for the command.

        Args:
            cmd: The command being executed.
            args: The arguments passed to the command.

        Raises:
            Any error that occurs while running the pre-run hooks.
        """

        @parameter
        def run_action(parent: Self) raises -> None:
            if parent.persistent_post_run:
                parent.persistent_post_run.value()(args, cmd.flags)

                comptime if not ENABLE_TRAVERSE_RUN_HOOKS:
                    return

        try:
            # Run the persistent pre-run hooks.
            cmd.visit_parents[run_action, reverse=ENABLE_TRAVERSE_RUN_HOOKS]()

            # Run the pre-run hooks.
            if cmd.pre_run:
                cmd.pre_run.value()(args, cmd.flags)
        except e:
            self.error_writer(String(t"Failed to run pre-run hooks for command: {cmd.name}"))
            raise e^

    def _execute_post_run_hooks(self, cmd: Self, args: List[String]) raises -> None:
        """Runs the post-run hooks for the command.

        Args:
            cmd: The command being executed.
            args: The arguments passed to the command.

        Raises:
            Any error that occurs while running the post-run hooks.
        """

        @parameter
        def run_action(parent: Self) raises -> None:
            if parent.persistent_post_run:
                parent.persistent_post_run.value()(args, cmd.flags)

                comptime if not ENABLE_TRAVERSE_RUN_HOOKS:
                    return

        try:
            # Run the persistent post-run hooks.
            # If ENABLE_TRAVERSE_RUN_HOOKS is True, so we traverse downward from the root command.
            cmd.visit_parents[run_action, reverse=ENABLE_TRAVERSE_RUN_HOOKS]()

            # Run the post-run hooks.
            if cmd.post_run:
                cmd.post_run.value()(args, cmd.flags)
        except e:
            self.error_writer(String(t"Failed to run post-run hooks for command: {cmd.name}"))
            raise e^

    def execute(mut self, var args: List[String]) -> None:
        """Traverses the arguments passed to the executable and executes the last command in the branch.

        Args:
            args: The arguments passed to the executable.
        """
        self._execute(args^)

    def execute(mut self, args: Span[StaticString, StaticConstantOrigin]) -> None:
        """Traverses the arguments passed to the executable and executes the last command in the branch.

        This is an overload that accepts a variadic list of static strings, which is generally used for the
        result of `argv()`.

        Args:
            args: The arguments passed to the executable.
        """
        self._execute(parse_args_from_command_line(args))

    def _execute(mut self, var input_args: List[String]) -> None:
        """Traverses the arguments passed to the executable and executes the last command in the branch.

        Args:
            input_args: The arguments passed to the executable.
        """
        # Traverse from the root command through the children to find a match for the current argument.
        # Any additional arguments past the last matched command name are considered arguments.
        if self.has_parent():
            self.exit(Error("Cannot execute from a non-root command. Please execute from the root command."))
            return

        var cmd = ArcPointer(self.copy())
        var args = Span(input_args)

        # If there's no children, then the root command is used.
        # Otherwise, we traverse the command tree to find the command that matches the arguments.
        if self.children and args:
            var result = _parse_command_from_args(cmd[], input_args)
            if result:
                cmd = result.value()[0]
                var leftover_start = result.value()[1]
                if len(args) >= leftover_start:
                    args = args[leftover_start : len(args)]
            else:
                # No subcommand matched, use the root command.
                pass

        # Merge persistent flags from ancestors.
        cmd[]._merge_flags()

        var remaining_args: List[String]
        try:
            remaining_args = cmd[].flags.from_args(args)
        except e:
            # TODO: Move the suggestion checking into a separate function.
            if not cmd[].suggest:
                self.exit(e)
                return

            var flag_name = flag_from_error(e)
            if not flag_name:
                self.exit(e)
                return

            var suggestion = suggest_flag(cmd[].flags.flags, flag_name.value())
            if suggestion == "":
                self.exit(e)
                return

            self.error_writer(String(t"Unknown flag: {flag_name.value()}\nDid you mean: {suggestion}?"))
            return

        try:
            # Check if the help flag was passed
            if cmd[].flags.get_bool(self.help.flag.name):
                var help_context = HelpContext(
                    full_name=cmd[].full_name(),
                    usage=cmd[].usage,
                    args_usage=cmd[].args_usage,
                    flags=cmd[].flags.flags.copy(),
                    children=[(child[].name, child[].usage) for child in cmd[].children],
                    aliases=cmd[].aliases.copy()
                )
                self.output_writer(self.help.action(help_context))
                return

            # Check if the version flag was passed
            if self.version:
                # Check if version is set (not None) and if so, the value must be True.
                var version_flag_passed = cmd[].flags.get_bool(self.version.value().flag.name)
                if version_flag_passed and version_flag_passed.value() == True:
                    self.output_writer(self.version.value().action(self.version.value().value))
                    return

            # Check if the completion subcommand was invoked
            if cmd[].name == "completion":
                if not remaining_args:
                    self.error_writer(String(t"Usage: {self.name} completion <shell>\nSupported shells: zsh, bash"))
                    return
                self.output_writer(default_completion(self, remaining_args[0]))
                return

            # Validate individual required flags (eg: flag is required)
            cmd[].flags.validate_required_flags()

            # Validate flag groups (eg: one of required, mutually exclusive, required together)
            cmd[].flags.validate_flag_groups()

            # Run flag actions if they have any
            # TODO: Renable flag actions
            cmd[].flags.visit_all[_run_flag_action]()

            # Validate the remaining arguments
            cmd[].arg_validator(remaining_args, self.valid_args)

            # Run the function's commands.
            self._execute_pre_run_hooks(cmd[], remaining_args)
            cmd[].run(remaining_args, cmd[].flags)
            self._execute_post_run_hooks(cmd[], remaining_args)
        except e:
            self.exit(e)
