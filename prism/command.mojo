"""The `Command` type and the traversal that dispatches to it."""

from std.memory import ArcPointer
from std.sys import get_defined_bool
from prism._arg_parse import parse_args_from_command_line, parse_args_from_stdin
from prism._arg_set import ArgSet
from prism._flag_set import Annotation, FlagSet
from prism.arg import Arg
from prism._util import panic
from prism.args import ArgValidatorFn, arbitrary_args
from prism.exit import ExitFn, default_exit
from prism.flag import Flag
from prism.opt_type import OptType
from prism.help import Help, HelpContext
from prism.completion import default_completion
from prism.suggest import flag_from_error, suggest_flag, suggest_name
from prism.version import Version
from prism.writer import WriterFn, default_error_writer, default_output_writer


comptime ENABLE_TRAVERSE_RUN_HOOKS = get_defined_bool["PRISM_TRAVERSE_RUN_HOOKS", False]()
"""Controls the order in which ancestors' persistent pre and post run hooks are run.

If False, the chain is walked from the command upward to the root. If True, it is walked from the
root downward to the command. Every ancestor's hook runs either way; an earlier `return` here
claimed to stop after the first match, but it returned from the per-parent visitor rather than the
traversal, so it never had that effect."""


comptime CmdFn = def (args: ArgSet, flags: FlagSet) raises thin -> None
"""The function for a command to run.

`run` accepts a non-raising function too, because a non-raising function coerces to this type in
one step. The pre and post run hooks are `Optional[CmdFn]`, and reaching an Optional takes a second
step that the compiler will not chain, so a hook function must be declared `raises` even when it
never raises. Omitting it reports a `Command` constructor mismatch rather than naming the hook.
"""
comptime ParentVisitorFn = def (Command) capturing thin -> None
"""The function for visiting parents of a command."""
comptime RaisingParentVisitorFn = def (Command) capturing raises thin -> None
"""The function for visiting parents of a command."""


def _parse_command(command: Command, arg: ImmStringSpan) -> Optional[ArcPointer[Command]]:
    """Traverses the command tree to find the command that matches the given argument.

    Args:
        command: The current command being traversed.
        arg: The argument to match against the command name or aliases.

    Returns:
        The command that matches the argument.
    """
    def contains_arg(aliases: List[String], arg: ImmStringSpan) -> Bool:
        for name in aliases:
            if name == arg:
                return True
        return False

    for cmd in command.children:
        if cmd[].name == arg or contains_arg(cmd[].aliases, arg):
            return cmd

    return None


def _visible_flags(command: Command) -> FlagSet:
    """Returns the flags a command can accept: its own, plus persistent flags from its ancestors.

    Args:
        command: The command to collect flags for.

    Returns:
        The command's own flags followed by the persistent flags it inherits.
    """
    var flags = command.flags.copy()
    flags.extend(command.inherited_flags())
    return flags^


def _flag_consumes_next(flags: FlagSet, arg: ImmStringSpan) -> Bool:
    """Reports whether a flag argument also consumes the argument that follows it as its value.

    Args:
        flags: The flags the current command accepts.
        arg: The flag argument, which starts with `-` and contains no `=`.

    Returns:
        True if the next argument is this flag's value rather than a standalone argument.

    #### Notes:
    - Bool flags never take a following value, so they consume one argument.
    - An unrecognized flag is assumed to consume one argument. Reporting it here would be
      premature, since the flag may simply belong to a subcommand not yet descended into;
      `FlagSet.from_args` raises for it once the final command is known.
    """
    if arg.startswith("--", 0, 2):
        var flag = flags.lookup(arg[byte=2:])
        return Bool(flag) and flag.value()[].type != OptType.Bool

    # A shorthand argument may be a cluster of bool flags like `-abc`. Only the final shorthand in
    # such a cluster can take a value, so that is the one that decides.
    var shorthands = arg[byte=1:]
    if not shorthands:
        return False

    var flag = flags.lookup_shorthand(shorthands[byte = shorthands.byte_length() - 1 :])
    return Bool(flag) and flag.value()[].type != OptType.Bool


