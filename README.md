# Prism

![Mojo 24.3](https://img.shields.io/badge/Mojo%F0%9F%94%A5-24.3-purple)

A Budding CLI Library!

Inspired by: `Cobra`!

> [!NOTE]
> This library will often have breaking changes and it should not be used for anything in production.

## Usage

WIP: Documentation, but you should be able to figure out how to use the library by looking at the examples. 

You should be able to build the package by running `mojo package prism -I external`. For the easiest method, I recommend just copying the entire external folder into your repository, then copy the `prism` folder into the external folder as well.

> NOTE: It seems like `.mojopkg` files don't like being part of another package, eg. sticking all of your external deps in an `external` or `vendor` package. The only way I've gotten mojopkg files to work is to be in the same directory as the file being executed, and that directory cannot be a mojo package.

### Basic Command and Subcommand

Here's an example of a basic command and subcommand!

![Basic Example](https://github.com/thatstoasty/prism/blob/main/demos/images/chromeria.png)

![Chromeria](https://github.com/thatstoasty/prism/blob/main/demos/tapes/hello-chromeria.gif)

### Command Flags

Commands can have typed flags added to them to enable different behaviors.

```mojo
    var root_command = Command(
        name="logger", description="Base command.", run=handler
    )
    root_command.add_string_flag(name="type", shorthand="t", usage="Formatting type: [json, custom]")
```

![Logging](https://github.com/thatstoasty/prism/blob/main/demos/tapes/logging.gif)

### Command Aliases

Commands can also be aliased to enable different ways to call the same command. You can change the command underneath the alias and maintain the same behavior.

```mojo
var tool_command = Command(
        name="tool", description="This is a dummy command!", run=tool_func, aliases=List[String]("object", "thing")
    )
```

![Aliases](https://github.com/thatstoasty/prism/blob/main/demos/tapes/aliases.gif)

### Pre and Post Run Hooks

Commands can be configured to run pre-hook and post-hook functions before and after the command's main run function.

```mojo
fn pre_hook(command: CommandArc, args: List[String]) -> None:
    print("Pre-hook executed!")
    return None


fn post_hook(command: CommandArc, args: List[String]) -> None:
    print("Post-hook executed!")
    return None


fn init() -> None:
    var start = now()
    var root_command = Command(
        name="printer",
        description="Base command.",
        run=printer,
        pre_run=pre_hook,
        post_run=post_hook,
    )
```

![Printer](https://github.com/thatstoasty/prism/blob/main/demos/tapes/printer.gif)

### Persistent Flags and Hooks

Flags and hooks can also be inherited by children commands! This can be useful for setting global flags or hooks that should be applied to all child commands.

```mojo
fn init() -> None:
    var root_command = Command(name="nested", description="Base command.", run=base)

    var get_command = Command(
        name="get",
        description="Base command for getting some data.",
        run=print_information,
        persistent_pre_run=pre_hook,
        persistent_post_run=post_hook,
    )
    get_command.persistent_flags[].add_bool_flag(name="lover", shorthand="l", usage="Are you an animal lover?")
```

![Persistent](https://github.com/thatstoasty/prism/blob/main/demos/tapes/persistent.gif)

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
    tool_command.mark_flags_required_together("color", "formatting")
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

![Flag Groups](https://github.com/thatstoasty/prism/blob/main/demos/tapes/flag_groups.gif)

> NOTE: If you want to enforce a rule on persistent flags, then the child command must be added to the parent command **BEFORE** setting the rule.

See `examples/flag_groups/child.mojo` for an example.

```mojo
fn init() -> None:
    var root_command = Command(
        name="my",
        description="This is a dummy command!",
        run=test,
    )
    # Persistent flags are defined on the parent command.
    root_command.persistent_flags[].add_bool_flag(name="required", shorthand="r", usage="Always required.")
    root_command.persistent_flags[].add_string_flag(name="host", shorthand="h", usage="Host")
    root_command.persistent_flags[].add_string_flag(name="port", shorthand="p", usage="Port")
    root_command.mark_persistent_flag_required("required")

    var tool_command = Command(
        name="tool", description="This is a dummy command!", run=tool_func
    )
    tool_command.add_bool_flag(name="also", shorthand="a", usage="Also always required.")
    tool_command.add_string_flag(name="uri", shorthand="u", usage="URI")

    # Child commands are added to the parent command.
    root_command.add_command(tool_command)

    # Rules are set on the child command, which can include persistent flags inherited from the parent command.
    # When executing `mark_flags_required_together()` or `mark_flags_mutually_exclusive()`,
    # the inherited flags from all parents will merged into the tool_command.flags FlagSet.
    tool_command.mark_flag_required("also")
    tool_command.mark_flags_required_together("host", "port")
    tool_command.mark_flags_mutually_exclusive("host", "uri")

    root_command.execute()
```

![Flag Groups 2](https://github.com/thatstoasty/prism/blob/main/demos/tapes/flag_groups-2.gif)

### Positional and Custom Arguments

Validation of positional arguments can be specified using the `arg_validator` field of `Command`. The following validators are built in:

- Number of arguments:
  - `no_args` - report an error if there are any positional args.
  - `arbitrary_args` - accept any number of args.
  - `minimum_n_args[Int]` - report an error if less than N positional args are provided.
  - `maximum_n_args[Int]` - report an error if more than N positional args are provided.
  - `exact_args[Int]` - report an error if there are not exactly N positional args.
  - `range_args[min, max]` - report an error if the number of args is not between min and max.
- Content of the arguments:
  - `only_valid_args` - report an error if there are any positional args not specified in the `valid_args` field of `Command`, which can optionally be set to a list of valid values for positional args.

If `arg_validator` is undefined, it defaults to `arbitrary_args`.

> NOTE: `match_all` is unstable at the moment. I will work on ironing it out in the near future. This most likely does not work.

Moreover, `match_all[arg_validators: List[ArgValidator]]` enables combining existing checks with arbitrary other checks. For instance, if you want to report an error if there are not exactly N positional args OR if there are any positional args that are not in the ValidArgs field of Command, you can call `match_all` on `exact_args` and `only_valid_args`, as shown below:

```mojo
fn test_match_all():
    var result = match_all[
        List[ArgValidator](
            range_args[0, 1](),
            valid_args[List[String]("Pineapple")]()
        )
    ]()(List[String]("abc", "123"))
    testing.assert_equal(result.value()[], "Command accepts between 0 to 1 argument(s). Received: 2.")
```

![Arg Validators](https://github.com/thatstoasty/prism/blob/main/demos/tapes/arg_validators.gif)

### Help Commands

Commands are configured to accept a `--help` flag by default. This will print the output of a default help function. You can also configure a custom help function to be run when the `--help` flag is passed.

```mojo
fn help_func(command: Arc[Command]) -> String:
    return ""

fn init() -> None:
    var root_command = Command(
        name="hello",
        description="This is a dummy command!",
        run=test,
    )

    var hello_command = Command(name="chromeria", description="This is a dummy command!", run=hello, help=help_func)
```

![Help](https://github.com/thatstoasty/prism/blob/main/demos/tapes/help.gif)

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
- Error message from `get_flags` comes up blank when finally exiting the program. For now, just printing the error message before the Error is returned. Seems like an issue with catching a raised Error and then returning it. Will try returning an Error instead of raising it.
