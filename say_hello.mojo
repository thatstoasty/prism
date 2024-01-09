from prism.flag import Flag, InputFlags, PositionalArgs, get_args_and_flags
from prism.command import Command


fn say(args: PositionalArgs, flags: InputFlags) raises -> None:
    print("Shouldn't be here!")


fn say_hello(args: PositionalArgs, flags: InputFlags) raises -> None:
    print("Hello World!")


fn say_goodbye(args: PositionalArgs, flags: InputFlags) raises -> None:
    print("Goodbye World!")


fn build_say_command() -> Command:
    return Command(
        name="say",
        description="Say something to someone",
        run=say,
    )


fn build_say_hello_command() -> Command:
    return Command(
        name="say_hello",
        description="Say hello to someone",
        run=say_hello,
    )

fn build_say_goodbye_command() -> Command:
    return Command(
        name="say_goodbye",
        description="Say goodbye to someone",
        run=say_goodbye,
    )