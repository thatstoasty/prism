from memory._arc import Arc
from time import now
from prism import Flag, Command, CommandArc
from prism.vector import to_string


fn test(command: CommandArc, args: List[String]) -> None:
    print("Pass tool, object, or thing as a subcommand!")


fn tool_func(command: CommandArc, args: List[String]) -> None:
    print("My tool!")


fn init() -> None:
    var start = now()
    var root_command = Command(
        name="my",
        description="This is a dummy command!",
        run=test,
    )
    root_command.persistent_flags[].add_bool_flag(name="required", shorthand="r", usage="Always required.")
    root_command.persistent_flags[].add_string_flag(name="host", shorthand="h", usage="Host")
    root_command.persistent_flags[].add_string_flag(name="port", shorthand="p", usage="Port")
    root_command.mark_persistent_flag_required("required")

    var tool_command = Command(name="tool", description="This is a dummy command!", run=tool_func)
    tool_command.add_bool_flag(name="also", shorthand="a", usage="Also always required.")
    tool_command.add_string_flag(name="uri", shorthand="u", usage="URI")
    root_command.add_command(tool_command)

    tool_command.mark_flag_required("also")
    tool_command.mark_flags_required_together("host", "port")
    tool_command.mark_flags_mutually_exclusive("host", "uri")

    root_command.execute()
    # print("duration", (now() - start) / 1e9)


fn main() -> None:
    init()
