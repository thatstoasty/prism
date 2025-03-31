from sys import argv
from builtin.io import _fdopen
from collections import Optional, Dict
from collections.string import StaticString
from memory import ArcPointer
import mog
from mog import Position, get_width
from prism._util import panic
from prism.flag import Flag
from prism._flag_set import Annotation, FlagSet
from prism.args import arbitrary_args
from prism.context import Context


fn _parse_args_from_command_line(args: VariadicList[StaticString]) -> List[String]:
    """Returns the arguments passed to the executable as a list of strings.

    Returns:
        The arguments passed to the executable as a list of strings.
    """
    var result = List[String](capacity=len(args))
    var i = 1
    while i < len(args):
        result.append(String(args[i]))
        i += 1

    return result^


@value
@register_passable("trivial")
struct STDINParserState:
    """State of the parser when reading from stdin."""

    var value: UInt8
    """State of the parser when reading from stdin."""

    alias FIND_TOKEN = Self(0)
    alias FIND_ARG = Self(1)

    fn __eq__(self, other: Self) -> Bool:
        """Compares two `STDINParserState` instances for equality.

        Args:
            other: The other `STDINParserState` instance to compare to.

        Returns:
            True if the two instances are equal, False otherwise.
        """
        return self.value == other.value

    fn __ne__(self, other: Self) -> Bool:
        """Compares two `STDINParserState` instances for inequality.

        Args:
            other: The other `STDINParserState` instance to compare to.

        Returns:
            True if the two instances are not equal, False otherwise.
        """
        return self.value != other.value


fn _parse_args_from_stdin(input: String) -> List[String]:
    """Reads arguments from stdin and returns them as a list of strings.

    Args:
        input: The input string to parse.

    Returns:
        The arguments read from stdin as a list of strings.
    """
    var state = STDINParserState.FIND_TOKEN
    var line_number = 1
    var token = String("")
    var args = List[String]()

    for char in input.codepoint_slices():
        if state == STDINParserState.FIND_TOKEN:
            if char.isspace() or char == '"':
                if char == "\n":
                    line_number += 1
                if token != "":
                    if token == "--":
                        break
                    args.append(token)
                    token = ""
                if char == '"':
                    state = STDINParserState.FIND_ARG
                continue
            token.write(char)
        else:
            if char != '"':
                token.write(char)
            else:
                if token != "":
                    args.append(token)
                    token = ""
                state = STDINParserState.FIND_TOKEN

    if state == STDINParserState.FIND_TOKEN:
        if token and token != "--":
            args.append(token)
    else:
        # Not an empty string and not a space
        if token and not token.isspace():
            args.append(token)

    return args^


fn default_help(command: ArcPointer[Command]) raises -> String:
    """Prints the help information for the command.

    Args:
        command: The command to generate help information for.

    Returns:
        The help information for the command.

    Raises:
        Any error that occurs while generating the help information.
    """
    alias style = mog.Style(mog.ASCII)
    var builder = String("Usage: ", command[].full_name())

    if len(command[].flags) > 0:
        builder.write(" [OPTIONS]")
    if len(command[].children) > 0:
        builder.write(" COMMAND")
    builder.write(" [ARGS]...", "\n\n", command[].usage, "\n")

    if command[].args_usage:
        builder.write("\nArguments:\n  ", command[].args_usage.value(), "\n")

    var option_width = 0
    if command[].flags:
        var widest_flag = 0
        var widest_shorthand = 0
        for flag in command[].flags:
            if len(flag[].name) > widest_flag:
                widest_flag = len(flag[].name)
            if len(flag[].shorthand) > widest_shorthand:
                widest_shorthand = len(flag[].shorthand)

        alias USAGE_PADDING = 4
        option_width = widest_flag + widest_shorthand + 5 + USAGE_PADDING
        var options_style = style.width(option_width)

        builder.write("\nOptions:")
        for flag in command[].flags:
            var option = String("\n  ")
            if flag[].shorthand:
                option.write("-", flag[].shorthand, ", ")
            option.write("--", flag[].name)
            builder.write(options_style.render(option), flag[].usage)

        builder.write("\n")

    if command[].children:
        var options_style = style.width(option_width - 2)
        builder.write("\nCommands:")
        for i in range(len(command[].children)):
            builder.write("\n  ", options_style.render(command[].children[i][].name), command[].children[i][].usage)
        builder.write("\n")

    if command[].aliases:
        builder.write("\nAliases:\n  ")
        for i in range(len(command[].aliases)):
            builder.write(command[].aliases[i])

            if i < len(command[].aliases) - 1:
                builder.write(", ")
        builder.write("\n")

    return builder^


