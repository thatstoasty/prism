from prism import Flag, Command
from prism.command import CommandArc


fn say(command: Arc[Command], args: List[String]) -> None:
    print("Shouldn't be here!")
    return None


fn say_hello(command: Arc[Command], args: List[String]) -> None:
    print("Hello World!")
    return None


fn say_goodbye(command: Arc[Command], args: List[String]) -> None:
    print("Goodbye World!")
    return None


# for some reason returning the command object without setting it to variable breaks the compiler
fn build_say_command() -> Arc[Command]:
    return Arc(
        Command(
            name="say",
            description="Say something to someone",
            run=say,
        )
    )


fn build_hello_command() -> Arc[Command]:
    var cmd = Arc(
        Command(
            name="hello",
            description="Say hello to someone",
            run=say_hello,
        )
    )
    return cmd


fn build_goodbye_command() -> Arc[Command]:
    var cmd = Arc(
        Command(
            name="goodbye",
            description="Say goodbye to someone",
            run=say_goodbye,
        )
    )
    return cmd
