from prism import Flag, InputFlags, PositionalArgs, Command, CommandMap, add_command
from python import Python, PythonObject
from mist import TerminalStyle


fn printer(args: PositionalArgs, flags: InputFlags) raises -> None:
    if len(args) <= 0:
        print("No text to print! Pass in some text as a positional argument.")
        return None

    var color = flags.get("color", "")
    var formatting = flags.get("formatting", "")
    var style = TerminalStyle()

    if color != "":
        style.color(color)
    if formatting == "bold":
        style.bold()
    elif formatting == "underline":
        style.underline()
    elif formatting == "italic":
        style.italic()

    print(style.render(args[0]))


fn init() raises -> None:
    var command_map = CommandMap()
    var root_command = Command(name="printer", description="Base command.", run=printer)
    root_command.add_flag(Flag("color", "c", "Text color"))
    root_command.add_flag(Flag("formatting", "f", "Text formatting"))
    command_map[root_command.name] = root_command

    root_command.execute(command_map)


fn main() raises -> None:
    _ = init()
