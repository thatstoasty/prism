# prism

A Budding CLI Library! Using this as a way to learn Mojo and to better understand CLI tooling development.

Inspired by: `Cobra`!

## Usage

WIP: Documentation, but you should be able to figure out how to use the library by looking at the examples and referencing the Cobra documentation. The `external` directory is only for the examples at the moment, so you should be able to build the package by running `mojo package prism`.

## Examples

Try out the `nested` example in the examples directory!

Here's the script copied over from the main file.

```py
from prism import Flag, Command, CommandArc
from python import Python, PythonObject


fn base(command: CommandArc, args: List[String]) raises -> None:
    print("This is the base command!")


fn print_information(command: CommandArc, args: List[String]) raises -> None:
    print("Pass cat or dog as a subcommand, and see what you get!")


fn get_cat_fact(command: CommandArc, args: List[String]) raises -> None:
    var requests = Python.import_module("requests")
    # URL you want to send a GET request to
    var url = "https://cat-fact.herokuapp.com/facts/"

    # Send the GET request
    var response = requests.get(url)

    # Check if the request was successful (status code 200)
    if response.status_code == 200:
        var count_flag = command[].get_all_flags()[].get_as_string("count")
        if not count_flag:
            raise Error("Count flag was not found.")
        var count = atol(count_flag.value())
        var body = response.json()
        for i in range(count):
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
    cat_command.add_flag(
        Flag(name="count", shorthand="c", usage="Number of facts to get.")
    )

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

```

Start by navigating to the `nested` example directory.
`cd examples/nested`

Run the example by using the following command, we're not specifying a subcommand so we should be executing the root command.

```bash
mojo run examples/nested/nested.mojo
This is the base command!
```

Now try running it with a subcommand.

```bash
mojo run examples/nested/nested.mojo get
Pass cat or dog as a subcommand, and see what you get!
```

Let's follow the suggestion and add the cat subcommand.

```bash
mojo run examples/nested/nested.mojo get cat
Owning a cat can reduce the risk of stroke and heart attack by a third.
```

Now try running it with a flag to get up to five facts.

```bash
mojo run examples/nested/nested.mojo get cat --count=5
Owning a cat can reduce the risk of stroke and heart attack by a third.
Most cats are lactose intolerant, and milk can cause painful stomach cramps and diarrhea. It's best to forego the milk and just give your cat the standard: clean, cool drinking water.
Domestic cats spend about 70 percent of the day sleeping and 15 percent of the day grooming.
The frequency of a domestic cat's purr is the same at which muscles and bones repair themselves.
Cats are the most popular pet in the United States: There are 88 million pet cats and 74 million dogs.
```

Let's try running it from a compiled binary instead. Start by setting your `MOJO_PYTHON_LIBRARY` environment variable to your default python3 installation. We need to do this because we're using the `requests` module via Python interop.
`export MOJO_PYTHON_LIBRARY=$(which python3)`

Compile the example file into a binary.
`mojo build examples/nested/nested.mojo`

Now run the previous command, but with the binary instead.
`./examples/nested/nested --count=3`

You should get the same result as before! But, what about command information?

```bash
./nested get cat --help
Get some cat facts!

Usage:
  nested get cat [args] [flags]

Available commands:

Available flags:
  -h, --help    Displays help information about the command.
  -c, --count    Number of facts to get.

Use "root get cat [command] --help" for more information about a command.
```

Usage information will be printed the console by passing the `--help` flag.

## TODO

### Repository

- [ ] Add a description
- [ ] Add examples

### Documentation

### Features

- Introduce persistent flags and commands to `Command` struct
- Add support for bool flags just passing of a flag. Like `--help`.
- Map `--help` flag to configurable help function.
- Add find suggestion logic to `Command` struct.
- Enable required flags.

### Improvements

- Help flags should be processed first, currently it's being checked after validating args and other flags.
- Tree traversal improvements.
- Figure out how to return mutable references.
- Once we have kwarg unpacking, update add_flag to pass kwargs along.
- It is difficult to have recursive relationships, not passing the command to the arg validator for now.
- Until `Error` is implements `CollectionElement`, `ArgValidator` functions return a string and throw the error from the caller.
- Non string flags without a value or default value will fail unless empty string can be converted to that type. Will update flags so they're typed.
- Switch arg parsing algorithm to not require an `=` for flag assignment

### Bugs

- Using `CommandArc` instead of `Arc[Command]` works for `Command.run` functions. But using `Arc[Command]` causes a recursive relationship error?
- `Command` has 2 almost indentical init functions because setting a default `arg_validator` value, breaks the compiler as of 24.2.
