# Prism

A Budding CLI Library!

Inspired by: `Cobra` and `urfave/cli`!

![Mojo Version](https://img.shields.io/badge/Mojo%F0%9F%94%A5-25.1-orange)
![Build Status](https://github.com/thatstoasty/prism/actions/workflows/build.yml/badge.svg)
![Test Status](https://github.com/thatstoasty/prism/actions/workflows/test.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## New to Mojo?

If you haven't created a project before you can follow these steps to create your project!

1. Install Modular's CLI tool, `Magic`: <https://docs.modular.com/magic/>.
2. Run `magic init my-mojo-project --format mojoproject` to create a `Mojo` project directory.
3. Change directory into your project directory with `cd my-mojo-project`.

Now you're ready to add `prism` to your project!

**NOTE**: Keep in mind that `Mojo` is intended to run either in an activated `Magic` shell or through a `Magic` command. Personally, I like to run my code via `Magic` commands like so:

```bash
magic run mojo path/to/hello_world.mojo
```

`Magic` will ensure that `mojo` is executing using the version defined in your `mojoproject.toml` as well as any dependencies defined. I would advise against trying to set up a global `Mojo` installation until you're comfortable with the project based pattern.

## Installation

1. First, you'll need to configure your `mojoproject.toml` file to include my Conda channel. Add `"https://repo.prefix.dev/mojo-community"` to the list of channels.
2. Next, add `prism` to your project's dependencies by running `magic add prism`.
3. Finally, run `magic install` to install in `prism` and its dependencies. You should see the `.mojopkg` files in `$CONDA_PREFIX/lib/mojo/` (usually resolves to `.magic/envs/default/lib/mojo`).

## Basic Command and Subcommand

Here's an example of a basic command and subcommand!

```mojo
from memory import ArcPointer
from prism import Command, Context


fn test(ctx: Context) -> None:
    print("Pass chromeria as a subcommand!")


fn hello(ctx: Context) -> None:
    print("Hello from Chromeria!")


fn main() -> None:
    root = Command(
        name="hello",
        description="This is a dummy command!",
        run=test,
        children=List[ArcPointer[Command]](
            ArcPointer(Command(
                name="chromeria",
                description="This is a dummy command!",
                run=hello
            ))
        ),
    )

    root.execute()
```

![Chromeria](https://github.com/thatstoasty/prism/blob/main/doc/tapes/hello-chromeria.gif)

## Why are subcommands wrapped with `ArcPointer`?

Due to the nature of self-referential structs, we need to use a smart pointer to reference the subcommand. The child command is owned by the `ArcPointer`, and that pointer is then shared across the program execution.

## Accessing arguments

`prism` provides the parsed arguments as part of the `ctx` argument.

```mojo
from prism import Context

fn printer(ctx: Context) raises -> None:
    if len(ctx.args) == 0:
        raise Error("No args provided.")

    for arg in ctx.args:
        print(arg[])
```

## Command Aliases

Commands can also be aliased to enable different ways to call the same command. You can change the command underneath the alias and maintain the same behavior.

```mojo
from memory import ArcPointer
from prism import Command

fn main():
    print_tool = ArcPointer(Command(
        name="tool",
        description="This is a dummy command!",
        run=tool_func,
        aliases=List[String]("object", "thing")
    ))
```

![Aliases](https://github.com/thatstoasty/prism/blob/main/doc/tapes/aliases.gif)

## Pre and Post Run Hooks

Commands can be configured to run pre-hook and post-hook functions before and after the command's main run function.

```mojo
from prism import Command, Context

fn pre_hook(ctx: Context) -> None:
    print("Pre-hook executed!")

fn post_hook(ctx: Context) -> None:
    print("Post-hook executed!")

fn main() -> None:
    root = Command(
        name="printer",
        description="Base command.",
        run=printer,
        pre_run=pre_hook,
        post_run=post_hook,
    )
```

![Printer](https://github.com/thatstoasty/prism/blob/main/doc/tapes/printer.gif)

## Flags

Commands can have typed flags added to them to enable different behaviors.

```mojo
from memory import ArcPointer
from prism import Command, Flag
import prism

fn main() -> None:
    root = Command(
        name="logger",
        description="Base command.",
        run=handler,
        flags=List[Flag](
            prism.string_flag(
                name="type",
                shorthand="t",
                usage="Formatting type: [json, custom]",
            )
        ),
    )
```

![Logging](https://github.com/thatstoasty/prism/blob/main/doc/tapes/logging.gif)

### Default flag values from environment variables

Flag values can also be retrieved from environment variables, if a value is not provided as an argument.

```mojo
from memory import ArcPointer
from prism import Command, Flag
import prism

fn test(ctx: Context) raises -> None:
    name = ctx.command[].get_string("name")
    print("Hello {}".format(name))


fn main() -> None:
    root = Command(
        name="greet",
        usage="Greet a user!",
        raising_run=test,
        flags=List[Flag](
            prism.string_flag(
                name="name",
                shorthand="n",
                usage="The name of the person to greet.",
                environment_variable="NAME",
            )
        ),
    )

    root.execute()
```

### Default flag values from files

Likewise, flag values can also be retrieved from a file as well, if a value is not provided as an argument.

```mojo
from memory import ArcPointer
from prism import Command, Flag
import prism

fn test(ctx: Context) raises -> None:
    name = ctx.command[].get_string("name")
    print("Hello {}".format(name))

fn main() -> None:
    root = Command(
        name="greet",
        usage="Greet a user!",
        raising_run=test,
        flags=List[Flag](
            prism.string_flag(
                name="name",
                shorthand="n",
                usage="The name of the person to greet.",
                file_path="~/.myapp/config",
            )
        ),
    )

    root.execute()
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
from memory import ArcPointer
from prism import Command, Flag
import prism

fn main() -> None:
    root = Command(
        name="nested",
        description="Base command.",
        run=base,
        children=List[ArcPointer[Command]](
            ArcPointer(Command(
                name="get",
                description="Base command for getting some data.",
                run=print_information,
                persistent_pre_run=pre_hook,
                persistent_post_run=post_hook,
            ))
        ),
        flags=List[Flag](
            prism.bool_flag(
                name="lover",
                shorthand="l",
                usage="Are you an animal lover?",
                persistent=True,
            )
        ),
    )
```

![Persistent](https://github.com/thatstoasty/prism/blob/main/doc/tapes/persistent.gif)

### Required flags

Flags can be grouped together to enable relationships between them. This can be used to enable different behaviors based on the flags that are passed.

By default flags are considered optional. If you want your command to report an error when a flag has not been set, mark it as required:

```mojo
from memory import ArcPointer
from prism import Command, Flag
import prism

fn main():
    print_tool = ArcPointer(Command(
        name="tool",
        description="This is a dummy command!",
        run=tool_func,
        aliases=List[String]("object", "thing"),
        flags=List[Flag](
            prism.bool_flag(
                name="required",
                shorthand="r",
                usage="Always required.",
                required=True,
            )
        ),
    ))
```

### Flag Groups

If you have different flags that must be provided together (e.g. if they provide the `--color` flag they MUST provide the `--formatting` flag as well) then Prism can enforce that requirement:

```mojo
from memory import ArcPointer
from prism import Command, Flag
import prism

fn main();:
    print_tool = ArcPointer(Command(
        name="tool",
        description="This is a dummy command!",
        run=tool_func,
        aliases=List[String]("object", "thing"),
        flags=List[Flag](
            prism.uint32_flag(
                name="color",
                shorthand="c",
                usage="Text color",
                default=0x3464eb,
            ),
            prism.string_flag(
                name="formatting",
                shorthand="f",
                usage="Text formatting",
            ),
        ),
        flags_required_together=List[String]("color", "formatting"),
    ))
```

You can also prevent different flags from being provided together if they represent mutually exclusive options such as specifying an output format as either `--color` or `--hue` but never both:

```mojo
from memory import ArcPointer
from prism import Command, Flag
import prism

fn main():
   print_tool = ArcPointer(Command(
        name="tool",
        description="This is a dummy command!",
        run=tool_func,
        aliases=List[String]("object", "thing"),
        flags=List[Flag](
            prism.uint32_flag(
                name="color",
                shorthand="c",
                usage="Text color",
                default=0x3464eb,
            ),
            prism.uint32_flag(
                name="hue",
                shorthand="x",
                usage="Text color",
                default="#3464eb",
            ),
        ),
        mutually_exclusive_flags=List[String]("color", "hue"),
    ))
```

If you want to require at least one flag from a group to be present, you can use `mark_flags_one_required`. This can be combined with `mark_flags_mutually_exclusive` to enforce exactly one flag from a given group:

```mojo
from memory import ArcPointer
from prism import Command, Flag
import prism

fn main():
   print_tool = ArcPointer(Command(
        name="tool",
        description="This is a dummy command!",
        run=tool_func,
        aliases=List[String]("object", "thing"),
        flags=List[Flag](
            prism.uint32_flag(
                name="color",
                shorthand="c",
                usage="Text color",
                default=0x3464eb,
            ),
            prism.string_flag(
                name="formatting",
                shorthand="f",
                usage="Text formatting",
            ),
        ),
        one_required_flags=List[String]("color", "formatting"),
        mutually_exclusive_flags=List[String]("color", "formatting"),
    ))
```

In these cases:

- The group is only enforced on commands where every flag is defined.
- A flag may appear in multiple groups.
- A group may contain any number of flags.

![Flag Groups](https://github.com/thatstoasty/prism/blob/main/doc/tapes/flag_groups.gif)

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

Commands are configured to accept a `--help` and `-h` flag by default. This will print the output of a default help function. You can also configure a custom help function to be run when the `--help` flag is passed.

```mojo
from memory import ArcPointer
from prism import Command
import prism

fn help_func(mut command: ArcPointer[Command]) -> String:
    return "My help function."

fn main() -> None:
    root = Command(
        name="hello",
        description="This is a dummy command!",
        run=test,
        help=help_func
    )
```

![Help](https://github.com/thatstoasty/prism/blob/main/doc/tapes/help.gif)

### Version

Commands can be configured to accept `--version` and `-v` flag to run a version function. This will print the result of the version function using the output writer that's configured for the command.

```mojo
from memory import ArcPointer
from prism import Command, Context


fn test(ctx: Context) -> None:
    print("Pass -v to see the version!")


fn version() -> String:
    return "MyCLI version 0.1.0"


fn main() -> None:
    Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        version=version,
    ).execute()
```

## Output Redirection

The standard output and error output behavior can be customized by providing writer functions. By default, the writer is set to `print` to stdout and stderr, but you can provide custom writer functions that satisfy the expected function signatures.

```mojo
from memory import ArcPointer
from prism import Command, Context


fn my_output_writer(arg: String):
    print(arg)


fn my_error_writer(arg: String):
    print(arg, file=2)


fn test(ctx: Context) -> None:
    print("Pass -v to see the version!")


fn main() -> None:
    Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        version=version,
        output_writer=my_output_writer,
        error_writer=my_error_writer,
    ).execute()
```

## Exiting the program

By default, `prism` will exit with a status code of `1` if any `Errors` are raised during the execution of the program. However, the exit behavior can be customized by providing an exit function to the `Command` struct. It's a bit manual with error handling now, but it will be improved in the future.

```mojo
from memory import ArcPointer
from prism import Command, Context
from sys import exit


fn test(ctx: Context) raises -> None:
    raise Error("Error: Exit Code 2")


fn my_exit(e: Error) -> None:
    if String(e) == "Error: Exit Code 2":
        exit(2)
    else:
        exit(1)


fn main() -> None:
    Command(
        name="hello",
        usage="This is a dummy command!",
        raising_run=test,
        exit=my_exit,
    ).execute()
```

## Notes

- Flags can have values passed by using the `=` operator. Like `--count=5` OR like `--count 5`.

## TODO

## Features

- Add suggestion logic to `Command` struct.
- Autocomplete generation.
- Enable usage function to return the results of a usage function upon calling wrong functions or commands.
- Replace print usage with writers to enable stdout/stderr/file writing.
- Update default help command to improve available commands and flags section.
- Add support for combining shorthand flags, like so: `-abc` instead of `-a -b -c`.
- Try to avoid `Dict` and `try/except` blocks in order to support compile time command building.
- Add persistent flag mutually exclusive and required together checks back in.
- Add support for stdout/stderr writer configuration, instead of just using print.

## Improvements

- Tree traversal improvements.
- `ArcPointer[Command]` being passed to validators and command functions is marked as `mut` because the compiler complains about forming a reference to a borrowed register value. This is a temporary fix, I will try to get it back to a borrowed reference.
- For now, help functions and arg validators will need to be set after the command is constructed. This is to help reduce cyclical dependencies, but I will work on a way to set these values in the constructor as the type system matures.
- Once we have trait objects, use actual typed flags instead of converting values to and from strings.

## Bugs
