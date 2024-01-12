from prism import Flag, InputFlags, PositionalArgs, Command, CommandMap, add_command
from python import Python, PythonObject


fn base(args: PositionalArgs, flags: InputFlags) raises -> None:
    print("This is the base command!")


fn print_information(args: PositionalArgs, flags: InputFlags) raises -> None:
    print("Pass cat or dog as a subcommand, and see what you get!")


fn get_cat_fact(args: PositionalArgs, flags: InputFlags) raises -> None:
    let requests = Python.import_module("requests")
    # URL you want to send a GET request to
    let url = 'https://cat-fact.herokuapp.com/facts/'

    # Send the GET request
    let response = requests.get(url)

    # Check if the request was successful (status code 200)
    if response.status_code == 200:
        let count_flag = flags.get("count", "1")
        let count = atol(count_flag)
        let body = response.json()
        for i in range(count):
            print(body[i]['text'])
    else:
        raise Error('Request failed!')


fn get_dog_breeds(args: PositionalArgs, flags: InputFlags) raises -> None:
    let requests = Python.import_module("requests")
    # URL you want to send a GET request to
    let url = 'https://dog.ceo/api/breeds/list/all'

    # Send the GET request
    let response = requests.get(url)

    # Check if the request was successful (status code 200)
    if response.status_code == 200:
        print(response.json()["message"])
    else:
        raise Error('Request failed!')


fn init() raises -> None:
    var command_map = CommandMap()
    var root_command = Command(
        name        = "root", 
        description = "Base command.", 
        run         = base
    )

    command_map[root_command.name] = root_command

    var get_command = Command(
        name        = "get", 
        description = "Base command for getting some data.", 
        run         = print_information
    )
    add_command(get_command, root_command, command_map)

    var cat_command = Command(
        name="cat",
        description="Get some cat facts!",
        run=get_cat_fact,
    )
    cat_command.add_flag(Flag("count", "c", "Number of facts to get."))
    add_command(cat_command, get_command, command_map)

    var dog_command = Command(
        name="dog",
        description="Get some dog breeds!",
        run=get_dog_breeds,
    )
    add_command(dog_command, get_command, command_map)

    root_command.execute(command_map)


fn main() raises -> None:
    _ = init()
