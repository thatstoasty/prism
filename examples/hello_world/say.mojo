from prism import Flag, Command
from prism.command import CommandArc


fn say(command: CommandArc, args: List[String]) -> Error:
    print("Shouldn't be here!")
    return Error()


fn say_hello(command: CommandArc, args: List[String]) -> Error:
    print("Hello World!")
    return Error()


fn say_goodbye(command: CommandArc, args: List[String]) -> Error:
    print("Goodbye World!")
    return Error()


# for some reason returning the command object without setting it to variable breaks the compiler
fn build_say_command() -> Command:
    return Command(
        name="say",
        description="Say something to someone",
        run=say,
    )


fn build_hello_command() -> Command:
    var cmd = Command(
        name="hello",
        description="Say hello to someone",
        run=say_hello,
    )
    return cmd


fn build_goodbye_command() -> Command:
    var cmd = Command(
        name="goodbye",
        description="Say goodbye to someone",
        run=say_goodbye,
    )
    return cmd
