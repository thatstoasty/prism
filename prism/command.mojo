from sys import argv
from collections.optional import Optional
from memory import Reference
from memory import Arc
from external.string_dict import Dict
from external.gojo.fmt import sprintf
from external.gojo.builtins import panic
from external.gojo.strings import StringBuilder
from .flag import Flag, get_flags
from .flag_set import FlagSet, process_flag_for_group_annotation, validate_flag_groups
from .args import arbitrary_args, get_args
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


fn default_help(command: Command) -> String:
    """Prints the help information for the command."""
    var builder = StringBuilder()
    _ = builder.write_string(command.description)

    if command.aliases:
        _ = builder.write_string("\n\nAliases:")
        _ = builder.write_string(sprintf("\n  %s", to_string(command.aliases)))

    # Build usage statement arguments depending on the command's children and flags.
    var full_command = command._full_command()
    _ = builder.write_string(sprintf("\n\nUsage:\n  %s%s", full_command, String(" [args]")))
    if len(command.children) > 0:
        _ = builder.write_string(" [command]")
    if len(command.flags[]) > 0:
        _ = builder.write_string(" [flags]")

    if command.children:
        _ = builder.write_string("\n\nAvailable commands:")
        for child in command.children:
            _ = builder.write_string(sprintf("\n  %s", str(child[][])))

    if command.flags[]:
        _ = builder.write_string("\n\nAvailable flags:")
        for flag in command.flags[].flags:
            _ = builder.write_string(sprintf("\n  -%s, --%s    %s", flag[].shorthand, flag[].name, flag[].usage))

    _ = builder.write_string(
        sprintf('\n\nUse "%s [command] --help" for more information about a command.', full_command)
    )
    return str(builder)


alias CommandFunction = fn (Command, List[String]) -> None
alias CommandFunctionErr = fn (Command, List[String]) -> Error
alias HelpFunction = fn (Command) escaping -> String
alias ArgValidator = fn (Command, List[String]) escaping -> Optional[String]
alias ParentVisitorFn = fn (Command) capturing -> None

# Set to True to traverse all parents' persistent pre and post run hooks. If False, it'll only run the first match.
# If False, starts from the child command and goes up the parent chain. If True, starts from root and goes down.
# TODO: For now it's locked to False until file scope variables.
alias ENABLE_TRAVERSE_RUN_HOOKS = False


fn parse_command_from_args(start: Command) -> (Command, List[String]):
    var args = get_args_as_list()
    var number_of_args = len(args)
    var command = start
    var children = command.children
    var leftover_args_start_index = 0  # Start at 1 to start slice at the first remaining arg, not the last child command.

    for arg in args:
        for cmd in children:
            if cmd[][].name == arg[] or contains(cmd[][].aliases, arg[]):
                command = cmd[][]
                children = cmd[][].children
                leftover_args_start_index += 1
                break

    # If the there are more or equivalent args to the index, then there are remaining args to pass to the command.
    var remaining_args = List[String]()
    if number_of_args >= leftover_args_start_index:
        remaining_args = args[leftover_args_start_index:number_of_args]

    return command, remaining_args


