# Prism

A Budding CLI Library!

Prism is a Mojo library designed to help you build command-line interfaces (CLI) with ease. It provides a simple and intuitive way to define commands, subcommands, flags, and hooks, making it easier to create powerful CLI applications. This is primarily a pet project of mine, so expect it to be a bit rough around the edges. I plan to add more features and polish it up as I go along!

Inspired by: `Cobra` and `urfave/cli`!

![Mojo Version](https://img.shields.io/badge/Mojo%F0%9F%94%A5-25.4-orange)
![Build Status](https://github.com/thatstoasty/prism/actions/workflows/build.yml/badge.svg)
![Test Status](https://github.com/thatstoasty/prism/actions/workflows/test.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Installation

1. First, you'll need to configure your `mojoproject.toml` file to include my Conda channel. Add `"https://repo.prefix.dev/mojo-community"` to the list of channels.
2. Next, add `prism` to your project's dependencies by running `pixi add prism`.
3. Finally, run `pixi install` to install in `prism` and its dependencies. You should see the `.mojopkg` files in `$CONDA_PREFIX/lib/mojo/` (usually resolves to `.pixi/envs/default/lib/mojo`).

## Basic Command and Subcommand

Here's an example of a basic command and subcommand!

```mojo
from prism import Command, Context, FlagSet

fn test(args: List[String], flags: FlagSet) -> None:
    print("Pass chromeria as a subcommand!")

fn hello(args: List[String], flags: FlagSet) -> None:
    print("Hello from Chromeria!")

fn main() -> None:
    var cli = Command(
        name="hello",
        description="This is a dummy command!",
        run=test,
        children=[
            Command(
                name="chromeria",
                description="This is a dummy command!",
                run=hello
            )
        ],
    )
    cli.execute()
```

![Chromeria](https://github.com/thatstoasty/prism/blob/main/doc/tapes/hello-chromeria.gif)

## Why are subcommands wrapped with `ArcPointer`?

Due to the nature of self-referential structs, we need to use a smart pointer to reference the subcommand. The child command is owned by the `ArcPointer`, and that pointer is then shared across the program execution.

## Accessing arguments

`prism` provides the parsed arguments as part of the `ctx` argument.

```mojo
from prism import FlagSet

fn printer(args: List[String], flags: FlagSet) raises -> None:
    if len(args) == 0:
        raise Error("No args provided.")

    for arg in args:
        print(arg)
```

## Command Aliases

Commands can also be aliased to enable different ways to call the same command. You can change the command underneath the alias and maintain the same behavior.

```mojo
from prism import Command

fn main():
    var cli = Command(
        name="tool",
        description="This is a dummy command!",
        run=tool_func,
        aliases=["object", "thing"]
    )
    cli.execute()
```

![Aliases](https://github.com/thatstoasty/prism/blob/main/doc/tapes/aliases.gif)

## Pre and Post Run Hooks

Commands can be configured to run pre-hook and post-hook functions before and after the command's main run function.

```mojo
from prism import Command, FlagSet

fn pre_hook(args: List[String], flags: FlagSet) -> None:
    print("Pre-hook executed!")

fn post_hook(args: List[String], flags: FlagSet) -> None:
    print("Post-hook executed!")

fn main() -> None:
    var cli = Command(
        name="printer",
        description="Base command.",
        run=printer,
        pre_run=pre_hook,
        post_run=post_hook,
    )
    cli.execute()
```

![Printer](https://github.com/thatstoasty/prism/blob/main/doc/tapes/printer.gif)

## Flags

Commands can have typed flags added to them to enable different behaviors.

```mojo
from prism import Command, Flag

fn main() -> None:
    var cli = Command(
        name="logger",
        description="Base command.",
        run=handler,
        flags=[
            Flag.string(
                name="type",
                shorthand="t",
                usage="Formatting type: [json, custom]",
            )
        ],
    )
    cli.execute()
```

![Logging](https://github.com/thatstoasty/prism/blob/main/doc/tapes/logging.gif)

### Default flag values from environment variables

Flag values can also be retrieved from environment variables, if a value is not provided as an argument.

```mojo
from prism import Command, Flag, FlagSet

fn test(args: List[String], flags: FlagSet) raises -> None:
    if name := flags.get_string("name"):
        print("Hello ", name[])

fn main() -> None:
    var cli = Command(
        name="greet",
        usage="Greet a user!",
        raising_run=test,
        flags=[
            Flag.string(
                name="name",
                shorthand="n",
                usage="The name of the person to greet.",
                environment_variable="NAME",
            )
        ],
    )
    cli.execute()
```

### Default flag values from files

Likewise, flag values can also be retrieved from a file as well, if a value is not provided as an argument.

```mojo
from prism import Command, Flag, FlagSet
import prism

fn test(args: List[String], flags: FlagSet) raises -> None:
    if name := flags.get_string("name"):
        print("Hello ", name[])

fn main() -> None:
    var cli = Command(
        name="greet",
        usage="Greet a user!",
        raising_run=test,
        flags=[
            Flag.string(
                name="name",
                shorthand="n",
                usage="The name of the person to greet.",
                file_path="~/.myapp/config",
            )
        ],
    )
    cli.execute()
```

### Flag Precedence

The precedence for flag value sources is as follows (highest to lowest):

1. Command line flag value from user
2. Environment variable (if specified)
3. Configuration file (if specified)
4. Default defined on the flag

### Persistent Flags and Hooks

Flags and hooks can also be inherited by children commands! This can be useful for setting global flags or hooks that should be applied to all child commands.

```mojo
from prism import Command, Flag

fn main() -> None:
    var cli = Command(
        name="nested",
        description="Base command.",
        run=base,
        children=[
            Command(
                name="get",
                description="Base command for getting some data.",
                run=print_information,
                persistent_pre_run=pre_hook,
                persistent_post_run=post_hook,
            )
        ],
        flags=[
            Flag.bool(
                name="lover",
                shorthand="l",
                usage="Are you an animal lover?",
                persistent=True,
            )
        ],
    )
    cli.execute()
```

![Persistent](https://github.com/thatstoasty/prism/blob/main/doc/tapes/persistent.gif)

### Required flags

Flags can be grouped together to enable relationships between them. This can be used to enable different behaviors based on the flags that are passed.

By default flags are considered optional. If you want your command to report an error when a flag has not been set, mark it as required:

```mojo
from prism import Command, Flag, FlagSet

fn main():
    var cli = Command(
        name="tool",
        description="This is a dummy command!",
        run=tool_func,
        aliases=["object", "thing"],
        flags=[
            Flag.bool(
                name="required",
                shorthand="r",
                usage="Always required.",
                required=True,
            )
        ],
    )
    cli.execute()
```

### Flag Groups

If you have different flags that must be provided together (e.g. if they provide the `--color` flag they MUST provide the `--formatting` flag as well) then Prism can enforce that requirement:

```mojo
from prism import Command, Flag
import prism

fn main():
    var cli = Command(
        name="tool",
        description="This is a dummy command!",
        run=tool_func,
        aliases=["object", "thing"],
        flags=[
            Flag.uint32(
                name="color",
                shorthand="c",
                usage="Text color",
                default=0x3464eb,
            ),
            Flag.string(
                name="formatting",
                shorthand="f",
                usage="Text formatting",
            ),
        ],
        flags_required_together=["color", "formatting"],
    )
    cli.execute()
```

You can also prevent different flags from being provided together if they represent mutually exclusive options such as specifying an output format as either `--color` or `--hue` but never both:

```mojo
from prism import Command, Flag

fn main():
   var cli = Command(
        name="tool",
        description="This is a dummy command!",
        run=tool_func,
        aliases=["object", "thing"],
        flags=[
            Flag.uint32(
                name="color",
                shorthand="c",
                usage="Text color",
                default=0x3464eb,
            ),
            Flag.uint32(
                name="hue",
                shorthand="x",
                usage="Text color",
                default=0x3464eb,
            ),
        ],
        mutually_exclusive_flags=["color", "hue"],
    )
    cli.execute()
```

If you want to require at least one flag from a group to be present, you can use `mark_flags_one_required`. This can be combined with `mark_flags_mutually_exclusive` to enforce exactly one flag from a given group:

```mojo
from prism import Command, Flag

fn main():
   var cli = Command(
        name="tool",
        description="This is a dummy command!",
        run=tool_func,
        aliases=["object", "thing"],
        flags=[
            Flag.uint32(
                name="color",
                shorthand="c",
                usage="Text color",
                default=0x3464eb,
            ),
            Flag.string(
                name="formatting",
                shorthand="f",
                usage="Text formatting",
            ),
        ],
        one_required_flags=["color", "formatting"],
        mutually_exclusive_flags=["color", "formatting"],
    )
    cli.execute()
```

In these cases:

- The group is only enforced on commands where every flag is defined.
- A flag may appear in multiple groups.
- A group may contain any number of flags.

![Flag Groups](https://github.com/thatstoasty/prism/blob/main/doc/tapes/flag_groups.gif)

### Suggesting alternative flags

If a flag is not provided, you can suggest an alternative flag to the user. This can be useful for providing hints to the user about what they may have meant to type.

```mojo
from prism import Command, Flag
import prism

fn main():
    var cli = Command(
        name="tool",
        description="This is a dummy command!",
        run=tool_func,
        aliases=["object", "thing"],
        flags=[
            Flag.string(
                name="color",
                shorthand="c",
                usage="Text color",
                default=0x3464eb,
            ),
            Flag.string(
                name="formatting",
                shorthand="f",
                usage="Text formatting",
            ),
        ],
        suggest=True,
    )
    cli.execute()
```

If you run the command with an invalid flag, it will suggest the closest match to the flag you provided.

```bash
mojo cli.mojo --volor
```

will suggest:

```txt
Unknown flag: volor
Did you mean: --color
```

## Positional and Custom Arguments

Validation of positional arguments can be specified using the `arg_validator` field of `Command`. The following validators are built in:

- Number of arguments:
  - `no_args` - report an error if there are any positional args.
  - `arbitrary_args` - accept any number of args.
  - `minimum_n_args[Int]` - report an error if less than N positional args are provided.
  - `maximum_n_args[Int]` - report an error if more than N positional args are provided.
  - `exact_args[Int]` - report an error if there are not exactly N positional args.
  - `range_args[min, max]` - report an error if the number of args is not between min and max.
- Content of the arguments:
  - `valid_args` - report an error if there are any positional args not specified in the `valid_args` field of `Command`, which can optionally be set to a list of valid values for positional args.
- Composition of validators:
  - `match_all` - pass a list of validators to ensure all of them pass.

If `arg_validator` is undefined, it defaults to `arbitrary_args`.

![Arg Validators](https://github.com/thatstoasty/prism/blob/main/doc/tapes/arg_validators.gif)

## Common Flags

### Help

Commands are configured to accept a `--help` and `-h` flag by default. This will print the output of a default help function. You can also configure a custom help function to be run when the `--help` flag is passed. You can use the `help` argument of the `Command` constructor to configure the help function, and the help flag itself.

```mojo
from prism import Command, FlagSet, Flag, Help

fn help_func(args: List[String], flags: FlagSet) -> String:
    return "My help function."

fn main() -> None:
    var cli = Command(
        name="hello",
        description="This is a dummy command!",
        run=test,
        help=Help(
            flag=Flag.bool(name="custom-help", shorthand="ch", usage="My Cool Help Flag."),
            action=help_func,
        ),
    )
    cli.execute()
```

![Help](https://github.com/thatstoasty/prism/blob/main/doc/tapes/help.gif)

### Version

Commands can be configured to accept `--version` and `-v` flag to run a version function. This will print the result of the version function using the output writer that's configured for the command. You can also configure the flag and function to run when the version flag is passed by using the `version` argument of the `Command` constructor.

```mojo
from prism import Command, FlagSet, Version, Flag

fn test(args: List[String], flags: FlagSet) -> None:
    print("Pass -v to see the version!")

fn version(version: String) -> String:
    return "MyCLI version: " + version

fn main() -> None:
    var cli = Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        version=Version(
            "0.1.0",
            flag=Flag.bool(name="custom-version", shorthand="cv", usage="My Cool Version Flag."),
            action=version
        ),
    )
    cli.execute()
```

## Output Redirection

The standard output and error output behavior can be customized by providing writer functions. By default, the writer is set to `print` to stdout and stderr, but you can provide custom writer functions that satisfy the expected function signatures.

```mojo
from prism import Command, FlagSet
from sys import stderr

fn my_output_writer(arg: String):
    print(arg)

fn my_error_writer(arg: String):
    print(arg, file=stderr)

fn test(args: List[String], flags: FlagSet) -> None:
    print("Pass -v to see the version!")

fn main() -> None:
    var cli = Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        version=version,
        output_writer=my_output_writer,
        error_writer=my_error_writer,
    )
    cli.execute()
```

## Reading arguments in from stdin

Commands can additionally read arguments in from `stdin`. Set `read_from_stdin` to `True` and `stdin` will also be read and parsed for arguments. This should only be set on the root command.

```mojo
from prism import Command, FlagSet

fn test(args: List[String], flags: FlagSet) -> None:
    for arg in args:
        print("Received:", arg)

fn main() -> None:
    var cli = Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        read_from_stdin=True
    )
    cli.execute()
```

## Exiting the program

By default, `prism` will exit with a status code of `1` if any `Errors` are raised during the execution of the program. However, the exit behavior can be customized by providing an exit function to the `Command` struct. It's a bit manual with error handling now, but it will be improved in the future.

```mojo
from prism import Command, FlagSet
from sys import exit


fn test(args: List[String], flags: FlagSet) raises -> None:
    raise Error("Error: Exit Code 2")


fn my_exit(e: Error) -> None:
    if e.as_string_slice() == "Error: Exit Code 2":
        exit(2)
    else:
        exit(1)


fn main() -> None:
    var cli = Command(
        name="hello",
        usage="This is a dummy command!",
        raising_run=test,
        exit=my_exit,
    )
    cli.execute()
```

## Notes

- Flags can have values passed by using the `=` operator. Like `--count=5` OR like `--count 5`.

## TODO

Should error and output writers even be supported for commands? It seems like unneccessary complexity to have them for every command, when they can be set at the top level. Perhaps we can make it so that the top level command has a default writer, and child commands can override it if needed.

### Features

- Add support for configurable delimiter (default: `--`) to indicate the end of flags.
- Add suggestion logic for commands.
- Autocomplete generation.
- Add persistent flag mutually exclusive and required together checks back in.
- Typed arguments.
- Once the stdlib supports reading from stdin (currently only supports `readline` and `read_until_delimiter`), reading args from stdin will be updated to support newlines.

### Improvements

- Tree traversal improvements.
- Once we have trait objects, use actual typed flags instead of converting values to and from strings.
- Commands without children can be created at compile time, but those with them cannot. Perhaps I can find a way to make this work.

## Bugs

- The `CLI.help` is temporarily no longer optional due to a bug in Mojo. It should be optional in order to disable the help flag, but the optional argument in the constructor with a default value leads to an issue where the pointer to the help function is null.
