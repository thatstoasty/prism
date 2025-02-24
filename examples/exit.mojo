from memory import ArcPointer
from prism import Command, Context
from sys import exit


fn test(ctx: Context) raises -> None:
    raise Error("Error: Exit Code 2")


fn my_exit(e: Error) -> None:
    if String(e) == "Error: Exit Code 2":
        print("Exiting with code 2")
        exit(2)
    else:
        exit(1)


fn main() -> None:
    Command(
        name="hello",
        usage="This is a dummy command!",
        raising_run=test,
        exit=my_exit,
    ).execute()
