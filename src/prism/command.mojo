from sys import argv
from collections import Optional, Dict, InlineList
from memory import ArcPointer
import mog
from ._util import to_string, to_list, string_to_bool, panic
from .flag import Flag, FType, bool_flag
from ._flag_set import (
    visit_all,
    validate_required_flags,
    from_args,
    REQUIRED,
    REQUIRED_AS_GROUP,
    ONE_REQUIRED,
    MUTUALLY_EXCLUSIVE,
    set_as,
    set_annotation,
    lookup
)
from ._flag_group import validate_flag_groups
from .args import arbitrary_args, get_args
from .context import Context


fn _concat_names(flag_names: VariadicListMem[String, _]) -> String:
    """Concatenates the flag names into a single string.

    Args:
        flag_names: The flag names to concatenate.

    Returns:
        The concatenated flag names.
    """
    var result = String()
    for i in range(len(flag_names)):
        result.write(flag_names[i])
        if i != len(flag_names) - 1:
            result.write(" ")

    return result


fn _concat_names(flag_names: List[String]) -> String:
    """Concatenates the flag names into a single string.

    Args:
        flag_names: The flag names to concatenate.

    Returns:
        The concatenated flag names.
    """
    var result = String()
    for i in range(len(flag_names)):
        result.write(flag_names[i])
        if i != len(flag_names) - 1:
            result.write(" ")

    return result


fn _get_args_as_list() -> List[String]:
    """Returns the arguments passed to the executable as a list of strings.

    Returns:
        The arguments passed to the executable as a list of strings.
    """
    var args = argv()
    var result = List[String](capacity=len(args))
    var i = 1
    while i < len(args):
        result.append(args[i])
        i += 1

    return result


alias NEWLINE = ord("\n")


fn default_help(mut command: ArcPointer[Command]) raises -> String:
    """Prints the help information for the command.

    Args:
        command: The command to generate help information for.

    Returns:
        The help information for the command.

    Raises:
        Any error that occurs while generating the help information.
    """
    var usage_style = mog.Style().border(mog.HIDDEN_BORDER)
    var border_style = mog.Style().border(mog.ROUNDED_BORDER).border_foreground(mog.Color(0x383838)).padding(0, 1)
    var option_style = mog.Style().foreground(mog.Color(0x81C8BE))
    var bold_style = mog.Style().bold()

    var builder = String()
    builder.write(mog.Style().bold().foreground(mog.Color(0xE5C890)).render("Usage: "))
    builder.write(bold_style.render(command[].full_name()))

    if len(command[].flags) > 0:
        builder.write(" [OPTIONS]")
    if len(command[].children) > 0:
        builder.write(" COMMAND")
    builder.write(" [ARGS]...")

    var usage = usage_style.render(mog.join_vertical(mog.left, builder, "\n", command[].usage))

    builder = String()
    if command[].flags:
        builder.write(bold_style.render("Options"))
        for flag in command[].flags:
            builder.write(option_style.render("\n-{}, --{}".format(flag[].shorthand, flag[].name)))
            builder.write("    {}".format(flag[].usage))
    var options = border_style.render(builder)

    builder = String()
    if command[].children:
        builder.write(bold_style.render("Commands"))
        for i in range(len(command[].children)):
            builder.write("\n{}    {}".format(option_style.render(command[].children[i][].name), command[].children[i][].usage))

            if i == len(command[].children) - 1:
                builder.write("\n")

    if command[].aliases:
        builder.write(bold_style.render("Aliases"))
        builder.write("\n{}".format(option_style.render(command[].aliases.__str__())))

    return mog.join_vertical(mog.left, usage, options, border_style.render(builder))


alias CmdFn = fn (ctx: Context) -> None
"""The function for a command to run."""
alias RaisingCmdFn = fn (ctx: Context) raises -> None
"""The function for a command to run that can error."""
alias HelpFn = fn (mut command: ArcPointer[Command]) raises -> String
"""The function to generate help output."""
alias ArgValidatorFn = fn (ctx: Context) raises -> None
"""The function for an argument validator."""
alias ParentVisitorFn = fn (parent: ArcPointer[Command]) capturing -> None
"""The function for visiting parents of a command."""

