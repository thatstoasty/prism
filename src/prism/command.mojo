from sys import argv
from collections import Optional, Dict, InlineList
from memory import ArcPointer
from os import abort
import mog
from .util import to_string, to_list, string_to_bool
from .flag import Flag
from .flag_set import (
    visit_all,
    validate_required_flags,
    from_args,
    REQUIRED,
    REQUIRED_AS_GROUP,
    ONE_REQUIRED,
    MUTUALLY_EXCLUSIVE,
    set_as,
    set_annotation,
    bool_flag,
    string_flag,
)
from .flag_group import validate_flag_groups
from .args import arbitrary_args, get_args
from .context import Context


fn concat_names(flag_names: VariadicListMem[String, _]) -> String:
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


fn get_args_as_list() -> List[String]:
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

    var cmd = command
    var builder = String()
    builder.write(mog.Style().bold().foreground(mog.Color(0xE5C890)).render("Usage: "))
    builder.write(bold_style.render(cmd[].full_name()))

    if len(cmd[].flags) > 0:
        builder.write(" [OPTIONS]")
    if len(cmd[].children) > 0:
        builder.write(" COMMAND")
    builder.write(" [ARGS]...")

    var usage = usage_style.render(mog.join_vertical(mog.left, builder, "\n", cmd[].usage))

    builder = String()
    if cmd[].flags:
        builder.write(bold_style.render("Options"))
        for flag in cmd[].flags:
            builder.write(option_style.render("\n-{}, --{}".format(flag[].shorthand, flag[].name)))
            builder.write("    {}".format(flag[].usage))
    var options = border_style.render(builder)

    builder = String()
    if cmd[].children:
        builder.write(bold_style.render("Commands"))
        for i in range(len(cmd[].children)):
            builder.write("\n{}    {}".format(option_style.render(cmd[].children[i][].name), cmd[].children[i][].usage))

            if i == len(cmd[].children) - 1:
                builder.write("\n")

    if cmd[].aliases:
        builder.write(bold_style.render("Aliases"))
        builder.write("\n{}".format(option_style.render(cmd[].aliases.__str__())))

    var commands = border_style.render(builder)
    return mog.join_vertical(mog.left, usage, options, commands)


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

    var local_flags: List[Flag]
    """Local flags for the command. TODO: Use this field to store cached results for local flags."""

    var persistent_flags: List[Flag]
    """Local flags that also persist to children."""

    var flags: List[Flag]
    """It is all local, persistent, and inherited flags."""

    var _inherited_flags: List[Flag]
    """Cached results from self._merge_flags()."""

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
        """
        if not run and not raising_run:
            abort("A command must have a run or raising_run function.")

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

        self.arg_validator = arbitrary_args
        self.valid_args = valid_args

        self.children = children
        self.parent = List[ArcPointer[Self]](capacity=1)

        # These need to be mutable so we can add flags to them.
        self.flags = flags
        self.local_flags = List[Flag]()
        self.persistent_flags = List[Flag]()
        self._inherited_flags = List[Flag]()
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
        self.local_flags = existing.local_flags^
        self.persistent_flags = existing.persistent_flags^
        self._inherited_flags = existing._inherited_flags^

        self.children = existing.children^
        self.parent = existing.parent^

    fn __str__(self) -> String:
        """Returns a string representation of the `Command`.

        Returns:
            The string representation of the `Command`.
        """
        return String.write(self)

    fn write_to[W: Writer, //](self, mut writer: W):
        """Write Flag string representation to a `Formatter`.

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
        for command_ref in children:
            if command_ref[][].name == arg or arg in command_ref[][].aliases:
                leftover_start += 1
                return command_ref[][], command_ref[][].children

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
            var root = self.root()
            return root[].execute()

        command, remaining_args = self._parse_command_from_args(get_args_as_list())

        # Merge local and inherited flags
        command._merge_flags()

        # Add all parents to the list to check if they have persistent pre/post hooks.
        var parents = List[ArcPointer[Self]]()

        @parameter
        fn append_parents(parent: ArcPointer[Self]) capturing -> None:
            parents.append(parent)

        command.visit_parents[append_parents]()

        # If ENABLE_TRAVERSE_RUN_HOOKS is True, reverse the list to start from the root command rather than
        # from the child. This is because all of the persistent hooks will be run.
        @parameter
        if ENABLE_TRAVERSE_RUN_HOOKS:
            parents.reverse()

        try:
            # Get the flags for the command to be executed.
            var remaining_args = from_args(command.flags, remaining_args)

            # Check if the help flag was passed
            var help_passed = command.get_bool("help")
            var command_ref = ArcPointer(command)
            if help_passed == True:
                print(command.help(command_ref))
                return None

            # Validate individual required flags (eg: flag is required)
            validate_required_flags(command.flags)

            # Validate flag groups (eg: one of required, mutually exclusive, required together)
            validate_flag_groups(command.flags)

            # Run flag actions if they have any
            var ctx = Context(remaining_args, command_ref)

            @parameter
            fn run_action(flag: Flag) raises -> None:
                if flag.action and flag.value:
                    flag.action.value()(ctx, flag.value.value())

            visit_all[run_action](command.flags)

            # Validate the remaining arguments
            command.arg_validator(ctx)

            # Run the function's commands.
            self._execute_pre_run_hooks(ctx, parents)
            if command.run:
                command.run.value()(ctx)
            else:
                command.raising_run.value()(ctx)
            self._execute_post_run_hooks(ctx, parents)
        except e:
            abort(e)

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
            # if parent[].persistent_flags:
            #     flags += parent[].persistent_flags

        self.visit_parents[add_parent_persistent_flags]()
        return flags

    fn _merge_flags(mut self):
        """Returns all flags for the command and inherited flags from its parent."""
        self.flags += self.persistent_flags
        self._inherited_flags = self.inherited_flags()
        self.flags += self._inherited_flags

    fn add_subcommand(mut self, mut command: ArcPointer[Self]):
        """Adds child command and set's child's parent attribute to self.

        Args:
            command: The command to add as a child of self.
        """
        self.children.append(command)
        if command[].parent:
            command[].parent[0] = self
        else:
            command[].parent.append(self)

    # fn mark_flag_required(mut self, flag_name: String) -> None:
    #     """Marks the given flag with annotations so that `Prism` errors
    #     if the command is invoked without the flag.

    #     Args:
    #         flag_name: The name of the flag to mark as required.
    #     """
    #     try:
    #         self.flags.set_required(flag_name)
    #     except e:
    #         abort(e)

    fn mark_flags_required_together(mut self, *flag_names: String) -> None:
        """Marks the given flags with annotations so that `Prism` errors
        if the command is invoked with a subset (but not all) of the given flags.

        Args:
            flag_names: The names of the flags to mark as required together.
        """
        self._merge_flags()
        var names = concat_names(flag_names)
        try:
            for flag_name in flag_names:
                set_as[REQUIRED_AS_GROUP](self.flags, flag_name[], names)
        except e:
            abort(e)

    fn mark_flags_one_required(mut self, *flag_names: String) -> None:
        """Marks the given flags with annotations so that `Prism` errors
        if the command is invoked without at least one flag from the given set of flags.

        Args:
            flag_names: The names of the flags to mark as required.
        """
        self._merge_flags()
        var names = concat_names(flag_names)
        try:
            for flag_name in flag_names:
                set_as[ONE_REQUIRED](self.flags, flag_name[], names)
        except e:
            abort(e)

    fn mark_flags_mutually_exclusive(mut self, *flag_names: String) -> None:
        """Marks the given flags with annotations so that `Prism` errors
        if the command is invoked with more than one flag from the given set of flags.

        Args:
            flag_names: The names of the flags to mark as mutually exclusive.
        """
        self._merge_flags()
        var names = concat_names(flag_names)
        try:
            for flag_name in flag_names:
                set_as[MUTUALLY_EXCLUSIVE](self.flags, flag_name[], names)
        except e:
            abort(e)

    # fn mark_persistent_flag_required(mut self, flag_name: String) -> None:
    #     """Marks the given persistent flag with annotations so that `Prism` errors
    #     if the command is invoked without the flag.

    #     Args:
    #         flag_name: The name of the flag to mark as required.
    #     """
    #     try:
    #         self.persistent_flags.set_required(flag_name)
    #     except e:
    #         abort(e)

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

    fn lookup(ref self, name: String, type: String = "") raises -> Pointer[Flag, __origin_of(self.flags)]:
        """Returns an mutable or immutable Pointer to a Flag with the given name.
        Mutable if FlagSet is mutable, immutable if FlagSet is immutable.

        Args:
            name: The name of the Flag to lookup.
            type: The type of the Flag to lookup.

        Returns:
            Optional Pointer to the Flag.

        Raises:
            Error: If the Flag is not found.
        """
        if type == "":
            for i in range(len(self.flags)):
                if self.flags[i].name == name:
                    return Pointer.address_of(self.flags[i])
        else:
            for i in range(len(self.flags)):
                if self.flags[i].name == name and self.flags[i].type == type:
                    return Pointer.address_of(self.flags[i])

        raise Error("FlagNotFoundError: Could not find the following flag: " + name)

    fn get_string(self, name: String) raises -> String:
        """Returns the value of a flag as a `String`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `String`.

        Raises:
            Error: If the flag is not found.
        """
        return self.lookup(name, "String")[].value_or_default()

    fn get_bool(self, name: String) raises -> Bool:
        """Returns the value of a flag as a `Bool`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Bool`.

        Raises:
            Error: If the flag is not found.
        """
        return string_to_bool(self.lookup(name, "Bool")[].value_or_default())

    fn get_int(self, name: String, type: String = "Int") raises -> Int:
        """Returns the value of a flag as an `Int`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.
            type: The type of the flag.

        Returns:
            The value of the flag as an `Int`.

        Raises:
            Error: If the flag is not found.
        """
        return atol(self.lookup(name, type)[].value_or_default())

    fn get_int8(self, name: String) raises -> Int8:
        """Returns the value of a flag as a `Int8`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Int8`.

        Raises:
            Error: If the flag is not found.
        """
        return Int8(self.get_int(name, "Int8"))

    fn get_int16(self, name: String) raises -> Int16:
        """Returns the value of a flag as a `Int16`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Int16`.

        Raises:
            Error: If the flag is not found.
        """
        return Int16(self.get_int(name, "Int16"))

    fn get_int32(self, name: String) raises -> Int32:
        """Returns the value of a flag as a `Int32`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Int32`.

        Raises:
            Error: If the flag is not found.
        """
        return Int32(self.get_int(name, "Int32"))

    fn get_int64(self, name: String) raises -> Int64:
        """Returns the value of a flag as a `Int64`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Int64`.

        Raises:
            Error: If the flag is not found.
        """
        return Int64(self.get_int(name, "Int64"))

    fn get_uint(self, name: String) raises -> UInt:
        """Returns the value of a flag as a `UInt`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `UInt`.

        Raises:
            Error: If the flag is not found.
        """
        return UInt(self.get_int(name, "UInt"))

    fn get_uint8(self, name: String) raises -> UInt8:
        """Returns the value of a flag as a `UInt8`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `UInt8`.

        Raises:
            Error: If the flag is not found.
        """
        return UInt8(self.get_int(name, "UInt8"))

    fn get_uint16(self, name: String) raises -> UInt16:
        """Returns the value of a flag as a `UInt16`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `UInt16`.

        Raises:
            Error: If the flag is not found.
        """
        return UInt16(self.get_int(name, "UInt16"))

    fn get_uint32(self, name: String) raises -> UInt32:
        """Returns the value of a flag as a `UInt32`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `UInt32`.

        Raises:
            Error: If the flag is not found.
        """
        return UInt32(self.get_int(name, "UInt32"))

    fn get_uint64(self, name: String) raises -> UInt64:
        """Returns the value of a flag as a `UInt64`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `UInt64`.

        Raises:
            Error: If the flag is not found.
        """
        return UInt64(self.get_int(name, "UInt64"))

    fn get_float16(self, name: String) raises -> Float16:
        """Returns the value of a flag as a `Float16`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Float16`.

        Raises:
            Error: If the flag is not found.
        """
        return self.get_float64(name).cast[DType.float16]()

    fn get_float32(self, name: String) raises -> Float32:
        """Returns the value of a flag as a `Float32`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Float32`.

        Raises:
            Error: If the flag is not found.
        """
        return self.get_float64(name).cast[DType.float32]()

    fn get_float64(self, name: String) raises -> Float64:
        """Returns the value of a flag as a `Float64`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `Float64`.

        Raises:
            Error: If the flag is not found.
        """
        return atof(self.lookup(name, "Float64")[].value_or_default())

    fn _get_list(self, name: String, type: String) raises -> List[String]:
        """Returns the value of a flag as a `List[String]`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.
            type: The type of the flag.

        Returns:
            The value of the flag as a `List[String]`.

        Raises:
            Error: If the flag is not found.
        """
        return self.lookup(name, type)[].value_or_default().split(sep=" ")

    fn get_string_list(self, name: String) raises -> List[String]:
        """Returns the value of a flag as a `List[String]`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `List[String]`.

        Raises:
            Error: If the flag is not found.
        """
        return self._get_list(name, "StringList")

    fn get_int_list(self, name: String) raises -> List[Int]:
        """Returns the value of a flag as a `List[Int]`. If it isn't set, then return the default value.

        Args:
            name: The name of the flag.

        Returns:
            The value of the flag as a `List[Int]`.

        Raises:
            Error: If the flag is not found.
        """
        var values = self._get_list(name, "IntList")
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
        var values = self._get_list(name, "Float64List")
        var floats = List[Float64](capacity=len(values))
        for value in values:
            floats.append(atof(value[]))
        return floats
