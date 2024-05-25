from sys import argv
from collections.optional import Optional
from memory.arc import Arc
from external.gojo.fmt import sprintf
from external.gojo.builtins import panic
from external.gojo.strings import StringBuilder
from .flag import Flag, get_flags
from .flag_set import FlagSet, process_flag_for_group_annotation, validate_flag_groups

# from .args import arbitrary_args, get_args
from .vector import join, to_string, contains

# Individual flag annotations
alias REQUIRED = "REQUIRED"

# Flag Group annotations
alias REQUIRED_AS_GROUP = "REQUIRED_AS_GROUP"
alias ONE_REQUIRED = "ONE_REQUIRED"
alias MUTUALLY_EXCLUSIVE = "MUTUALLY_EXCLUSIVE"


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
    var cmd = command
    var builder = StringBuilder()
    _ = builder.write_string(cmd[].description)

    if cmd[].aliases:
        _ = builder.write_string("\n\nAliases:")
        _ = builder.write_string(sprintf("\n  %s", to_string(cmd[].aliases)))

    # Build usage statement arguments depending on the command's children and flags.
    var full_command = cmd[]._full_command()
    _ = builder.write_string(sprintf("\n\nUsage:\n  %s%s", full_command, String(" [args]")))
    if len(cmd[].children) > 0:
        _ = builder.write_string(" [command]")
    if len(cmd[].flags) > 0:
        _ = builder.write_string(" [flags]")

    if cmd[].children:
        _ = builder.write_string("\n\nAvailable commands:")
        for child in cmd[].children:
            _ = builder.write_string(sprintf("\n  %s", str(child[][])))

    if cmd[].flags.flags:
        _ = builder.write_string("\n\nAvailable flags:")
        for flag in cmd[].flags.flags:
            _ = builder.write_string(sprintf("\n  -%s, --%s    %s", flag[].shorthand, flag[].name, flag[].usage))

    _ = builder.write_string(
        sprintf('\n\nUse "%s [command] --help" for more information about a command.', full_command)
    )
    return str(builder)


# alias CommandArc = Arc[Command]
alias CommandFn = fn (FlagSet, List[String]) -> None
alias CommandFnErr = fn (FlagSet, List[String]) -> Error
alias HelpFn = fn (Arc[Command]) -> String
alias ParentVisitorFn = fn (Arc[Command]) capturing -> None

