from prism import Flag, Command, CommandArc
from python import Python, PythonObject


fn base(command: CommandArc, args: List[String]) raises -> None:
    print("This is the base command!")


fn print_information(command: CommandArc, args: List[String]) raises -> None:
    print("Pass cat or dog as a subcommand, and see what you get!")


fn get_cat_fact(command: CommandArc, args: List[String]) raises -> None:
    var flags = command[].get_all_flags()[]
    var lover = flags.get_as_bool("lover")
    if lover and lover.value():
        print("Hello fellow cat lover!")

    var requests = Python.import_module("requests")
    # URL you want to send a GET request to
    var url = "https://cat-fact.herokuapp.com/facts/"

    # Send the GET request
    var response = requests.get(url)

    # Check if the request was successful (status code 200)
    if response.status_code == 200:
        var count = flags.get_as_int("count")
        if not count:
            raise Error("Count flag was not found.")
        var body = response.json()
        for i in range(count.value()):
            print(body[i]["text"])
    else:
        raise Error("Request failed!")


fn get_dog_breeds(command: CommandArc, args: List[String]) raises -> None:
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


fn init() raises -> None:
    var root_command = Command(name="nested", description="Base command.", run=base)

    var get_command = Command(
        name="get",
        description="Base command for getting some data.",
        run=print_information,
    )

    var cat_command = Command(
        name="cat",
        description="Get some cat facts!",
        run=get_cat_fact,
    )
    cat_command.flags.add_int_flag(name="count", shorthand="c", usage="Number of facts to get.")
    cat_command.flags.add_bool_flag(name="lover", shorthand="l", usage="Are you a cat lover?")

    var dog_command = Command(
        name="dog",
        description="Get some dog breeds!",
        run=get_dog_breeds,
    )

    get_command.add_command(cat_command)
    get_command.add_command(dog_command)
    root_command.add_command(get_command)
    root_command.execute()


fn main() raises -> None:
    init()