# TODO: For now it's locked to False until file scope variables.
alias ENABLE_TRAVERSE_RUN_HOOKS = False
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
    var aliases: List[String]
    """Aliases that can be used instead of the first word in name."""
    var help: HelpFn
    """Generates help text."""

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

    var flags: List[Flag]
    """It is all local, persistent, and inherited flags."""

    var children: List[ArcPointer[Self]]
    """Child commands."""
    # TODO: An optional pointer would be great, but it breaks the compiler. So a list of 0-1 pointers is used.
    var parent: List[ArcPointer[Self]]
    """Parent command."""

    fn __init__(
        mut self,
        name: String,
        usage: String,
        *,
        aliases: List[String] = List[String](),
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
        flags: List[Flag] = List[Flag](),
        flags_required_together: Optional[List[String]] = None,
        mutually_exclusive_flags: Optional[List[String]] = None,
        one_required_flags: Optional[List[String]] = None,
        arg_validator: Optional[ArgValidatorFn] = None,
    ):
        """Constructs a new `Command`.

        Args:
            name: The name of the command.
            usage: The usage of the command.
            aliases: The aliases for the command.
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
        """
        if not run and not raising_run:
            panic("A command must have a run or raising_run function.")

        self.name = name
        self.usage = usage
        self.aliases = aliases

        self.help = default_help

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
            self._mark_flag_group_as[REQUIRED_AS_GROUP](flags_required_together.value())
        if mutually_exclusive_flags:
            self._mark_flag_group_as[MUTUALLY_EXCLUSIVE](mutually_exclusive_flags.value())
        if one_required_flags:
            self._mark_flag_group_as[ONE_REQUIRED](one_required_flags.value())

        self.flags.append(bool_flag(name="help", shorthand="h", usage="Displays help information about the command."))

    fn __moveinit__(mut self, owned existing: Self):
        """Initializes a new `Command` by moving the fields from an existing `Command`.

        Args:
            existing: The existing `Command` to move the fields from.
        """
        self.name = existing.name^
        self.usage = existing.usage^
        self.aliases = existing.aliases^

        self.help = existing.help

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
            writer.write(self.flags.__str__())
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
        for cmd in children:
            if cmd[][].name == arg or arg in cmd[][].aliases:
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

        return command, remaining_args

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
            print("Failed to run pre-run hooks for command: " + ctx.command[].name, file=2)
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
            print("Failed to run post-run hooks for command: " + ctx.command[].name, file=2)
            raise e

    fn execute(self) -> None:
        """Traverses the arguments passed to the executable and executes the last command in the branch."""
        # Traverse from the root command through the children to find a match for the current argument.
        # Any additional arguments past the last matched command name are considered arguments.
        # TODO: Tree traversal is new to me, there's probably a better way to do this.

        # Always execute from the root command, regardless of what command was executed in main.
        if self.has_parent():
            return self.root()[].execute()

        command, remaining_args = self._parse_command_from_args(_get_args_as_list())
        var command_ptr = ArcPointer(command^) # Give ownership to the pointer, for consistency.

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
            # Get the flags for the command to be executed.
            remaining_args = from_args(command_ptr[].flags, remaining_args)

            # Check if the help flag was passed
            if command_ptr[].get_bool("help") == True:
                print(command_ptr[].help(command_ptr))
                return

            # Validate individual required flags (eg: flag is required)
            validate_required_flags(command_ptr[].flags)

            # Validate flag groups (eg: one of required, mutually exclusive, required together)
            validate_flag_groups(command_ptr[].flags)

            # Run flag actions if they have any
            var ctx = Context(remaining_args, command_ptr)

            @parameter
            fn run_action(flag: Flag) raises -> None:
                if flag.action and flag.value:
                    flag.action.value()(ctx, flag.value.value())

            visit_all[run_action](command_ptr[].flags)

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
            panic(e)

    fn inherited_flags(self) -> List[Flag]:
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
        return flags

    fn _merge_flags(mut self):
        """Returns all flags for the command and inherited flags from its parent."""
        self.flags += self.inherited_flags()

    fn _mark_flag_group_as[annotation: String](mut self, flag_names: List[String]) -> None:
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
        constrained[
            annotation not in [REQUIRED_AS_GROUP, ONE_REQUIRED, MUTUALLY_EXCLUSIVE],
            "annotation must be one of REQUIRED_AS_GROUP, ONE_REQUIRED, or MUTUALLY_EXCLUSIVE.",
        ]()
        self._merge_flags()
        try:
            for flag_name in flag_names:
                set_as[annotation](self.flags, flag_name[], _concat_names(flag_names))
        except e:
            panic(e)

    fn has_parent(self) -> Bool:
        """Returns True if the command has a parent, False otherwise.

        Returns:
            True if the command has a parent, False otherwise.
        """
        return self.parent.__bool__()

    fn visit_parents[func: ParentVisitorFn](self) -> None:
        """Visits all parents of the command and invokes func on each parent.

        Parameters:
            func: The function to invoke on each parent.
        """
        if self.has_parent():
            func(self.parent[0][])
            self.parent[0][].visit_parents[func]()

    fn get_string(self, name: String) raises -> String:
        """Returns the value of a flag as a `String`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `String`.

        Raises:
            Error: If the flag is not found.
        """
        return lookup[FType.String](self.flags, name)[].value_or_default()

    fn get_bool(self, name: String) raises -> Bool:
        """Returns the value of a flag as a `Bool`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Bool`.

        Raises:
            Error: If the flag is not found.
        """
        return string_to_bool(lookup["Bool"](self.flags, name)[].value_or_default())

    fn get_int[type: String = "Int"](self, name: String) raises -> Int:
        """Returns the value of a flag as an `Int`. If it isn't set, then return the default value.

        Parameters:
            type: The type of the flag.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as an `Int`.

        Raises:
            Error: If the flag is not found.
        """
        constrained[type not in FType.IntTypes, "type must be one of `Int`, `Int8`, `Int16`, `Int32`, `Int64`, `UInt`, `UInt8`, `UInt16`, `UInt32`, or `UInt64`."]()
        return atol(lookup[type](self.flags, name)[].value_or_default())

    fn get_int8(self, name: String) raises -> Int8:
        """Returns the value of a flag as a `Int8`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Int8`.

        Raises:
            Error: If the flag is not found.
        """
        return Int8(self.get_int[FType.Int8](name))

    fn get_int16(self, name: String) raises -> Int16:
        """Returns the value of a flag as a `Int16`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Int16`.

        Raises:
            Error: If the flag is not found.
        """
        return Int16(self.get_int[FType.Int16](name))

    fn get_int32(self, name: String) raises -> Int32:
        """Returns the value of a flag as a `Int32`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Int32`.

        Raises:
            Error: If the flag is not found.
        """
        return Int32(self.get_int[FType.Int32](name))

    fn get_int64(self, name: String) raises -> Int64:
        """Returns the value of a flag as a `Int64`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Int64`.

        Raises:
            Error: If the flag is not found.
        """
        return Int64(self.get_int[FType.Int64](name))

    fn get_uint(self, name: String) raises -> UInt:
        """Returns the value of a flag as a `UInt`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `UInt`.

        Raises:
            Error: If the flag is not found.
        """
        return UInt(self.get_int[FType.UInt](name))

    fn get_uint8(self, name: String) raises -> UInt8:
        """Returns the value of a flag as a `UInt8`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `UInt8`.

        Raises:
            Error: If the flag is not found.
        """
        return UInt8(self.get_int[FType.UInt8](name))

    fn get_uint16(self, name: String) raises -> UInt16:
        """Returns the value of a flag as a `UInt16`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `UInt16`.

        Raises:
            Error: If the flag is not found.
        """
        return UInt16(self.get_int[FType.UInt16](name))

    fn get_uint32(self, name: String) raises -> UInt32:
        """Returns the value of a flag as a `UInt32`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `UInt32`.

        Raises:
            Error: If the flag is not found.
        """
        return UInt32(self.get_int[FType.UInt32](name))

    fn get_uint64(self, name: String) raises -> UInt64:
        """Returns the value of a flag as a `UInt64`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `UInt64`.

        Raises:
            Error: If the flag is not found.
        """
        return UInt64(self.get_int[FType.UInt64](name))
    
    fn get_float[type: String](self, name: String) raises -> Float64:
        """Returns the value of a flag as a `Float64`. If it isn't set, then return the default value.

        Parameters:
            type: The type of the flag.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Float64`.

        Raises:
            Error: If the flag is not found.
        """
        constrained[type not in FType.FloatTypes, "type must be one of `Float16`, `Float32`, `Float64`"]()
        return atof(lookup[type](self.flags, name)[].value_or_default())

    fn get_float16(self, name: String) raises -> Float16:
        """Returns the value of a flag as a `Float16`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Float16`.

        Raises:
            Error: If the flag is not found.
        """
        return self.get_float[FType.Float16](name).cast[DType.float16]()

    fn get_float32(self, name: String) raises -> Float32:
        """Returns the value of a flag as a `Float32`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Float32`.

        Raises:
            Error: If the flag is not found.
        """
        return self.get_float[FType.Float32](name).cast[DType.float32]()

    fn get_float64(self, name: String) raises -> Float64:
        """Returns the value of a flag as a `Float64`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Float64`.
            
        Raises:
            Error: If the flag is not found.
        """
        return self.get_float[FType.Float64](name)

    fn _get_list[type: String](self, name: String) raises -> List[String]:
        """Returns the value of a flag as a `List[String]`. If it isn't set, then return the default value.

        Parameters:
            type: The type of the flag.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `List[String]`.

        Raises:
            Error: If the flag is not found.
        """
        constrained[type not in FType.ListTypes, "type must be one of `StringList`, `IntList`, or `Float64List`."]()
        return lookup[type](self.flags, name)[].value_or_default().split(sep=" ")

    fn get_string_list(self, name: String) raises -> List[String]:
        """Returns the value of a flag as a `List[String]`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `List[String]`.

        Raises:
            Error: If the flag is not found.
        """
        return self._get_list[FType.StringList](name)

    fn get_int_list(self, name: String) raises -> List[Int]:
        """Returns the value of a flag as a `List[Int]`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `List[Int]`.

        Raises:
            Error: If the flag is not found.
        """
        var values = self._get_list[FType.IntList](name)
        var ints = List[Int](capacity=len(values))
        for value in values:
            ints.append(atol(value[]))
        return ints

    fn get_float64_list(self, name: String) raises -> List[Float64]:
        """Returns the value of a flag as a `List[Float64]`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `List[Float64]`.

        Raises:
            Error: If the flag is not found.
        """
        var values = self._get_list[FType.Float64List](name)
        var floats = List[Float64](capacity=len(values))
        for value in values:
            floats.append(atof(value[]))
        return floats
