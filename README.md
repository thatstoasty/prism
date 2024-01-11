# prism
A Command Line Library to learn Mojo!

## Usage
TODO

## Examples
Try out the cat facts example in the examples directory!

Here's the script copied over from the main file.
```py
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
```

Try running the example by using the following command
`mojo run examples/cat_facts.py`

You should get the default result of 1 fact printed to the console. I always get the same fact.
`Owning a cat can reduce the risk of stroke and heart attack by a third.`

Now try running it with a flag to get up to five facts.
`mojo run examples/cat_facts.py --count=3`

```txt
Owning a cat can reduce the risk of stroke and heart attack by a third.
Most cats are lactose intolerant, and milk can cause painful stomach cramps and diarrhea. It's best to forego the milk and just give your cat the standard: clean, cool drinking water.
Domestic cats spend about 70 percent of the day sleeping and 15 percent of the day grooming.
```

Let's try running it from a compiled binary instead. Start by setting your `MOJO_PYTHON_LIBRARY` environment variable to your default python3 installation. We need to do this because we're using the `requests` module via Python interop.
`export MOJO_PYTHON_LIBRARY=$(which python3)`

Compile the example file into a binary.
`mojo build examples/cat_facts.py`

Now run the previous command, but with the binary instead.
`./examples/cat_facts --count=3`

You should get the same result as before! But, what about command information?
`./examples/cat_facts --help`

Usage information will be printed the console by passing the `--help` flag.
```
Get cat facts!

Usage:
  cat_facts [args] [flags]

Available commands:

Available flags:
  -h, --help    Displays help information about the command.
  -c, --count    Number of facts to get.

Use "cat_facts [command] --help" for more information about a command.
```

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