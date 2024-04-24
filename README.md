# Prism

A Budding CLI Library!

Inspired by: `Cobra`!

> [!NOTE]
> This library will often have breaking changes and it should not be used for anything in production.
NOTE: This does not work on Mojo 24.2, you must use the nightly build for now. This will be resolved in the next Mojo release.

## Usage

WIP: Documentation, but you should be able to figure out how to use the library by looking at the examples and referencing the Cobra documentation. You should be able to build the package by running `mojo package prism -I .`.

## Examples

Try out the `nested` example in the examples directory!

Here's the script copied over from the main file.

```mojo
from prism import Flag, Command, CommandArc
from python import Python, PythonObject


fn base(command: CommandArc, args: List[String]) -> None:
    print("This is the base command!")
    return None


fn print_information(command: CommandArc, args: List[String]) -> None:
    print("Pass cat or dog as a subcommand, and see what you get!")
    return None


fn get_cat_fact(command: CommandArc, args: List[String]) -> Error:
    var flags = command[].get_all_flags()[]
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


fn get_dog_breeds(command: CommandArc, args: List[String]) -> Error:
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


fn init() -> None:
    var root_command = Command(name="nested", description="Base command.", run=base)

    var get_command = Command(
        name="get",
        description="Base command for getting some data.",
        run=print_information,
    )

    var cat_command = Command(
        name="cat",
        description="Get some cat facts!",
        erroring_run=get_cat_fact,
    )
    cat_command.flags.add_int_flag[name="count", shorthand="c", usage="Number of facts to get."]()
    cat_command.flags.add_bool_flag[name="lover", shorthand="l", usage="Are you a cat lover?"]()

    var dog_command = Command(
        name="dog",
        description="Get some dog breeds!",
        erroring_run=get_dog_breeds,
    )

    get_command.add_command(cat_command)
    get_command.add_command(dog_command)
    root_command.add_command(get_command)
    root_command.execute()


fn main() -> None:
    init()


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
mojo run nested.mojo get cat --count 5
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
`./nested --count 3`

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

## Notes

- Flags can have values passed by using the `=` operator. Like `--count=5` OR like `--count 5`.
- Commands can be created via a typical `Command()` constructor to use runtime values, or you can use `Command.new()` method to create a new `Command` using compile time `Parameters` instead (when possible).
- This library leans towards Errors as values over raising Exceptions.
- `Optional[Error]` would be much cleaner for Command run functions. For now return `Error()` if there's no `Error` to return.

## TODO

### Repository

- [ ] Add a description

### Documentation

### Features

- Add find suggestion logic to `Command` struct.
- Enable required flags.
- Replace print usage with writers to enable stdout/stderr/file writing.

### Improvements

- Tree traversal improvements.
- Figure out how to return mutable references.
- Once we have kwarg unpacking, update add_flag to pass kwargs along.
- It is difficult to have recursive relationships, not passing the command to the arg validator for now.
- Until `Error` is implements `CollectionElement`, `ArgValidator` functions return a string and throw the error from the caller.
- Considering adding convenience functions for adding persistent flags, but I don't want to make the Command struct too massive. It may be better to just limit setting flags to the `command[].flags[].add_flag()` pattern. Auto dereferencing will most likely make this look like verbose in the future. For now persistent flags will be set via `command[].persistent_flags[].add_flag()`.

### Bugs

- Using `CommandArc` instead of `Arc[Command]` works for `Command.run` functions. But using `Arc[Command]` causes a recursive relationship error?
- `Command` has 2 almost indentical init functions because setting a default `arg_validator` value, breaks the compiler as of 24.2.