def _parse_command_from_args(command: ArcPointer[Command], mut args: List[String]) -> Optional[ArcPointer[Command]]:
    """Traverses the command tree to find the command that matches the given arguments.

    On a match, `args` is rewritten with the matched command names removed and everything else
    left in its original order, ready to be handed to `FlagSet.from_args`.

    Args:
        command: The root command to start traversing from.
        args: The arguments to traverse the command tree with. Rewritten in place on a match.

    Returns:
        The command that matches the arguments.
    """
    # Descend one level per matched argument. Each lookup searches the children of the command
    # matched so far, not the children of the root, so deeply nested subcommands resolve.
    var current = command
    var matched = False
    var passthrough = List[String](capacity=len(args))

    # Collecting the visible flags copies every flag the command can see, including the persistent
    # ones it inherits. Most invocations write no flags before the subcommand, so build the set on
    # first use at each level and drop it on descent rather than eagerly per level.
    var visible_flags = FlagSet()
    var visible_flags_ready = False

    var i = 0
    while i < len(args):
        ref arg = args[i]

        # A bare `--` ends flag parsing, so no subcommand can follow it.
        if arg == "--":
            break

        # Step over flags rather than stopping at them, so that a subcommand written after a flag
        # is still found. A flag that takes a value swallows the argument after it too, which is
        # what keeps `--output foo sub` from mistaking `foo` for a subcommand.
        if arg.startswith("-", 0, 1):
            var width = 1
            if "=" not in arg:
                if not visible_flags_ready:
                    visible_flags = _visible_flags(current[])
                    visible_flags_ready = True
                if _flag_consumes_next(visible_flags, arg):
                    width = 2

            for j in range(i, min(i + width, len(args))):
                passthrough.append(args[j])
            i += width
            continue

        var result = _parse_command(current[], arg)
        if not result:
            break

        # The command name is consumed by the match rather than passed through.
        current = result.value()
        visible_flags_ready = False
        matched = True
        i += 1

    # No subcommands matched, this is a root command execution.
    if not matched:
        return None

    # The first argument that is not a flag or a subcommand name is positional, and so is
    # everything after it. Pass the remainder through untouched.
    while i < len(args):
        passthrough.append(args[i])
        i += 1

    args = passthrough^
    return current^


def _with_usage_hint(command: Command, error: Error) -> Error:
    """Appends a pointer to the command's help to an error about to be reported.

    Args:
        command: The command that was being executed.
        error: The error to annotate.

    Returns:
        The error with a trailing hint naming the command whose help to read.
    """
    return Error(t"{error}\n\nRun '{command.full_name()} --help' for usage.")


