# prism
A Budding CLI Library! Using this as a way to learn Mojo and to better understand CLI tooling development.

Inspired by: `Cobra`!

## Usage
TODO

## Examples
Try out the `nested` example in the examples directory!

Here's the script copied over from the main file.
```py
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
```

Start by navigating to the `nested` example directory.
`cd examples/nested`

Run the example by using the following command, we're not specifying a subcommand so we should be executing the root command.
```bash
mojo run nested.mojo
This is the base command!
```

Now try running it with a subcommand.
```bash
mojo run nested.mojo get
Pass cat or dog as a subcommand, and see what you get!
```

Let's follow the suggestion and add the cat subcommand.
```bash
mojo run nested.mojo get cat
Owning a cat can reduce the risk of stroke and heart attack by a third.
```

Now try running it with a flag to get up to five facts.
```bash
mojo run nested.mojo get cat --count=5
Owning a cat can reduce the risk of stroke and heart attack by a third.
Most cats are lactose intolerant, and milk can cause painful stomach cramps and diarrhea. It's best to forego the milk and just give your cat the standard: clean, cool drinking water.
Domestic cats spend about 70 percent of the day sleeping and 15 percent of the day grooming.
The frequency of a domestic cat's purr is the same at which muscles and bones repair themselves.
Cats are the most popular pet in the United States: There are 88 million pet cats and 74 million dogs.
```

Let's try running it from a compiled binary instead. Start by setting your `MOJO_PYTHON_LIBRARY` environment variable to your default python3 installation. We need to do this because we're using the `requests` module via Python interop.
`export MOJO_PYTHON_LIBRARY=$(which python3)`

Compile the example file into a binary.
`mojo build nested.mojo`

Now run the previous command, but with the binary instead.
`./nested --count=3`

You should get the same result as before! But, what about command information?
```bash
./nested get cat --help
Get some cat facts!

Usage:
  root get cat [args] [flags]

Available commands:

Available flags:
  -h, --help    Displays help information about the command.
  -c, --count    Number of facts to get.

Use "root get cat [command] --help" for more information about a command.
```

Usage information will be printed the console by passing the `--help` flag.

## TODO:
### Repository
- [ ] Add a description
- [ ] Add examples

### Documentation

### Features
- Add pre run, post run, and persistent flags to Command struct
- Find better solution to command map usage.
- Switch to passing commands to command run functions instead of passing flags and args.
  - Refactor get flag as type functions when commands after the above change.