# Set to True to traverse all parents' persistent pre and post run hooks. If False, it'll only run the first match.
# If False, starts from the child command and goes up the parent chain. If True, starts from root and goes down.
# TODO: For now it's locked to False until file scope variables.
alias ENABLE_TRAVERSE_RUN_HOOKS = False


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
        persisting_pre_run: The function to run before the command is executed. This persists to children.
        persisting_post_run: The function to run after the command is executed. This persists to children.
        persisting_erroring_pre_run: The function to run before the command is executed that returns an error. This persists to children.
        persisting_erroring_post_run: The function to run after the command is executed that returns an error. This persists to children.
        help: The function to generate help text for the command.
    """

    var name: String
    var description: String

    # Aliases that can be used instead of the first word in name.
    var aliases: List[String]

    # Generates help text.
    var help: HelpFn

    # The group id under which this subcommand is grouped in the 'help' output of its parent.
    var group_id: String

    var pre_run: Optional[CommandFn]
    var run: Optional[CommandFn]
    var post_run: Optional[CommandFn]

    var erroring_pre_run: Optional[CommandFnErr]
    var erroring_run: Optional[CommandFnErr]
    var erroring_post_run: Optional[CommandFnErr]

    var persistent_pre_run: Optional[CommandFn]
    var persistent_post_run: Optional[CommandFn]

    var persistent_erroring_pre_run: Optional[CommandFnErr]
    var persistent_erroring_post_run: Optional[CommandFnErr]

    var arg_validator: ArgValidatorFn
    var valid_args: List[String]

    # Local flags for the command. TODO: Use this field to store cached results for local flags.
    var local_flags: FlagSet

    # Local flags that also persist to children.
    var persistent_flags: FlagSet

    # It is all local, persistent, and inherited flags.
    var flags: FlagSet

    # Cached results from self._merge_flags().
    var _inherited_flags: FlagSet

    var children: List[Arc[Self]]
    var parent: Arc[Optional[Self]]

    fn __init__(
        inout self,
        name: String,
        description: String,
        aliases: List[String] = List[String](),
        valid_args: List[String] = List[String](),
        run: Optional[CommandFn] = None,
        pre_run: Optional[CommandFn] = None,
        post_run: Optional[CommandFn] = None,
        erroring_run: Optional[CommandFnErr] = None,
        erroring_pre_run: Optional[CommandFnErr] = None,
        erroring_post_run: Optional[CommandFnErr] = None,
        persistent_pre_run: Optional[CommandFn] = None,
        persistent_post_run: Optional[CommandFn] = None,
        persistent_erroring_pre_run: Optional[CommandFnErr] = None,
        persistent_erroring_post_run: Optional[CommandFnErr] = None,
        # help: HelpFn = default_help
    ):
        if not run and not erroring_run:
            panic("A command must have a run or erroring_run function.")

        self.name = name
        self.description = description
        self.aliases = aliases

        self.help = default_help
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
    fn __init__[
        arg_validator: ArgValidatorFn
    ](
        inout self,
        name: String,
        description: String,
        aliases: List[String] = List[String](),
        valid_args: List[String] = List[String](),
        run: Optional[CommandFn] = None,
        pre_run: Optional[CommandFn] = None,
        post_run: Optional[CommandFn] = None,
        erroring_run: Optional[CommandFnErr] = None,
        erroring_pre_run: Optional[CommandFnErr] = None,
        erroring_post_run: Optional[CommandFnErr] = None,
        persistent_pre_run: Optional[CommandFn] = None,
        persistent_post_run: Optional[CommandFn] = None,
        persistent_erroring_pre_run: Optional[CommandFnErr] = None,
        persistent_erroring_post_run: Optional[CommandFnErr] = None,
        # help: HelpFn = default_help
    ):
        if not run and not erroring_run:
            panic("A command must have a run or erroring_run function.")

        self.name = name
        self.description = description
        self.aliases = aliases

        self.help = default_help
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

        self.arg_validator = existing.arg_validator
        self.valid_args = existing.valid_args^
        self.flags = existing.flags^
        self.local_flags = existing.local_flags^
        self.persistent_flags = existing.persistent_flags^
        self._inherited_flags = existing._inherited_flags^

        self.children = existing.children^
        self.parent = existing.parent^

    fn __str__(self) -> String:
        return sprintf("(Name: %s, Description: %s)", self.name, self.description)

    fn __repr__(inout self) -> String:
        var parent_name: String = ""
        if self.has_parent():
            parent_name = self.parent[].value()[].name
        return (
            "Name: "
            + self.name
            + "\nDescription: "
            + self.description
            + "\nArgs: "
            + to_string(self.valid_args)
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
            var ancestor: String = self.parent[].value()[]._full_command()
            return ancestor + " " + self.name
        else:
            return self.name

    # fn _root(self: Reference[Self]) -> Arc[Command]:
    #     """Returns the root command of the command tree."""
    #     if self[].has_parent():
    #         return self[].parent.value()[][]._root()

    #     return self[]

    fn validate_flag_groups(self):
        var group_status = Dict[String, Dict[String, Bool]]()
        var one_required_group_status = Dict[String, Dict[String, Bool]]()
        var mutually_exclusive_group_status = Dict[String, Dict[String, Bool]]()

        @always_inline
        fn flag_checker(flag: Reference[Flag]) capturing:
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

    # fn validate_args(self, args: List[String]) -> Optional[String]:
    #     return self.arg_validator(self, args)

    fn parse_command_from_args(self, args: List[String]) -> (Self, List[String]):
        var number_of_args = len(args)
        var command = self
        var children = self.children
        var leftover_args_start_index = 0  # Start at 1 to start slice at the first remaining arg, not the last child command.

        for arg in args:
            for command_ref in children:
                if command_ref[][].name == arg[] or contains(command_ref[][].aliases, arg[]):
                    command = command_ref[][]
                    children = command.children
                    leftover_args_start_index += 1
                    break

        # If the there are more or equivalent args to the index, then there are remaining args to pass to the command.
        var remaining_args = List[String]()
        if number_of_args >= leftover_args_start_index:
            remaining_args = args[leftover_args_start_index:number_of_args]

        return command, remaining_args

    fn execute(self) -> None:
        """Traverses the arguments passed to the executable and executes the last command in the branch."""
        # Traverse from the root command through the children to find a match for the current argument.
        # Any additional arguments past the last matched command name are considered arguments.
        # TODO: Tree traversal is new to me, there's probably a better way to do this.

        # Always execute from the root command, regardless of what command was executed in main.
        # print(self.name)
        # if self.has_parent():
        #     return self._root()[].execute()

        var args = get_args_as_list()
        var remaining_args: List[String]
        var command: Command
        command, remaining_args = self.parse_command_from_args(args)

        # # Merge local and inherited flags
        # command._merge_flags()

        # # Add all parents to the list to check if they have persistent pre/post hooks.
        # var parents = List[Self]()

        # @always_inline
        # fn append_parent(command: Self) capturing -> None:
        #     parents.append(command)

        # command.visit_parents[append_parent]()

        # # If ENABLE_TRAVERSE_RUN_HOOKS is True, reverse the list to start from the root command rather than
        # # from the child. This is because all of the persistent hooks will be run.
        # @parameter
        # if ENABLE_TRAVERSE_RUN_HOOKS:
        #     parents.reverse()

        # # Get the flags for the command to be executed.
        # # store flags as a mutable ref
        # var err: Error
        # remaining_args, err = get_flags(command.flags, remaining_args)
        # if err:
        #     panic(err)

        # # Check if the help flag was passed
        # var help_passed = command.flags.get_as_bool("help")
        # if help_passed.value()[] == True:
        #     print(command.help(command))
        #     return None

        # # Validate individual required flags (eg: flag is required)
        # err = command.validate_required_flags()
        # if err:
        #     panic(err)

        # # Validate flag groups (eg: one of required, mutually exclusive, required together)
        # command.validate_flag_groups()

        # # Validate the remaining arguments
        # var error_message = command.arg_validator(command, remaining_args)
        # if error_message:
        #     panic(error_message.value()[])

        # # Run the persistent pre-run hooks.
        # for parent in parents:
        #     if parent[].persistent_erroring_pre_run:
        #         err = parent[].persistent_erroring_pre_run.value()[](command.flags, remaining_args)
        #         if err:
        #             panic(err)

        #         @parameter
        #         if not ENABLE_TRAVERSE_RUN_HOOKS:
        #             break
        #     else:
        #         if parent[].persistent_pre_run:
        #             parent[].persistent_pre_run.value()[](command.flags, remaining_args)

        #             @parameter
        #             if not ENABLE_TRAVERSE_RUN_HOOKS:
        #                 break

        # # Run the pre-run hooks.
        # if command.pre_run:
        #     command.pre_run.value()[](command.flags, remaining_args)
        # elif command.erroring_pre_run:
        #     err = command.erroring_pre_run.value()[](command.flags, remaining_args)
        #     if err:
        #         panic(err)

        # # Run the function's commands.
        # if command.run:
        #     command.run.value()[](command.flags, remaining_args)
        # else:
        #     err = command.erroring_run.value()[](command.flags, remaining_args)
        #     if err:
        #         panic(err)

        # # Run the persistent post-run hooks.
        # for parent in parents:
        #     if parent[].persistent_erroring_post_run:
        #         err = parent[].persistent_erroring_post_run.value()[](command.flags, remaining_args)
        #         if err:
        #             panic(err)

        #         @parameter
        #         if not ENABLE_TRAVERSE_RUN_HOOKS:
        #             break
        #     else:
        #         if parent[].persistent_post_run:
        #             parent[].persistent_post_run.value()[](command.flags, remaining_args)

        #             @parameter
        #             if not ENABLE_TRAVERSE_RUN_HOOKS:
        #                 break

        # # Run the post-run hooks.
        # if command.post_run:
        #     command.post_run.value()[](command.flags, remaining_args)
        # elif command.erroring_post_run:
        #     err = command.erroring_post_run.value()[](command.flags, remaining_args)
        #     if err:
        #         panic(err)

    fn inherited_flags(self) -> FlagSet:
        """Returns the flags for the command and inherited flags from its parent.

        Returns:
            The flags for the command and its parent.
        """
        var i_flags = FlagSet()

        @always_inline
        fn add_parent_persistent_flags(parent: Arc[Self]) capturing -> None:
            var cmd = parent
            if cmd[].persistent_flags:
                i_flags += cmd[].persistent_flags

        self.visit_parents[add_parent_persistent_flags]()

        return i_flags

    fn _merge_flags(inout self):
        """Returns all flags for the command and inherited flags from its parent."""
        # Set mutability of flag set by initializing it as a var.
        self.flags += self.persistent_flags
        self._inherited_flags = self.inherited_flags()
        self.flags += self._inherited_flags

    fn add_command(inout self, inout command: Command):
        """Adds child command and set's child's parent attribute to self.

        Args:
            command: The command to add as a child of self.
        """
        self.children.append(Arc(command))
        command.parent = self

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
                panic(sprintf("Failed to find flag %s and mark it as being required in a flag group", flag_name[]))

            var flag = maybe_flag.value()[]

            # TODO: This inline join logic is temporary until we can pass around varadic lists or cast it to a list.
            var result: String = ""
            for i in range(len(flag_names)):
                result += flag_names[i]
                if i != len(flag_names) - 1:
                    result += " "
            flag[].annotations[REQUIRED_AS_GROUP] = result
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
                panic(sprintf("Failed to find flag %s and mark it as being in a one-required flag group", flag_name[]))

            var flag = maybe_flag.value()[]
            var result: String = ""
            for i in range(len(flag_names)):
                result += flag_names[i]
                if i != len(flag_names) - 1:
                    result += " "
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
                    sprintf(
                        "Failed to find flag %s and mark it as being in a mutually exclusive flag group", flag_name[]
                    )
                )

            var flag = maybe_flag.value()[]
            var result: String = ""
            for i in range(len(flag_names)):
                result += flag_names[i]
                if i != len(flag_names) - 1:
                    result += " "
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
            func(self.parent[].value()[])
            self.parent[].value()[].visit_parents[func]()

    fn validate_required_flags(self) -> Error:
        """Validates all required flags are present and returns an error otherwise."""
        var missing_flag_names = List[String]()

        fn check_required_flag(flag: Reference[Flag]) capturing -> None:
            var required_annotation = flag[].annotations.get(REQUIRED, List[String]())
            if required_annotation:
                if required_annotation[0] == "true" and not flag[].changed:
                    missing_flag_names.append(flag[].name)

        self.flags.visit_all[check_required_flag]()

        if len(missing_flag_names) > 0:
            return Error("required flag(s) " + to_string(missing_flag_names) + " not set")
        return Error()

    # NOTE: These wrappers are just nice to have. Feels good to call Command().add_flag()
    # instead of Command().flags[].add_flag()
    # fn flag_list(self) -> List[Arc[Flag]]:
    #     """Returns a list of references to all flags in the merged flag set (local, persistent, inherited).

    #     This is just a convenience function to avoid having to call Command().flags[].get_flags().
    #     """
    #     return self.flags.flags

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
        self.flags.add_bool_flag(name=name, usage=usage, default=default, shorthand=shorthand)

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
        self.flags.add_string_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_int_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int = 0) -> None:
        """Adds an Int flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags.add_int_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_int8_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int8 = 0) -> None:
        """Adds an Int8 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags.add_int8_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_int16_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int16 = 0) -> None:
        """Adds an Int16 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags.add_int16_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_int32_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int32 = 0) -> None:
        """Adds an Int32 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags.add_int32_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_int64_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int64 = 0) -> None:
        """Adds an Int64 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags.add_int64_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_uint8_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt8 = 0) -> None:
        """Adds a UInt8 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags.add_uint8_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_uint16_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt16 = 0) -> None:
        """Adds a UInt16 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags.add_uint16_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_uint32_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt32 = 0) -> None:
        """Adds a UInt32 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags.add_uint32_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_uint64_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt64 = 0) -> None:
        """Adds a UInt64 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags.add_uint64_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_float16_flag(inout self, name: String, usage: String, shorthand: String = "", default: Float16 = 0) -> None:
        """Adds a Float16 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags.add_float16_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_float32_flag(inout self, name: String, usage: String, shorthand: String = "", default: Float32 = 0) -> None:
        """Adds a Float32 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags.add_float32_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_float64_flag(inout self, name: String, usage: String, shorthand: String = "", default: Float64 = 0) -> None:
        """Adds a Float64 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags.add_float64_flag(name=name, usage=usage, default=default, shorthand=shorthand)


