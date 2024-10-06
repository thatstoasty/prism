from memory import Arc
from prism import Command, Context


fn test(context: Context) -> None:
    print("Pass tool, object, or thing as a subcommand!")


fn tool_func(context: Context) -> None:
    print("My tool!")


fn main() -> None:
    var root = Arc(
        Command(
            name="my",
            description="This is a dummy command!",
            run=test,
        )
    )
    root[].persistent_flags.add_bool_flag(name="required", shorthand="r", usage="Always required.")
    root[].persistent_flags.add_string_flag(name="host", shorthand="h", usage="Host")
    root[].persistent_flags.add_string_flag(name="port", shorthand="p", usage="Port")
    root[].persistent_flags.add_string_flag(name="uri", shorthand="u", usage="URI")
    root[].mark_flags_required_together("host", "port")
    root[].mark_flags_mutually_exclusive("host", "uri")
    root[].mark_flag_required("required")

    root[].execute()