alias CmdFn = fn (ctx: Context) -> None
"""The function for a command to run."""
alias RaisingCmdFn = fn (ctx: Context) raises -> None
"""The function for a command to run that can error."""
alias HelpFn = fn (command: ArcPointer[Command]) raises -> String
"""The function to generate help output."""
alias ArgValidatorFn = fn (ctx: Context) raises -> None
"""The function for an argument validator."""
alias ParentVisitorFn = fn (parent: ArcPointer[Command]) capturing -> None
"""The function for visiting parents of a command."""
alias ExitFn = fn (Error) -> None
"""The function to call when an error occurs."""
alias VersionFn = fn (String) -> String
"""The function to call when the version flag is passed."""
alias WriterFn = fn (String) -> None
"""The function to call when writing output or errors."""


fn default_output_writer(arg: String) -> None:
    """Writes an output message to stdout.

    Args:
        arg: The output message to write.
    """
    print(arg)


fn default_error_writer(arg: String) -> None:
    """Writes an error message to stderr.

    Args:
        arg: The error message to write.
    """
    print(arg, file=2)


# TODO: For now it's locked to False until file scope variables.
alias ENABLE_TRAVERSE_RUN_HOOKS = False
"""Set to True to traverse all parents' persistent pre and post run hooks. If False, it'll only run the first match.
If False, starts from the child command and goes up the parent chain. If True, starts from root and goes down."""


fn default_exit(e: Error) -> None:
    """The default function to call when an error occurs.

    Args:
        e: The error that occurred.
    """
    panic(e)


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

    var help: HelpFn
    """Generates help text."""
    var exit: ExitFn
    """Function to call when an error occurs."""
    var version: Optional[String]
    """The version of the application."""
    var version_writer: Optional[VersionFn]
    """Function to call when the version flag is passed."""
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

    fn __init__(
        out self,
        name: String,
        usage: String,
        *,
        args_usage: Optional[String] = None,
        aliases: List[String] = List[String](),
        exit: ExitFn = default_exit,
        version: Optional[String] = None,
        version_writer: Optional[VersionFn] = None,
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
    ):
        """Constructs a new `Command`.

        Args:
            name: The name of the command.
            usage: The usage of the command.
            args_usage: The usage of the arguments for the command.
            aliases: The aliases for the command.
            exit: The function to call when an error occurs.
            version: The function to call when the version flag is passed.
            version_writer: The function to call when the version flag is passed.
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
        """
        if not run and not raising_run:
            panic("A command must have a run or raising_run function.")

        self.name = name
        self.usage = usage
        self.args_usage = args_usage
        self.aliases = aliases

        self.exit = exit
        self.help = default_help
        self.version = version
        self.version_writer = version_writer
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

        if arg_validator:
            self.arg_validator = arg_validator.value()
        else:
            self.arg_validator = arbitrary_args

        self.valid_args = valid_args

        self.flags = flags

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

        self.flags.append(Flag.bool(name="help", shorthand="h", usage="Displays help information about the command."))
        if self.version:
            self.flags.append(Flag.bool(name="version", shorthand="v", usage="Displays the version of the command."))

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
        self.version_writer = existing.version_writer^
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

        var input_args = _parse_args_from_command_line(argv())

        # Read from stdin and parse the arguments.
        if self.read_from_stdin:
            try:
                # TODO: Switch from readline to reading until EOF
                input_args.extend(_parse_args_from_stdin(_fdopen["r"](0).readline()))
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

        try:
            # Parse the flags for the command to be executed.
            var remaining_args = command_ptr[].flags.from_args(args)

            # Check if the help flag was passed
            if command_ptr[].flags.get_bool("help") == True:
                self.output_writer(command_ptr[].help(command_ptr))
                return

            # Check if the help flag was passed
            if self.version and command_ptr[].flags.get_bool("version") == True:
                var output: String
                if command_ptr[].version_writer:
                    output = command_ptr[].version_writer.value()(command_ptr[].version.value())
                else:
                    output = command_ptr[].version.value()
                self.output_writer(output)
                return

            # Validate individual required flags (eg: flag is required)
            command_ptr[].flags.validate_required_flags()

            # Validate flag groups (eg: one of required, mutually exclusive, required together)
            command_ptr[].flags.validate_flag_groups()

            # Run flag actions if they have any
            var ctx = Context(remaining_args, command_ptr)

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
                self.flags.set_annotation[annotation](name[], " ".join(flag_names))
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
