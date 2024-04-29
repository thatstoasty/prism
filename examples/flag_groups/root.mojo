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

    var tool_command = Command(
        name="tool", description="This is a dummy command!", run=tool_func, aliases=List[String]("object", "thing")
    )
    tool_command.add_bool_flag(name="required", shorthand="r", usage="Always required.")
    tool_command.add_string_flag(name="color", shorthand="c", usage="Text color", default="#3464eb")
    tool_command.add_string_flag(name="hue", shorthand="x", usage="Text color", default="#3464eb")
    tool_command.add_string_flag(name="formatting", shorthand="f", usage="Text formatting")
    tool_command.mark_flags_required_together("color", "formatting")
    tool_command.mark_flags_mutually_exclusive("color", "hue")
    tool_command.mark_flags_one_required("required")

    root_command.add_command(tool_command)
    root_command.execute()
    print("duration", (now() - start) / 1e9)


fn main() -> None:
    init()