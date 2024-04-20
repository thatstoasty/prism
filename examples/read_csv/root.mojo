from prism import Flag, Command, CommandArc, no_args
from external.goodies import CSVReader, FileWrapper
from os.path import exists


fn handler(command: CommandArc, args: List[String]) raises -> None:
    var file_path = command[].get_all_flags()[].get_as_string("file").value()
    if not exists(file_path):
        raise Error("File does not exist.")

    var file = FileWrapper(file_path, "r")
    var reader = CSVReader(file^)
    var lines = command[].get_all_flags()[].get_as_int("lines").value()
    var csv = reader.read_lines(lines, "\n", 3)
    for i in range(csv.row_count()):
        print(csv.get(i, 0))


fn init() raises -> None:
    var root_command = Command(name="read_csv", description="Base command.", run=handler, arg_validator=no_args)
    root_command.flags.add_string_flag(name="file", shorthand="f", usage="CSV file to read.")
    root_command.flags.add_int_flag(name="lines", shorthand="l", usage="Lines to print.", default="3")

    root_command.execute()


fn main() raises -> None:
    init()
