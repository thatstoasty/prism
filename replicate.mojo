fn right_output(flags: List[String], args: List[String]) -> None:
    for arg in args:
        print("Received", arg[])
    for flag in flags:
        print("Received", flag[])


fn wrong_output(flags: List[String], args: List[String]) -> None:
    for arg in args:
        print("Received", arg[])


fn main():
    var right: Optional[fn (flags: List[String], args: List[String]) -> None] = right_output
    var wrong: Optional[fn (flags: List[String], args: List[String]) -> None] = wrong_output
    right.value()[](List[String]("help"), List[String]("hello"))
    wrong.value()[](List[String]("help"), List[String]("hello"))
