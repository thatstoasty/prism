from memory import ArcPointer
from prism import Command, Context, Flag
import prism


fn test(ctx: Context) raises -> None:
    name = ctx.command[].get_string_list("name")
    print("Hello {}".format(" ".join(name)))


fn sum(ctx: Context) raises -> None:
    numbers = ctx.command[].get_int_list("number")
    sum = 0
    for number in numbers:
        sum += number[]
    print("The sum is: {}".format(sum))


fn sum_float(ctx: Context) raises -> None:
    numbers = ctx.command[].get_float64_list("number")
    sum = 0.0
    for number in numbers:
        sum += number[]
    print("The sum is: {}".format(sum))


fn main() -> None:
    Command(
        name="greet",
        usage="Greet a user!",
        raising_run=test,
        flags=List[Flag](
            Flag.string_list(
                name="name",
                shorthand="n",
                usage="The name of the person to greet.",
                default=List[String]("Mikhail", "Tavarez")
            )
        ),
        children=List[ArcPointer[Command]](
            ArcPointer(
                Command(
                    name="sum",
                    usage="Add up the numbers passed in with the -n flag!",
                    raising_run=sum,
                    flags=List[Flag](
                        Flag.int_list(
                            name="number",
                            shorthand="n",
                            usage="A number to include in the sum.",
                            default=List[Int, True](1, 2)
                        )
                    )
                )
            ),
            ArcPointer(
                Command(
                    name="sum_float",
                    usage="Add up the numbers passed in with the -n flag!",
                    raising_run=sum_float,
                    flags=List[Flag](
                        Flag.float64_list(
                            name="number",
                            shorthand="n",
                            usage="A number to include in the sum.",
                            default=List[Float64, True](1, 2)
                        )
                    )
                )
            )
        )
    ).execute()
