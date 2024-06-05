from sys import argv
from external.gojo.builtins import panic
from .command import Command
from .flag import Flag, get_flags


fn get_args_as_list() -> List[String]:
    """Returns the arguments passed to the executable as a list of strings."""
    var args = argv()
    var args_list = List[String]()
    var i = 1
    while i < len(args):
        args_list.append(args[i])
        i += 1

    return args_list


struct CLI:
    var commands: List[Command]
    var next_id: ID

    # TODO: Need to add the logic for adding commands and subcommands via init
    fn __init__(inout self, commands: List[Command] = List[Command]()) -> None:
        self.commands = List[Command]()
        self.next_id = 0
        for command in commands:
            self.add_command(command[])

    fn add_command(inout self, owned command: Command, parent_name: String = "") -> None:
        command.id = self.next_id

        # Add to command name to id mapping
        if parent_name != "":
            var parent_id = self.get_id(parent_name)
            if parent_id:
                var parent = self.lookup(parent_id.value())
                parent[].add_child(command.id)
                command.add_parent(parent_id.value())

        self._merge_flags(command)
        self.commands[self.next_id] = command^
        self.next_id += 1

    fn imm_lookup(self, id: ID) -> Reference[Command, __lifetime_of(self)]:
        return self.commands.__get_ref(id)[]

    fn lookup(inout self, id: ID) -> Reference[Command, __lifetime_of(self)]:
        return self.commands.__get_ref(id)[]

    fn lookup(inout self, name: String) raises -> Reference[Command, __lifetime_of(self)]:
        var id = self.get_id(name)
        if not id:
            raise Error("CLI.lookup: ID not found for the given name.")
        return self.lookup(id.value())

    fn lookup_deref(inout self, id: ID) -> ref [__lifetime_of(self)] Command:
        return self.commands.__get_ref(id)[]

    fn lookup_deref(inout self, name: String) raises -> ref [__lifetime_of(self)] Command:
        var id = self.get_id(name)
        if not id:
            raise Error("CLI.lookup: ID not found for the given name.")
        return self.lookup_deref(id.value())

    fn get_id(self, name: String) -> Optional[ID]:
        for command in self.commands:
            if command[].name == name:
                return command[].id
        return None

    fn inherited_flags(self, command: Command) -> FlagSet:
        """Returns the flags for the command and inherited flags from its parent.

        Returns:
            The flags for the command and its parent.
        """
        var i_flags = FlagSet()

        @always_inline
        fn add_parent_persistent_flags(parent: Reference[Command]) capturing -> None:
            if parent[].persistent_flags:
                i_flags += parent[].persistent_flags

        self.visit_parents[add_parent_persistent_flags](command)

        return i_flags

    fn _merge_flags(self, inout command: Command):
        """Returns all flags for the command and inherited flags from its parent."""
        # Set mutability of flag set by initializing it as a var.
        command.flags += command.persistent_flags
        command._inherited_flags = self.inherited_flags(command)
        command.flags += command._inherited_flags

    # # todo wip
    # fn add_command(inout self, owned command: Command, owned subcommands: List[Command]) -> None:
    #     var id = self.next_id
    #     command.id = id
    #     self.commands[self.next_id] = command ^
    #     self.next_id += 1

    #     for cmd in subcommands:
    #         cmd[].add_parent(id)
    #         cmd[].id = self.next_id
    #         self.commands[self.next_id] = cmd[]
    #         self.next_id += 1

    fn parse_command_from_args(inout self, args: List[String], inout remaining_args: List[String]) -> Int:
        var number_of_args = len(args)
        var command_id = 0
        var command = self.lookup(command_id)
        var children_ids = command[].children
        var leftover_args_start_index = 0  # Start at 1 to start slice at the first remaining arg, not the last child command.

        for arg in args:
            for id in children_ids:
                var arg_cmd_id = self.get_id(arg[])
                if arg_cmd_id:
                    if id[] == arg_cmd_id.take():
                        # if id[] == arg[] or contains(command_ref[][].aliases, arg[]):
                        print("found command")
                        command = self.lookup(id[])
                        print("lookup done")
                        children_ids = command[].children
                        leftover_args_start_index += 1
                        break

        # If the there are more or equivalent args to the index, then there are remaining args to pass to the command.
        if number_of_args >= leftover_args_start_index:
            remaining_args = args[leftover_args_start_index:number_of_args]

        return command_id

    fn has_parent(self, command: Command) -> Bool:
        """Returns true if the command has a parent."""
        return command.parent.__bool__()

    fn full_command(self, command: Reference[Command]) -> String:
        """Traverses up the parent command tree to build the full command as a string."""
        if command[].has_parent():
            var parent = self.imm_lookup(command[].parent.value())
            var ancestor: String = self.full_command(parent)
            return ancestor + " " + command[].name
        else:
            return command[].name

    fn visit_parents[func: ParentVisitorFn](self, command: Reference[Command]) -> None:
        """Visits all parents of the command and invokes func on each parent.

        Params:
            func: The function to invoke on each parent.
        """
        if command[].has_parent():
            var parent = self.imm_lookup(command[].parent.value())
            func(parent)
            self.visit_parents[func](parent)

    fn run(inout self):
        """Traverses the arguments passed to the executable and executes the last command in the branch."""
        # Traverse from the root command through the children to find a match for the current argument.
        # Any additional arguments past the last matched command name are considered arguments.
        # TODO: Tree traversal is new to me, there's probably a better way to do this.

        # # Always execute from the root command, regardless of what command was executed in main.
        # if self.has_parent():
        #     return self._root().execute()

        var args = get_args_as_list()
        var remaining_args = List[String]()
        var command_id = self.parse_command_from_args(args, remaining_args)
        var command = self.lookup(command_id)

        # Merge local and inherited flags
        command[]._merge_flags()

        # Add all parents to the list to check if they have persistent pre/post hooks.
        var parents = List[Command]()

        # TODO: Appending the commands here performs copies
        @always_inline
        fn append_parent(command: Reference[Command]) capturing -> None:
            parents.append(command[])

        self.visit_parents[append_parent](command)

        # If ENABLE_TRAVERSE_RUN_HOOKS is True, reverse the list to start from the root command rather than
        # from the child. This is because all of the persistent hooks will be run.
        @parameter
        if ENABLE_TRAVERSE_RUN_HOOKS:
            parents.reverse()

        # Get the flags for the command to be executed.
        # store flags as a mutable ref
        var err: Error
        remaining_args, err = get_flags(command[].flags, remaining_args)
        if err:
            panic(err)

        # Check if the help flag was passed
        var help_passed = command[].flags.get_as_bool("help")
        if help_passed.value() == True:
            var children = List[String]()
            for id in command[].children:
                var child = self.lookup(id[])
                children.append(str(child[]))
            print(
                command[].help(
                    command[].description, command[].aliases, self.full_command(command), children, command[].flags
                )
            )
            return None

        command[].execute(remaining_args, parents)
