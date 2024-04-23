from prism import Flag, Command, CommandArc, minimum_n_args
from examples.logging.log import logger, default_logger, json_logger


fn handler(command: CommandArc, args: List[String]) -> None:
    var print_type = command[].get_all_flags()[].get_as_string("type").value()
    if print_type == "json":
        for arg in args:
            json_logger.info(arg[])
    elif print_type == "custom":
        for arg in args:
            logger.info(arg[])
    else:
        for arg in args:
            default_logger.info(arg[])

    return None


fn init() -> None:
    var root_command = Command(
        name="logger", description="Base command.", run=handler, arg_validator=minimum_n_args[1]()
    )
    root_command.flags.add_string_flag[
        name="type", shorthand="t", usage="Formatting type: [json, custom]", default="json"
    ]()

    root_command.execute()


fn main() -> None:
    init()
