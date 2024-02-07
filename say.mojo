from prism import Flag, InputFlags, PositionalArgs, Command, CommandMap


fn say(args: PositionalArgs, flags: InputFlags) raises -> None:
    print("Shouldn't be here!")


fn say_hello(args: PositionalArgs, flags: InputFlags) raises -> None:
    print("Hello World!")

    # for item in flags.items():
    #     print("Flag: ", item.key, " Value: ", item.value)
    # for i in range(len(args)):
    #     print("Arg: ", args[i])


fn say_goodbye(args: PositionalArgs, flags: InputFlags) raises -> None:
    print("Goodbye World!")

# for some reason returning the command object without setting it to variable breaks the compiler
fn build_say_command() raises -> Command:
    let cmd = Command(
        name="say",
        description="Say something to someone",
        run=say,
    )
    return cmd


fn build_hello_command() raises -> Command:
    let cmd = Command(
        name="hello",
        description="Say hello to someone",
        run=say_hello,
    )
    return cmd

fn build_goodbye_command() raises -> Command:
    let cmd = Command(
        name="goodbye",
        description="Say goodbye to someone",
        run=say_goodbye,
    )
    return cmd
