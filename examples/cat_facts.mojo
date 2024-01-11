from prism import Flag, InputFlags, PositionalArgs, Command, CommandMap, add_command
from python import Python, PythonObject


fn get_fact(args: PositionalArgs, flags: InputFlags) raises -> None:
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


fn init() raises -> None:
    var command_map = CommandMap()
    var root_command = Command(
        name        = "cat_facts", 
        description = "Get cat facts!", 
        run         = get_fact
    )

    root_command.add_flag(Flag("count", "c", "Number of facts to get."))
    command_map[root_command.name] = root_command

    root_command.execute(command_map)


fn main() raises -> None:
    _ = init()
