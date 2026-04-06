from prism import Command, Flag, FlagSet, read_args


fn test(args: List[String], flags: FlagSet) raises -> None:
    var name = flags.get_string_list("name")
    if not name:
        print("Received no names to print.")
        return

    print("Hello", " ".join(name.value()))


fn sum(args: List[String], flags: FlagSet) raises -> None:
    var numbers = flags.get_int_list("number")
    if not numbers:
        print("Received no numbers to add.")
        return

    var sum = 0
    for number in numbers.value():
        sum += number
    print("The sum is:", sum)


fn sum_float(args: List[String], flags: FlagSet) raises -> None:
    var numbers = flags.get_float64_list("number")
    if not numbers:
        print("Received no numbers to add.")
        return

    var sum = 0.0
    for number in numbers.value():
        sum += number
    print("The sum is:", sum)


fn main() -> None:
    var cli = Command(
        name="greet",
        usage="Greet a user!",
        run=test,
        flags=[
            Flag.string_list(
                name="name",
                shorthand="n",
                usage="The name of the person to greet.",
                default=["Mikhail", "Tavarez"],
            )
        ],
        children=[
            Command(
                name="sum",
                usage="Add up the numbers passed in with the -n flag!",
                run=sum,
                flags=[
                    Flag.int_list(
                        name="number",
                        shorthand="n",
                        usage="A number to include in the sum.",
                        default=[1, 2],
                    )
                ],
            ),
            Command(
                name="sum_float",
                usage="Add up the numbers passed in with the -n flag!",
                run=sum_float,
                flags=[
                    Flag.float64_list(
                        name="number",
                        shorthand="n",
                        usage="A number to include in the sum.",
                        default=[1.0, 2.0],
                    )
                ],
            ),
        ],
    )
    cli.execute(read_args())
