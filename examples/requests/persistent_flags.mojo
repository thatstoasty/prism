from memory import ArcPointer
from prism import Command, Context, Flag
import prism
from python import Python


fn base(ctx: Context) -> None:
    print("This is the base command!")
    return None


fn print_information(ctx: Context) -> None:
    print("Pass cat or dog as a subcommand, and see what you get!")
    return None


fn get_cat_fact(ctx: Context) raises -> None:
    var lover = ctx.command[].get_bool("lover")
    if lover:
        print("Hello fellow cat lover!")

    var requests = Python.import_module("requests")

    # URL you want to send a GET request to
    var url = "https://catfact.ninja/fact"

    # Send the GET requests
    var count = ctx.command[].get_int("count")
    if not count:
        raise Error("Count flag was not found.")

    for _ in range(count):
        var response = requests.get(url)

        # Check if the request was successful (status code 200)
        if response.status_code == 200:
            print(response.json()["fact"])
        else:
            print(response.json())
            raise Error("Request failed!")


fn get_dog_breeds(ctx: Context) raises -> None:
    var lover = ctx.command[].get_bool("lover")
    if lover:
        print("Hello fellow dog lover!")

    var requests = Python.import_module("requests")
    # URL you want to send a GET request to
    var url = "https://dog.ceo/api/breeds/list/all"

    # Send the GET request
    var response = requests.get(url)

    # Check if the request was successful (status code 200)
    if response.status_code == 200:
        print(response.json()["message"])
    else:
        raise Error("Request failed!")


fn pre_hook(ctx: Context) -> None:
    print("Pre-hook executed!")


fn post_hook(ctx: Context) -> None:
    print("Post-hook executed!")


fn main() -> None:
    var cat_command = ArcPointer(Command(
        name="cat",
        usage="Get some cat facts!",
        raising_run=get_cat_fact,
        flags=List[Flag](
            Flag.int(
                name="count",
                shorthand="c",
                usage="Number of facts to get.",
            )
        )
    ))

    var dog_command = ArcPointer(Command(
        name="dog",
        usage="Get some dog breeds!",
        raising_run=get_dog_breeds,
    ))

    var get_command = ArcPointer(Command(
        name="get",
        usage="Base command for getting some data.",
        run=print_information,
        persistent_pre_run=pre_hook,
        persistent_post_run=post_hook,
        flags=List[Flag](
            Flag.bool(
                name="lover",
                shorthand="l",
                usage="Are you an animal lover?",
                persistent=True,
            )
        ),
        children=List[ArcPointer[Command]](
            cat_command,
            dog_command
        )
    ))

    var root = Command(
        name="nested",
        usage="Base command.",
        run=base,
        children=List[ArcPointer[Command]](
            get_command
        )
    )

    root.execute()