# from collections.optional import Optional
# from external.gojo.fmt import sprintf
# from .vector import contains
# from .command import Command

alias ArgValidatorFn = fn (UnsafePointer[Command], List[String]) -> Optional[String]


fn no_args(command: UnsafePointer[Command], args: List[String]) -> Optional[String]:
    """Returns an error if the command has any arguments.

    Args:
        command: Reference to the command being executed.
        args: The arguments to check.
    """
    var cmd = command
    if len(args) > 0:
        return sprintf("The command `%s` does not take any arguments.", cmd[].name)
    return None


fn arbitrary_args(command: UnsafePointer[Command], args: List[String]) -> Optional[String]:
    """Never returns an error.

    Args:
        command: Reference to the command being executed.
        args: The arguments to check.
    """
    return None


fn minimum_n_args[n: Int]() -> ArgValidatorFn:
    """Returns an error if there is not at least n arguments.

    Params:
        n: The minimum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn less_than_n_args(command: UnsafePointer[Command], args: List[String]) -> Optional[String]:
        var cmd = command
        if len(args) < n:
            return sprintf(
                "The command `%s` accepts at least %d argument(s). Received: %d.",
                cmd[].name,
                n,
                len(args),
            )
        return None

    return less_than_n_args


fn maximum_n_args[n: Int]() -> ArgValidatorFn:
    """Returns an error if there are more than n arguments.

    Params:
        n: The maximum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn more_than_n_args(command: UnsafePointer[Command], args: List[String]) -> Optional[String]:
        var cmd = command
        if len(args) > n:
            return sprintf("The command `%s` accepts at most %d argument(s). Received: %d.", cmd[].name, n, len(args))
        return None

    return more_than_n_args