def _unknown_command_error(command: Command, name: ImmStringSpan) -> Error:
    """Builds the error reported when an argument does not name any of a command's subcommands.

    Args:
        command: The command whose subcommands were searched.
        name: The argument that matched none of them.

    Returns:
        An error naming the offending argument, with a correction when one is close enough.
    """
    var message = String(t'Unknown command: "{name}" for "{command.full_name()}".')

    if command.suggest:
        # Aliases are matched during traversal, so they are suggestible too.
        var candidates = List[String]()
        for child in command.children:
            candidates.append(child[].name)
            candidates.extend(child[].aliases.copy())

        var suggestion = suggest_name(Span(candidates), name)
        if suggestion:
            message.write(t"\n\nDid you mean this?\n\t{suggestion}")

    return Error(message)


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
    """A function to run before the run function is executed. Must be declared `raises`."""
    var run: CmdFn
    """A function to run when the command is executed."""
    var post_run: Optional[CmdFn]
    """A function to run after the run function is executed. Must be declared `raises`."""

    var persistent_pre_run: Optional[CmdFn]
    """A function to run before the run function is executed. This persists to children.

    Must be declared `raises`.
    """
    var persistent_post_run: Optional[CmdFn]
    """A function to run after the run function is executed. This persists to children.

    Must be declared `raises`.
    """

    var arg_validator: ArgValidatorFn
    """Function to validate arguments passed to the command."""
    var args: List[Arg]
    """The positional arguments the command declares.

    Declaring arguments binds them by position and validates their count and types before `run` is
    called, and names them in usage text. Leave empty to accept any positional arguments and check
    them with `arg_validator` instead.
    """

    var flags: FlagSet
    """It is all local, persistent, and inherited flags."""

    var children: List[ArcPointer[Self]]
    """Child commands."""
    var parent: List[ArcPointer[Self]]
    """Ancestor link, held as a 0-or-1 element list; empty for the root command.

    The linked command carries no children of its own: the chain exists to be walked upward, and
    retaining children would make it a reference cycle that leaks the tree. Read a command's
    children from the command itself, never through another command's `parent`.

    `Optional[ArcPointer[Self]]` is the natural type here, but a recursive struct cannot be laid out
    through `Optional`, and `ArcPointer[Optional[Self]]` does not satisfy `ArcPointer`'s
    `Deinitable & Movable` bound. `List` is layout-opaque, so it is the encoding that compiles.
    Read this through `has_parent()` rather than indexing it directly.
    """

    var suggest: Bool
    """If True, the command will suggest flags when an unknown flag is passed."""

    var reject_unknown_subcommands: Bool
    """If True, a leftover positional argument on a command that has subcommands is an error.

    A command with subcommands is a dispatcher, so `app sttaus` is a typo rather than data, and
    running the parent silently is the wrong answer. Set to False on a parent command that
    genuinely takes positional arguments of its own.
    """

    var _generated_completion: Bool
    """True only for the `completion` subcommand `enable_completion` generates.

    Identity, not name, is what marks this command. A user is free to write their own subcommand
    called `completion`, and it must run its own `run` function rather than being intercepted.
    """

    def __init__(
        out self,
        name: String,
        usage: String,
        run: CmdFn,
        *,
        var aliases: List[String] = [],
        var help: Help = Help(),
        var version: Optional[Version] = None,
        exit: ExitFn = default_exit,
        output_writer: WriterFn = default_output_writer,
        error_writer: WriterFn = default_error_writer,
        var args: List[Arg] = [],
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
        reject_unknown_subcommands: Bool = True,
    ):
        """Constructs a new `Command`.

        Args:
            name: The name of the command.
            usage: The usage of the command.
            run: The function to run when the command is executed.
            aliases: The aliases for the command.
            help: The help information for the command.
            version: The version information for the command.
            exit: The function to call when an error occurs.
            output_writer: The function to call when writing output.
            error_writer: The function to call when writing errors.
            args: The positional arguments the command declares.
            children: The child commands.
            pre_run: The function to run before the command is executed. Must be declared `raises`.
            post_run: The function to run after the command is executed. Must be declared `raises`.
            persistent_pre_run: The function to run before the command is executed. This persists to
                children. Must be declared `raises`.
            persistent_post_run: The function to run after the command is executed. This persists to
                children. Must be declared `raises`.
            flags: The flags for the command.
            flags_required_together: The flags that are required together.
            mutually_exclusive_flags: The flags that are mutually exclusive.
            one_required_flags: The flags where at least one is required.
            arg_validator: The function to validate arguments passed to the command.
            suggest: If True, the command will suggest flags and subcommands when an unknown one
                is passed.
            enable_completion: If True, the command will have a completion subcommand.
            reject_unknown_subcommands: If True, a leftover positional argument on a command that
                has subcommands is reported as an unknown command. Set to False on a parent
                command that takes positional arguments of its own.
        """
        self.name = name
        self.usage = usage
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
        self.reject_unknown_subcommands = reject_unknown_subcommands
        self._generated_completion = False

        self.args = args^
        self.flags = flags^
        self.parent = []
        self.children = [ArcPointer(child.copy()) for child in children]

        self.flags.append(self.help.flag.copy())
        if self.version:
            self.flags.append(self.version.value().flag.copy())

        # Auto-add completion subcommand
        if enable_completion:
            def _completion_noop(args: ArgSet, flags: FlagSet) raises -> None:
                pass

            var completion_command = Command(
                name="completion",
                usage="Generate shell completion scripts.",
                run=_completion_noop,
                args=[
                    Arg.string(
                        name="shell",
                        usage="The shell to generate a script for.",
                        valid_values=["zsh", "bash"],
                    )
                ],
                enable_completion=False,
            )
            completion_command._generated_completion = True
            self.children.append(ArcPointer(completion_command^))

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
        if self.flags:
            writer.write(", Flags: ", self.flags)
        writer.write(")")

    def full_name(self) -> String:
        """Traverses up the parent command tree to build the full command as a string.

        Returns:
            The full command name.
        """
        if self.has_parent():
            return String(self.parent[0][].full_name(), " ", self.name)
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

    def _parent_link(mut self) -> ArcPointer[Self]:
        """Builds the value stored in a child's `parent`: this command without its children.

        Returns:
            A childless copy of this command, sharing its own ancestor chain.

        #### Notes:
        - `copy()` shares children by reference count rather than duplicating them, so a link built
          from a plain copy points back at the very child that holds it: `child -> parent ->
          children -> child`. `ArcPointer` does not collect cycles, so every command tree wired
          that way leaked. The chain is only ever walked upward, by `full_name`,
          `inherited_flags`, and the persistent run hooks, so dropping the children costs nothing
          and takes the cycle with it.
        """
        var children = self.children^
        self.children = []
        var link = self.copy()
        self.children = children^
        return ArcPointer(link^)

    def _wire_parents(mut self) -> None:
        """Links every command in this subtree to its parent, top-down.

        Parents cannot be linked as commands are constructed, because a child is built before the
        parent it will be attached to exists. This walks down from the root instead, so that by the
        time a node's children are linked the node's own parent chain is already complete. That is
        what makes `full_name` and `inherited_flags` correct at any depth, not just one level down.
        """
        var queue = List[ArcPointer[Self]]()
        var link = self._parent_link()
        for command in self.children:
            command[].parent = [link.copy()]
            queue.append(command)

        # A node is only enqueued once its own parent link is set, so by the time it is popped its
        # ancestor chain is complete and building a link from it captures the full chain.
        while queue:
            var node = queue.pop()
            if not node[].children:
                continue

            # One link per node, shared by all its children, rather than one copy per child.
            var node_link = node[]._parent_link()
            for command in node[].children:
                command[].parent = [node_link.copy()]
                queue.append(command)

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
        return Bool(self.parent)

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
            self.parent[0][].visit_parents[func, reverse]()
            func(self.parent[0][])
        else:
            func(self.parent[0][])
            self.parent[0][].visit_parents[func, reverse]()

    def visit_parents[func: RaisingParentVisitorFn, reverse: Bool = False](self) raises -> None:
        """Visits all parents of the command and invokes func on each parent.

        Parameters:
            func: The function to invoke on each parent.
            reverse: If True, visits parents in reverse order (from child to root).

        Raises:
            Error: If the visitor raises an error.
        """
        if not self.has_parent():
            return

        # If reverse is True, we traverse up the command tree first until we each the root
        # once the base case is reached, we make our way back down the command tree
        # and invoke the function on each parent in reverse order.
        comptime if reverse:
            self.parent[0][].visit_parents[func, reverse]()
            func(self.parent[0][])
        else:
            func(self.parent[0][])
            self.parent[0][].visit_parents[func, reverse]()

    def _execute_pre_run_hooks(self, cmd: Self, args: ArgSet) raises -> None:
        """Runs the pre-run hooks for the command.

        Args:
            cmd: The command being executed.
            args: The arguments passed to the command.

        Raises:
            Any error that occurs while running the pre-run hooks.
        """

        @parameter
        def run_action(parent: Self) raises -> None:
            if parent.persistent_pre_run:
                parent.persistent_pre_run.value()(args, cmd.flags)

        try:
            # Run the persistent pre-run hooks.
            cmd.visit_parents[run_action, reverse=ENABLE_TRAVERSE_RUN_HOOKS]()

            # Run the pre-run hooks.
            if cmd.pre_run:
                cmd.pre_run.value()(args, cmd.flags)
        except e:
            self.error_writer(String(t"Failed to run pre-run hooks for command: {cmd.name}"))
            raise e^

    def _execute_post_run_hooks(self, cmd: Self, args: ArgSet) raises -> None:
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

    def execute(mut self, args: Span[StaticString, ImmStaticOrigin]) -> None:
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

        # Link the tree's parent pointers once, from the root, before anything reads them.
        cmd[]._wire_parents()

        # `cmd` moves down the tree during traversal, so hold on to the wired root separately.
        # Completion generation walks the whole tree and needs the linked copy, not `self`.
        var root = cmd

        # If there's no children, then the root command is used.
        # Otherwise, we traverse the command tree to find the command that matches the arguments.
        # `input_args` comes back with the matched command names stripped and everything else,
        # flags included, still in place.
        if self.children and input_args:
            var result = _parse_command_from_args(cmd, input_args)
            if result:
                cmd = result.value()
            else:
                # No subcommand matched, use the root command.
                pass

        var args = Span(input_args)

        # Merge persistent flags from ancestors.
        cmd[]._merge_flags()

        var remaining_args: List[String]
        try:
            remaining_args = cmd[].flags.from_args(args)
        except e:
            # TODO: Move the suggestion checking into a separate function.
            if not cmd[].suggest:
                self.exit(_with_usage_hint(cmd[], e))
                return

            var flag_name = flag_from_error(e)
            if not flag_name:
                self.exit(_with_usage_hint(cmd[], e))
                return

            var suggestion = suggest_flag(cmd[].flags.flags, flag_name.value())
            if suggestion == "":
                self.exit(_with_usage_hint(cmd[], e))
                return

            # Route through `exit` like every other failure here. Writing the message and
            # returning reports a parse failure while exiting 0.
            self.exit(
                _with_usage_hint(cmd[], Error(t"Unknown flag: {flag_name.value()}\nDid you mean: {suggestion}?"))
            )
            return

        try:
            # `get_bool` returns an empty Optional when the flag has neither a value nor a default,
            # so the result has to be unwrapped rather than merely checked for presence, or
            # `--help=false` displays help anyway. Unwrap with `or_else`, not `opt and opt.value()`:
            # `and` dispatches to `Optional.__and__` and yields an Optional, which is truthy
            # whenever it holds a value, so the wrapped `False` reads as True.
            # Read the help flag from the command being executed, and render with that command's own
            # `Help`, so a subcommand configured with a custom help flag or renderer gets its own.
            if cmd[].flags.get_bool(cmd[].help.flag.name).or_else(False):
                var inherited = cmd[].inherited_flags()
                var help_context = HelpContext(
                    full_name=cmd[].full_name(),
                    usage=cmd[].usage,
                    args=cmd[].args.copy(),
                    flags=cmd[].flags.flags.copy(),
                    inherited_flags=inherited.flags.copy(),
                    children=[(child[].name, child[].usage) for child in cmd[].children],
                    aliases=cmd[].aliases.copy(),
                )
                self.output_writer(cmd[].help.action(help_context))
                return

            # Check if the version flag was passed. Read it from the command being executed, so a
            # subcommand carrying its own `Version` reports that rather than the root's.
            if cmd[].version:
                ref version = cmd[].version.value()
                # Unwrapped the same way as the help flag above, and for the same reason.
                if cmd[].flags.get_bool(version.flag.name).or_else(False):
                    self.output_writer(version.action(cmd[].full_name(), version.value))
                    return

            # Check if the generated completion subcommand was invoked. This tests the marker rather
            # than the name, so a user's own subcommand called `completion` runs normally.
            if cmd[]._generated_completion:
                if not remaining_args:
                    self.exit(
                        Error(t"Usage: {root[].name} completion <shell>\nSupported shells: zsh, bash")
                    )
                    return
                self.output_writer(default_completion(root[], remaining_args[0]))
                return

            # A command with subcommands of its own is a dispatcher, so a leftover positional
            # argument is a mistyped subcommand rather than data. Falling through and running the
            # parent turns a typo into a silent no-op. Commands generated by `enable_completion`
            # do not count: enabling shell completion should not turn a leaf into a dispatcher.
            if cmd[].reject_unknown_subcommands and remaining_args:
                for child in cmd[].children:
                    if not child[]._generated_completion:
                        raise _unknown_command_error(cmd[], remaining_args[0])

            # Validate individual required flags (eg: flag is required)
            cmd[].flags.validate_required_flags()

            # Validate flag groups (eg: one of required, mutually exclusive, required together)
            cmd[].flags.validate_flag_groups()

            # Run flag actions if they have any
            # TODO: Renable flag actions
            cmd[].flags.visit_all[_run_flag_action]()

            # Validate the remaining arguments. `ArgValidatorFn` is not handed the command, so
            # name it here rather than leaving the reader to guess which one rejected the input.
            try:
                cmd[].arg_validator(remaining_args)
            except e:
                raise Error(t"{cmd[].full_name()}: {e}")

            # Bind the positional values to the declared arguments. This checks their count and
            # types, so a mistyped argument is reported before `run` starts rather than surfacing
            # partway through it.
            var args = ArgSet(cmd[].args.copy())
            try:
                args.bind(remaining_args^)
            except e:
                raise Error(t"{cmd[].full_name()}: {e}")

            # Run the function's commands.
            self._execute_pre_run_hooks(cmd[], args)
            cmd[].run(args, cmd[].flags)
            self._execute_post_run_hooks(cmd[], args)
        except e:
            self.exit(_with_usage_hint(cmd[], e))
