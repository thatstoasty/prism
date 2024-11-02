from memory import Arc
from prism import Command, Context


fn test(ctx: Context) raises -> None:
    name = ctx.command[].flags.get_string_list("name")
    print(String("Hello {}").format(" ".join(name)))


fn sum(ctx: Context) raises -> None:
    numbers = ctx.command[].flags.get_int_list("number")
    sum = 0
    for number in numbers:
        sum += number[]
    print(String("The sum is: {}").format(sum))


fn sum_float(ctx: Context) raises -> None:
    numbers = ctx.command[].flags.get_float64_list("number")
    sum = 0.0
    for number in numbers:
        sum += number[]
    print(String("The sum is: {}").format(sum))


fn main() -> None:
    root = Command(
        name="greet",
        usage="Greet a user!",
        raising_run=test,
    )

    root.flags.string_list_flag(
        name="name",
        shorthand="n",
        usage="The name of the person to greet.",
        default=List[String]("Mikhail", "Tavarez"),
    )

    sum_cmd = Arc(Command(
        name="sum",
        usage="Add up the numbers passed in with the -n flag!",
        raising_run=sum
    ))
    root.add_subcommand(sum_cmd)

    sum_cmd[].flags.int_list_flag(
        name="number",
        shorthand="n",
        usage="A number to include in the sum.",
        default=List[Int, True](1, 2),
    )

    sum_float_cmd = Arc(
        Command(name="sum_float", usage="Add up the numbers passed in with the -n flag!", raising_run=sum_float)
    )
    root.add_subcommand(sum_float_cmd)

    sum_float_cmd[].flags.float64_list_flag(
        name="number",
        shorthand="n",
        usage="A number to include in the sum.",
        default=List[Float64, True](1, 2),
    )

    root.execute()
