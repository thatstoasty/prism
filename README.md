# Prism

A Budding CLI Library!

Inspired by: `Cobra`!

> [!NOTE]
> This library will often have breaking changes and it should not be used for anything in production.
NOTE: This does not work on Mojo 24.2, you must use the nightly build for now. This will be resolved in the next Mojo release.

## Usage

WIP: Documentation, but you should be able to figure out how to use the library by looking at the examples and referencing the Cobra documentation. You should be able to build the package by running `mojo package prism -I external`.

### Basic Command and Subcommand

Here's an example of a basic command and subcommand!

![Basic Example](https://github.com/thatstoasty/prism/blob/feature/documentation/demos/images/chromeria.png)

![Chromeria](https://github.com/thatstoasty/prism/blob/feature/documentation/demos/tapes/hello-chromeria.gif)

### Command Flags

Commands can have typed flags added to them to enable different behaviors.

```mojo
    var root_command = Command(
        name="logger", description="Base command.", run=handler, arg_validator=minimum_n_args[1]()
    )
    root_command.add_string_flag(name="type", shorthand="t", usage="Formatting type: [json, custom]")
```

![Logging](https://github.com/thatstoasty/prism/blob/feature/documentation/demos/tapes/logging.gif)

### Command Aliases

Commands can also be aliased to enable different ways to call the same command. You can change the command underneath the alias and maintain the same behavior.

```mojo
var tool_command = Command(
        name="tool", description="This is a dummy command!", run=tool_func, aliases=List[String]("object", "thing")
    )
```

![Aliases](https://github.com/thatstoasty/prism/blob/feature/documentation/demos/tapes/aliases.gif)

### Required flags

Flags can be grouped together to enable relationships between them. This can be used to enable different behaviors based on the flags that are passed.

By default flags are considered optional. If you want your command to report an error when a flag has not been set, mark it as required:

```mojo
var tool_command = Command(
        name="tool", description="This is a dummy command!", run=tool_func, aliases=List[String]("object", "thing")
    )
    tool_command.add_bool_flag(name="required", shorthand="r", usage="Always required.")
    tool_command.mark_flag_required("required")
```

Same for persistent flags:

```mojo
    var root_command = Command(
        name="my",
        description="This is a dummy command!",
        run=test,
    )
    root_command.persistent_flags[].add_bool_flag(name="free", shorthand="f", usage="Always required.")
    root_command.mark_persistent_flag_required("free")
```

### Flag Groups

If you have different flags that must be provided together (e.g. if they provide the `--color` flag they MUST provide the `--formatting` flag as well) then Prism can enforce that requirement:

```mojo
    var tool_command = Command(
        name="tool", description="This is a dummy command!", run=tool_func, aliases=List[String]("object", "thing")
    )
    tool_command.add_string_flag(name="color", shorthand="c", usage="Text color", default="#3464eb")
    tool_command.add_string_flag(name="formatting", shorthand="f", usage="Text formatting")
    tool_command.mark_flags_one_required_together("color", "formatting")
```

You can also prevent different flags from being provided together if they represent mutually exclusive options such as specifying an output format as either `--color` or `--hue` but never both:

```mojo
   var tool_command = Command(
        name="tool", description="This is a dummy command!", run=tool_func, aliases=List[String]("object", "thing")
    )
    tool_command.add_string_flag(name="color", shorthand="c", usage="Text color", default="#3464eb")
    tool_command.add_string_flag(name="hue", shorthand="x", usage="Text color", default="#3464eb")
    tool_command.mark_flags_mutually_exclusive("color", "hue")
```

If you want to require at least one flag from a group to be present, you can use `mark_flags_one_required`. This can be combined with `mark_flags_mutually_exclusive` to enforce exactly one flag from a given group:

```mojo
   var tool_command = Command(
        name="tool", description="This is a dummy command!", run=tool_func, aliases=List[String]("object", "thing")
    )
    tool_command.add_string_flag(name="color", shorthand="c", usage="Text color", default="#3464eb")
    tool_command.add_string_flag(name="formatting", shorthand="f", usage="Text formatting")
    tool_command.mark_flags_one_required("color", "formatting")
    tool_command.mark_flags_mutually_exclusive("color", "formatting")
```

In these cases:

- both local and persistent flags can be used
  - NOTE: the group is only enforced on commands where every flag is defined
- a flag may appear in multiple groups
- a group may contain any number of flags

![Flag Groups](https://github.com/thatstoasty/prism/blob/feature/documentation/demos/tapes/flag_groups.gif)

### Pre and Post Run Hooks

![Printer](https://github.com/thatstoasty/prism/blob/feature/documentation/demos/tapes/printer.gif)

### Persistent Flags and Hooks

Flags and

![Persistent](https://github.com/thatstoasty/prism/blob/feature/documentation/demos/tapes/persistent.gif)


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
- Need to add `mark_flag_required` to the `Command` struct.

### Improvements

- Tree traversal improvements.
- Once we have kwarg unpacking, update `Command().add_flag` to pass kwargs along.
- Considering adding convenience functions for adding persistent flags, but I don't want to make the Command struct too massive. It may be better to just limit setting flags to the `command[].flags[].add_flag()` pattern. Auto dereferencing will most likely make this look less verbose in the future. For now persistent flags will be set via `command[].persistent_flags[].add_flag()`.
- Once we have `Result[T]`, I will refactor raising functions to return results instead.

### Bugs

- `Command` has 2 almost indentical init functions because setting a default `arg_validator` value, breaks the compiler as of 24.2.
- Error message from `get_flags` comes up blank when finally exiting the program. For now, just printing the error message before the Error is returned.
