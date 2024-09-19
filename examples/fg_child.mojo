from memory import Arc
from prism import Command, CommandArc


fn test(command: Arc[Command], args: List[String]) -> None:
    print("Pass tool, object, or thing as a subcommand!")


fn tool_func(command: Arc[Command], args: List[String]) -> None:
    print("My tool!")


fn main() -> None:
    var root_command = Arc(
        Command(
            name="my",
            description="This is a dummy command!",
            run=test,
        )
    )
    root_command[].persistent_flags.add_bool_flag(name="required", shorthand="r", usage="Always required.")
    root_command[].persistent_flags.add_string_flag(name="host", shorthand="h", usage="Host")
    root_command[].persistent_flags.add_string_flag(name="port", shorthand="p", usage="Port")
    root_command[].mark_persistent_flag_required("required")

    var tool_command = Arc(Command(name="tool", description="This is a dummy command!", run=tool_func))
    tool_command[].flags.add_bool_flag(name="also", shorthand="a", usage="Also always required.")
    tool_command[].flags.add_string_flag(name="uri", shorthand="u", usage="URI")
    root_command[].add_command(tool_command)

    # Make sure to add the child command to the parent before marking flags.
    # add_command() will merge persistent flags from the parent into the child's flags.
    tool_command[].mark_flag_required("also")
    tool_command[].mark_flags_required_together("host", "port")
    tool_command[].mark_flags_mutually_exclusive("host", "uri")

    root_command[].execute()
