from memory import Arc
from prism import Command, CommandArc
from python import Python, PythonObject


fn base(command: Arc[Command], args: List[String]) -> None:
    print("This is the base command!")
    return None


fn print_information(command: Arc[Command], args: List[String]) -> None:
    print("Pass cat or dog as a subcommand, and see what you get!")
    return None


fn get_cat_fact(command: Arc[Command], args: List[String]) -> Error:
    var cmd = command
    var flags = cmd[].flags
    var lover = flags.get_as_bool("lover")
    if lover and lover.value():
        print("Hello fellow cat lover!")

    try:
        var requests = Python.import_module("requests")

        # URL you want to send a GET request to
        var url = "https://cat-fact.herokuapp.com/facts/"

        # Send the GET request
        var response = requests.get(url)

        # Check if the request was successful (status code 200)
        if response.status_code == 200:
            var count = flags.get_as_int("count")
            if not count:
                return Error("Count flag was not found.")
            var body = response.json()
            for i in range(count.value()):
                print(body[i]["text"])
        else:
            return Error("Request failed!")
    except e:
        return e

    return Error()


fn get_dog_breeds(command: Arc[Command], args: List[String]) -> Error:
    var cmd = command
    var flags = cmd[].flags
    var lover = flags.get_as_bool("lover")
    if lover and lover.value():
        print("Hello fellow dog lover!")

    try:
        var requests = Python.import_module("requests")
        # URL you want to send a GET request to
        var url = "https://dog.ceo/api/breeds/list/all"

        # Send the GET request
        var response = requests.get(url)

        # Check if the request was successful (status code 200)
        if response.status_code == 200:
            print(response.json()["message"])
        else:
            return Error("Request failed!")
    except e:
        return e

    return Error()


fn pre_hook(command: Arc[Command], args: List[String]) -> None:
    print("Pre-hook executed!")


fn post_hook(command: Arc[Command], args: List[String]) -> None:
    print("Post-hook executed!")


fn main() -> None:
    var root_command = Arc(Command(name="nested", description="Base command.", run=base))

    var get_command = Arc(
        Command(
            name="get",
            description="Base command for getting some data.",
            run=print_information,
            persistent_pre_run=pre_hook,
            persistent_post_run=post_hook,
        )
    )
    get_command[].persistent_flags.add_bool_flag(name="lover", shorthand="l", usage="Are you an animal lover?")

    var cat_command = Arc(
        Command(
            name="cat",
            description="Get some cat facts!",
            erroring_run=get_cat_fact,
        )
    )
    cat_command[].flags.add_int_flag(name="count", shorthand="c", usage="Number of facts to get.")

    var dog_command = Arc(
        Command(
            name="dog",
            description="Get some dog breeds!",
            erroring_run=get_dog_breeds,
        )
    )

    get_command[].add_command(cat_command)
    get_command[].add_command(dog_command)
    root_command[].add_command(get_command)
    root_command[].execute()
