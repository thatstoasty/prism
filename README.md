# Prism

A Budding CLI Library!

Inspired by: `Cobra`!

> [!NOTE]
> This library will often have breaking changes and it should not be used for anything in production.
NOTE: This does not work on Mojo 24.2, you must use the nightly build for now. This will be resolved in the next Mojo release.

## Usage

WIP: Documentation, but you should be able to figure out how to use the library by looking at the examples and referencing the Cobra documentation. You should be able to build the package by running `mojo package prism -I external`.

## Examples

Try out the `nested` example in the examples directory!

![Nested Example](https://github.com/thatstoasty/prism/blob/feature/documentation/demos/images/nested.png)

Start by navigating to the `nested` example directory.
`cd examples/nested`

Run the example by using the following command, we're not specifying a subcommand so we should be executing the root command.

![Nested 1](https://github.com/thatstoasty/prism/blob/feature/documentation/demos/tapes/nested-1.gif)

Now try running it with a subcommand.

![Nested 1](https://github.com/thatstoasty/prism/blob/feature/documentation/demos/tapes/nested-2.gif)

Let's follow the suggestion and add the cat subcommand.

![Nested 1](https://github.com/thatstoasty/prism/blob/feature/documentation/demos/tapes/nested-3.gif)

Now try running it with a flag to get three facts.

![Nested 1](https://github.com/thatstoasty/prism/blob/feature/documentation/demos/tapes/nested-4.gif)

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
- This library leans towards Errors as values over raising Exceptions.
- `Optional[Error]` would be much cleaner for Command `erroring_run` functions. For now return `Error()` if there's no `Error` to return.

## TODO

### Repository

- [ ] Add a description

### Documentation

### Features

- Add find suggestion logic to `Command` struct.
- Enable usage function to return the results of a usage function upon calling wrong functions or commands.
- Replace print usage with writers to enable stdout/stderr/file writing.
- Update default help command to improve available commands and flags section.

### Improvements

- Tree traversal improvements.
- Once we have kwarg unpacking, update `Command().add_flag` to pass kwargs along.
- Considering adding convenience functions for adding persistent flags, but I don't want to make the Command struct too massive. It may be better to just limit setting flags to the `command[].flags[].add_flag()` pattern. Auto dereferencing will most likely make this look less verbose in the future. For now persistent flags will be set via `command[].persistent_flags[].add_flag()`.
- Once we have `Result[T]`, I will refactor raising functions to return results instead.

### Bugs

- `Command` has 2 almost indentical init functions because setting a default `arg_validator` value, breaks the compiler as of 24.2.