fn exact_args[n: Int]() -> ArgValidatorFn:
    """Returns an error if there are not exactly n arguments.

    Params:
        n: The number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn exactly_n_args(command: UnsafePointer[Command], args: List[String]) -> Optional[String]:
        var cmd = command
        if len(args) != n:
            return sprintf("The command `%s` accepts exactly %d argument(s). Received: %d.", cmd[].name, n, len(args))
        return None

    return exactly_n_args


fn valid_args[valid: List[String]]() -> ArgValidatorFn:
    """Returns an error if threre are any positional args that are not in the command's valid_args.

    Params:
        valid: The valid arguments to check against.
    """

    fn only_valid_args(command: UnsafePointer[Command], args: List[String]) -> Optional[String]:
        var cmd = command
        if len(valid) > 0:
            for arg in args:
                if not contains(valid, arg[]):
                    return sprintf("Invalid argument: `%s`, for the command `%s`.", arg[], cmd[].name)
        return None

    return only_valid_args


fn range_args[minimum: Int, maximum: Int]() -> ArgValidatorFn:
    """Returns an error if there are not exactly n arguments.

    Params:
        minimum: The minimum number of arguments.
        maximum: The maximum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn range_n_args(command: UnsafePointer[Command], args: List[String]) -> Optional[String]:
        var cmd = command
        if len(args) < minimum or len(args) > maximum:
            return sprintf(
                "The command `%s`, accepts between %d to %d argument(s). Received: %d.",
                cmd[].name,
                minimum,
                maximum,
                len(args),
            )
        return None

    return range_n_args


# TODO: Having some issues with varadic list of functions, so using List for now.
fn match_all[arg_validators: List[ArgValidatorFn]]() -> ArgValidatorFn:
    """Returns an error if any of the arg_validators return an error.

    Params:
        arg_validators: A list of ArgValidatorFn functions that check the arguments.

    Returns:
        A function that checks all the arguments using the arg_validators list..
    """

    fn match_all_args(command: UnsafePointer[Command], args: List[String]) -> Optional[String]:
        for i in range(len(arg_validators)):
            var error = arg_validators[i](command, args)
            if error:
                return error
        return None

    return match_all_args


fn get_args(arguments: List[String]) -> List[String]:
    """Parses flags and args from the args passed via the command line
    and adds them to their appropriate collections.

    Args:
        arguments: The arguments passed via the command line.

    Returns:
        The arguments that are not flags.
    """
    var args = List[String]()
    for i in range(len(arguments)):
        # Argument is not a shorthand or full flag.
        var argument = arguments[i]
        if not (argument.startswith("-", 0, 1)):
            args.append(argument)
    return args
