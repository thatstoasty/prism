from memory import Arc
from prism import Command, Context


fn test(ctx: Context) -> None:
    print("Pass tool, object, or thing as a subcommand!")


fn tool_func(ctx: Context) -> None:
    print("My tool!")


fn main() -> None:
    var root = Command(
        name="my",
        usage="This is a dummy command!",
        run=test,
    )
    root.persistent_flags.bool_flag(name="required", shorthand="r", usage="Always required.")
    root.persistent_flags.string_flag(name="host", shorthand="h", usage="Host")
    root.persistent_flags.string_flag(name="port", shorthand="p", usage="Port")
    root.mark_persistent_flag_required("required")

    var print_tool = Arc(Command(name="tool", usage="This is a dummy command!", run=tool_func))
    print_tool[].flags.bool_flag(name="also", shorthand="a", usage="Also always required.")
    print_tool[].flags.string_flag(name="uri", shorthand="u", usage="URI")
    root.add_subcommand(print_tool)

    # Make sure to add the child command to the parent before marking flags.
    # add_subcommand() will merge persistent flags from the parent into the child's flags.
    print_tool[].mark_flag_required("also")
    print_tool[].mark_flags_required_together("host", "port")
    print_tool[].mark_flags_mutually_exclusive("host", "uri")

    root.execute()
