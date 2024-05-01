# Prism

A Budding CLI Library!

Inspired by: `Cobra`!

> [!NOTE]
> This library will often have breaking changes and it should not be used for anything in production.
NOTE: This does not work on Mojo 24.2, you must use the nightly build for now. This will be resolved in the next Mojo release.

## Usage

WIP: Documentation, but you should be able to figure out how to use the library by looking at the examples and referencing the Cobra documentation. You should be able to build the package by running `mojo package prism -I external`.

### Basic Command and Subcommand

![Nested Example](https://github.com/thatstoasty/prism/blob/feature/documentation/demos/images/chromeria.png)

![Chromeria 1](https://github.com/thatstoasty/prism/blob/feature/documentation/demos/tapes/hello-chromeria.gif)

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