# TODO: For parent Optional[Reference[Self, mutability, lifetime]]] works but Optional[Reference[Self]] causes compiler issues.
@value
struct Command[mutability: i1, lifetime: AnyLifetime[mutability].type](CollectionElement):
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
    var help: HelpFunction[mutability, lifetime]

    # The group id under which this subcommand is grouped in the 'help' output of its parent.
    var group_id: String

    var pre_run: Optional[CommandFunction]
    var run: Optional[CommandFunction]
    var post_run: Optional[CommandFunction]

    var erroring_pre_run: Optional[CommandFunctionErr]
    var erroring_run: Optional[CommandFunctionErr]
    var erroring_post_run: Optional[CommandFunctionErr]

    var persistent_pre_run: Optional[CommandFunction]
    var persistent_post_run: Optional[CommandFunction]

    var persistent_erroring_pre_run: Optional[CommandFunctionErr]
    var persistent_erroring_post_run: Optional[CommandFunctionErr]

    var arg_validator: ArgValidator[mutability, lifetime]
    var valid_args: List[String]

    # Local flags for the command. TODO: Use this field to store cached results for local flags.
    var local_flags: Arc[FlagSet]

    # Local flags that also persist to children.
    var persistent_flags: Arc[FlagSet]

    # It is all local, persistent, and inherited flags.
    var flags: Arc[FlagSet]

    # Cached results from self._merge_flags().
    var _inherited_flags: Arc[FlagSet]

    var children: List[Reference[Self, mutability, lifetime]]
    var parent: Optional[Reference[Self, mutability, lifetime]]

    fn __init__[
        help: HelpFunction[mutability, lifetime] = default_help[mutability, lifetime]
    ](
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
    ):
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

        self.arg_validator = arbitrary_args[mutability, lifetime]
        self.valid_args = valid_args

        self.children = List[Reference[Self, mutability, lifetime]]()
        self.parent = None

        # These need to be mutable so we can add flags to them.
        self.flags = Arc(FlagSet())
        self.local_flags = Arc(FlagSet())
        self.persistent_flags = Arc(FlagSet())
        self._inherited_flags = Arc(FlagSet())
        self.flags[].add_bool_flag(name="help", shorthand="h", usage="Displays help information about the command.")

    # TODO: Why do we have 2 almost indentical init functions? Setting a default arg_validator value, breaks the compiler as of 24.2.
    fn __init__[
        help: HelpFunction[mutability, lifetime] = default_help[mutability, lifetime]
    ](
        inout self,
        name: String,
        description: String,
        arg_validator: ArgValidator[mutability, lifetime],
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
    ):
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

        self.children = List[Reference[Self, mutability, lifetime]]()
        self.parent = None

        self.arg_validator = arg_validator
        self.valid_args = valid_args
        self.flags = Arc(FlagSet())
        self.local_flags = Arc(FlagSet())
        self.persistent_flags = Arc(FlagSet())
        self._inherited_flags = Arc(FlagSet())
        self.flags[].add_bool_flag(name="help", shorthand="h", usage="Displays help information about the command.")

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
        return sprintf("(Name: %s, Description: %s)", self.name, self.description)

    fn __repr__(inout self) -> String:
        var parent_name: String = ""
        if self.has_parent():
            parent_name = self.parent.value()[][].name
        return (
            "Name: "
            + self.name
            + "\nDescription: "
            + self.description
            + "\nArgs: "
            + to_string(self.valid_args)
            + "\nFlags: "
            + str(self.flags[])
            + "\nCommands: "
            # + to_string(self.children)
            + "\nParent: "
            + parent_name
        )

    fn _full_command(self) -> String:
        """Traverses up the parent command tree to build the full command as a string."""
        if self.has_parent():
            var ancestor: String = self.parent.value()[][]._full_command()
            return ancestor + " " + self.name
        else:
            return self.name

    fn _root(self: Reference[Self]) -> Reference[Command[mutability, lifetime], self.is_mutable, self.lifetime]:
        """Returns the root command of the command tree."""
        if self[].has_parent():
            var res = self[].parent.value()[]._root()
            return res

        return self

    fn validate_flag_groups(self):
        # TODO: Move to func and check mutually exclusive and one required cases.
        var group_status = Dict[Dict[Bool]]()
        var one_required_group_status = Dict[Dict[Bool]]()
        var mutually_exclusive_group_status = Dict[Dict[Bool]]()

        @always_inline
        fn flag_checker(flag: Reference[Flag]) capturing:
            var err = process_flag_for_group_annotation(self.flags[], flag, REQUIRED_AS_GROUP, group_status)
            if err:
                panic("Failed to process flag for REQUIRED_AS_GROUP annotation: " + str(err))
            err = process_flag_for_group_annotation(self.flags[], flag, ONE_REQUIRED, one_required_group_status)
            if err:
                panic("Failed to process flag for ONE_REQUIRED annotation: " + str(err))
            err = process_flag_for_group_annotation(
                self.flags[], flag, MUTUALLY_EXCLUSIVE, mutually_exclusive_group_status
            )
            if err:
                panic("Failed to process flag for MUTUALLY_EXCLUSIVE annotation: " + str(err))

        self.flags[].visit_all[flag_checker]()

        # Validate required flag groups
        validate_flag_groups(group_status, one_required_group_status, mutually_exclusive_group_status)

    fn execute(inout self) -> None:
        """Traverses the arguments passed to the executable and executes the last command in the branch."""
        # Traverse from the root command through the children to find a match for the current argument.
        # Any additional arguments past the last matched command name are considered arguments.
        # TODO: Tree traversal is new to me, there's probably a better way to do this.

        # Always execute from the root command, regardless of what command was executed in main.
        if self.has_parent():
            return self._root()[].execute()

        var remaining_args: List[String]
        var command: Self
        command, remaining_args = parse_command_from_args(self)

        # Merge local and inherited flags
        command._merge_flags()

        var parents = List[Optional[Reference[Self, self.mutability, self.lifetime]]]()
        var parent = Optional[Reference[Self, self.mutability, self.lifetime]](command)

        # Add all parents to the list to check if they have persistent pre/post hooks.
        while True:
            parents.append(parent)
            if not parent.value()[][].parent:
                break
            parent = parent.value()[][].parent

        # If ENABLE_TRAVERSE_RUN_HOOKS is True, reverse the list to start from the root command rather than
        # from the child. This is because all of the persistent hooks will be run.
        @parameter
        if ENABLE_TRAVERSE_RUN_HOOKS:
            parents.reverse()

        # Get the flags for the command to be executed.
        # store flags as a mutable ref
        var err: Error
        remaining_args, err = get_flags(command.flags[], remaining_args)
        if err:
            panic(err)

        # Check if the help flag was passed
        var help_passed = command.flags[].get_as_bool("help")
        if help_passed.value()[] == True:
            print(command.help(command))
            return None

        # Validate individual required flags (eg: flag is required)
        err = command.validate_required_flags()
        if err:
            panic(err)

        # Validate flag groups (eg: one of required, mutually exclusive, required together)
        command.validate_flag_groups()

        # Validate the remaining arguments
        var error_message = command.arg_validator(command, remaining_args)
        if error_message:
            panic(error_message.value()[])

        # Run the persistent pre-run hooks.
        for parent in parents:
            if parent[]:
                var cmd = parent[].value()[]
                if cmd[].persistent_erroring_pre_run:
                    err = cmd[].persistent_erroring_pre_run.value()[](command, remaining_args)
                    if err:
                        panic(err)
                    if not ENABLE_TRAVERSE_RUN_HOOKS:
                        break
                else:
                    if cmd[].persistent_pre_run:
                        cmd[].persistent_pre_run.value()[](command, remaining_args)
                        if not ENABLE_TRAVERSE_RUN_HOOKS:
                            break

        # Run the pre-run hooks.
        if command.pre_run:
            command.pre_run.value()[](command, remaining_args)
        elif command.erroring_pre_run:
            err = command.erroring_pre_run.value()[](command, remaining_args)
            if err:
                panic(err)

        # Run the function's commands.
        if command.run:
            command.run.value()[](command, remaining_args)
        else:
            err = command.erroring_run.value()[](command, remaining_args)
            if err:
                panic(err)

        # Run the persistent post-run hooks.
        for parent in parents:
            if parent[]:
                var cmd = parent[].value()
                if cmd[].persistent_erroring_post_run:
                    err = cmd[].persistent_erroring_post_run.value()[](command, remaining_args)
                    if err:
                        panic(err)
                    if not ENABLE_TRAVERSE_RUN_HOOKS:
                        break
                else:
                    if cmd[].persistent_post_run:
                        cmd[].persistent_post_run.value()[](command, remaining_args)
                        if not ENABLE_TRAVERSE_RUN_HOOKS:
                            break

        # Run the post-run hooks.
        if command.post_run:
            command.post_run.value()[](command, remaining_args)
        elif command.erroring_post_run:
            err = command.erroring_post_run.value()[](command, remaining_args)
            if err:
                panic(err)

    fn inherited_flags(self) -> FlagSet:
        """Returns the flags for the command and inherited flags from its parent.

        Returns:
            The flags for the command and its parent.
        """
        var i_flags = FlagSet()

        @always_inline
        fn add_parent_persistent_flags(parent: Command) capturing -> None:
            if parent.persistent_flags[]:
                i_flags += parent.persistent_flags[]

        self.visit_parents[add_parent_persistent_flags]()

        return i_flags

    fn _merge_flags(inout self):
        """Returns all flags for the command and inherited flags from its parent."""
        # Set mutability of flag set by initializing it as a var.
        self.flags[] += self.persistent_flags[]
        self._inherited_flags = self.inherited_flags()
        self.flags[] += self._inherited_flags[]

    fn add_command(inout self, inout command: Command):
        """Adds child command and set's child's parent attribute to self.

        Args:
            command: The command to add as a child of self.
        """
        self.children.append(command)
        command.parent = Reference[Command[self.mutability, self.lifetime], self.mutability, self.lifetime](self)

    fn mark_flag_required(inout self, flag_name: String) -> None:
        """Marks the given flag with annotations so that Prism errors
        if the command is invoked without the flag.

        Args:
            flag_name: The name of the flag to mark as required.
        """
        var err = self.flags[].set_annotation(flag_name, REQUIRED, List[String]("true"))
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
            var maybe_flag = self.flags[].lookup(flag_name[])
            if not maybe_flag:
                panic(sprintf("Failed to find flag %s and mark it as being required in a flag group", flag_name[]))

            var flag = maybe_flag.value()[]

            # TODO: This inline join logic is temporary until we can pass around varadic lists or cast it to a list.
            var result: String = ""
            for i in range(len(flag_names)):
                result += flag_names[i]
                if i != len(flag_names) - 1:
                    result += " "
            flag[].annotations.put(REQUIRED_AS_GROUP, result)
            var err = self.flags[].set_annotation(
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
            var maybe_flag = self.flags[].lookup(flag_name[])
            if not maybe_flag:
                panic(sprintf("Failed to find flag %s and mark it as being in a one-required flag group", flag_name[]))

            var flag = maybe_flag.value()[]
            var result: String = ""
            for i in range(len(flag_names)):
                result += flag_names[i]
                if i != len(flag_names) - 1:
                    result += " "
            flag[].annotations.put(ONE_REQUIRED, result)
            var err = self.flags[].set_annotation(
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
            var maybe_flag = self.flags[].lookup(flag_name[])
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
            flag[].annotations.put(MUTUALLY_EXCLUSIVE, result)
            var err = self.flags[].set_annotation(
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
        var err = self.persistent_flags[].set_annotation(flag_name, REQUIRED, List[String]("true"))
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
            func(self.parent.value()[][])
            self.parent.value()[][].visit_parents[func]()

    fn validate_required_flags(self) -> Error:
        """Validates all required flags are present and returns an error otherwise."""
        var missing_flag_names = List[String]()

        fn check_required_flag(flag: Reference[Flag]) capturing -> None:
            var required_annotation = flag[].annotations.get(REQUIRED, List[String]())
            if required_annotation:
                if required_annotation[0] == "true" and not flag[].changed:
                    missing_flag_names.append(flag[].name)

        self.flags[].visit_all[check_required_flag]()

        if len(missing_flag_names) > 0:
            return Error("required flag(s) " + to_string(missing_flag_names) + " not set")
        return Error()

    # NOTE: These wrappers are just nice to have. Feels good to call Command().add_flag()
    # instead of Command().flags[].add_flag()
    # fn flag_list(self) -> List[Reference[Flag]]:
    #     """Returns a list of references to all flags in the merged flag set (local, persistent, inherited).

    #     This is just a convenience function to avoid having to call Command().flags[].get_flags().
    #     """
    #     return self.flags[].flags

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
        self.flags[].add_bool_flag(name=name, usage=usage, default=default, shorthand=shorthand)

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
        self.flags[].add_string_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_int_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int = 0) -> None:
        """Adds an Int flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags[].add_int_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_int8_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int8 = 0) -> None:
        """Adds an Int8 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags[].add_int8_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_int16_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int16 = 0) -> None:
        """Adds an Int16 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags[].add_int16_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_int32_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int32 = 0) -> None:
        """Adds an Int32 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags[].add_int32_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_int64_flag(inout self, name: String, usage: String, shorthand: String = "", default: Int64 = 0) -> None:
        """Adds an Int64 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags[].add_int64_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_uint8_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt8 = 0) -> None:
        """Adds a UInt8 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags[].add_uint8_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_uint16_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt16 = 0) -> None:
        """Adds a UInt16 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags[].add_uint16_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_uint32_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt32 = 0) -> None:
        """Adds a UInt32 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags[].add_uint32_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_uint64_flag(inout self, name: String, usage: String, shorthand: String = "", default: UInt64 = 0) -> None:
        """Adds a UInt64 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags[].add_uint64_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_float16_flag(inout self, name: String, usage: String, shorthand: String = "", default: Float16 = 0) -> None:
        """Adds a Float16 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags[].add_float16_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_float32_flag(inout self, name: String, usage: String, shorthand: String = "", default: Float32 = 0) -> None:
        """Adds a Float32 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags[].add_float32_flag(name=name, usage=usage, default=default, shorthand=shorthand)

    fn add_float64_flag(inout self, name: String, usage: String, shorthand: String = "", default: Float64 = 0) -> None:
        """Adds a Float64 flag to the flag set.

        Args:
            name: The name of the flag.
            usage: The usage of the flag.
            shorthand: The shorthand of the flag.
            default: The default value of the flag.
        """
        self.flags[].add_float64_flag(name=name, usage=usage, default=default, shorthand=shorthand)
