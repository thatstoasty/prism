from prism import FlagSet, Command, CLI


fn test(flags: FlagSet, args: List[String]) -> None:
    print("Pass tool, object, or thing as a subcommand!")


fn tool_func(flags: FlagSet, args: List[String]) -> None:
    print("My tool!")


fn init() raises -> None:
    var cli = CLI()
    var root_command = Command(
        name="my",
        description="This is a dummy command!",
        run=test,
    )
    root_command.persistent_flags.add_bool_flag(name="required", shorthand="r", usage="Always required.")
    root_command.persistent_flags.add_string_flag(name="host", shorthand="h", usage="Host")
    root_command.persistent_flags.add_string_flag(name="port", shorthand="p", usage="Port")
    root_command.mark_persistent_flag_required("required")

    var tool_command = Command(name="tool", description="This is a dummy command!", run=tool_func)
    cli.add_command(root_command^)
    cli.add_command(tool_command^, parent_name="my")
    var tool = cli.lookup(tool_command.name)

    tool.add_bool_flag(name="also", shorthand="a", usage="Also always required.")
    tool.add_string_flag(name="uri", shorthand="u", usage="URI")
    tool.mark_flag_required("also")
    tool.mark_flags_required_together("host", "port")
    tool.mark_flags_mutually_exclusive("host", "uri")
    # tool_command.add_bool_flag(name="also", shorthand="a", usage="Also always required.")
    # tool_command.add_string_flag(name="uri", shorthand="u", usage="URI")
    # tool_command.mark_flag_required("also")
    # tool_command.mark_flags_required_together("host", "port")
    # tool_command.mark_flags_mutually_exclusive("host", "uri")

    # cli.run()


fn main() -> None:
    init()
