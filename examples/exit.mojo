from sys import exit

from prism import Command, FlagSet


fn test(args: List[String], flags: FlagSet) raises -> None:
    raise Error("Error: Exit Code 2")


fn my_exit(e: Error) -> None:
    if e.as_string_slice() == "Error: Exit Code 2":
        print("Exiting with code 2")
        exit(2)
    else:
        exit(1)


fn main() -> None:
    var cli = Command(
        name="hello",
        usage="This is a dummy command!",
        raising_run=test,
        exit=my_exit,
    )
    cli.execute()
