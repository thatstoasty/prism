# Prism

A Budding CLI Library!

Inspired by: `Cobra`!

![Mojo Version](https://img.shields.io/badge/Mojo%F0%9F%94%A5-24.5-orange)
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
from memory import Arc
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
    )

    hello_command = Arc(Command(name="chromeria", description="This is a dummy command!", run=hello))

    root.add_subcommand(hello_command)
    root.execute()
```

![Chromeria](https://github.com/thatstoasty/prism/blob/main/doc/tapes/hello-chromeria.gif)

## Why are subcommands wrapped with `Arc`?

Due to the nature of self-referential structs, we need to use a smart pointer to reference the subcommand. The child command is owned by the `Arc` pointer, and that pointer is then shared across the program execution.

This will be changed to `Box` in the upcoming release.

## Accessing arguments

`prism` provides the parsed arguments as part of the `ctx` argument.

```mojo
fn printer(ctx: Context) raises -> None:
    if len(ctx.args) == 0:
        raise Error("No args provided.")

    for arg in ctx.args:
        print(arg[])
```

## Command Aliases

Commands can also be aliased to enable different ways to call the same command. You can change the command underneath the alias and maintain the same behavior.

```mojo
print_tool = Arc(Command(
        name="tool", description="This is a dummy command!", run=tool_func, aliases=List[String]("object", "thing")
    ))
```

![Aliases](https://github.com/thatstoasty/prism/blob/main/doc/tapes/aliases.gif)

## Pre and Post Run Hooks

Commands can be configured to run pre-hook and post-hook functions before and after the command's main run function.

```mojo
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
fn main() -> None:
    root = Command(
        name="logger", description="Base command.", run=handler
    )
    root.flags.string_flag(name="type", shorthand="t", usage="Formatting type: [json, custom]")
```

![Logging](https://github.com/thatstoasty/prism/blob/main/doc/tapes/logging.gif)

### Default flag values from environment variables

Flag values can also be retrieved from environment variables, if a value is not provided as an argument.

```mojo
fn test(ctx: Context) raises -> None:
    name = ctx.command[].flags.get_string("name")
    print(String("Hello {}").format(name))


fn main() -> None:
    root = Command(
        name="greet",
        usage="Greet a user!",
        raising_run=test,
    )

    root.flags.string_flag(
        name="name",
        shorthand="n",
        usage="The name of the person to greet.",
        environment_variable="NAME",
    )

    root.execute()
```

### Default flag values from files

Likewise, flag values can also be retrieved from a file as well, if a value is not provided as an argument.

```mojo
fn test(ctx: Context) raises -> None:
    name = ctx.command[].flags.get_string("name")
    print(String("Hello {}").format(name))


fn main() -> None:
    root = Command(
        name="greet",
        usage="Greet a user!",
        raising_run=test,
    )

    root.flags.string_flag(
        name="name",
        shorthand="n",
        usage="The name of the person to greet.",
        file_path="$HOME/.myapp/config",
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
fn main() -> None:
    root = Command(name="nested", description="Base command.", run=base)

    get_command = Arc(Command(
        name="get",
        description="Base command for getting some data.",
        run=print_information,
        persistent_pre_run=pre_hook,
        persistent_post_run=post_hook,
    ))
    get_command[].flags.persistent_flags.bool_flag(name="lover", shorthand="l", usage="Are you an animal lover?")
```

![Persistent](https://github.com/thatstoasty/prism/blob/main/doc/tapes/persistent.gif)

### Required flags

Flags can be grouped together to enable relationships between them. This can be used to enable different behaviors based on the flags that are passed.

By default flags are considered optional. If you want your command to report an error when a flag has not been set, mark it as required:

```mojo
print_tool = Arc(Command(
        name="tool", description="This is a dummy command!", run=tool_func, aliases=List[String]("object", "thing")
    ))
    print_tool[].flags.bool_flag(name="required", shorthand="r", usage="Always required.")
    print_tool[].mark_flag_required("required")
```

Same for persistent flags:

```mojo
    root = Command(
        name="my",
        description="This is a dummy command!",
        run=test,
    )
    root.persistent_flags.bool_flag(name="free", shorthand="f", usage="Always required.")
    root.mark_persistent_flag_required("free")
```

### Flag Groups

If you have different flags that must be provided together (e.g. if they provide the `--color` flag they MUST provide the `--formatting` flag as well) then Prism can enforce that requirement:

```mojo
    print_tool = Arc(Command(
        name="tool", description="This is a dummy command!", run=tool_func, aliases=List[String]("object", "thing")
    ))
    print_tool[].flags.uint32_flag(name="color", shorthand="c", usage="Text color", default=0x3464eb)
    print_tool[].flags.string_flag(name="formatting", shorthand="f", usage="Text formatting")
    print_tool[].mark_flags_required_together("color", "formatting")
```

You can also prevent different flags from being provided together if they represent mutually exclusive options such as specifying an output format as either `--color` or `--hue` but never both:

```mojo
   print_tool = Arc(Command(
        name="tool", description="This is a dummy command!", run=tool_func, aliases=List[String]("object", "thing")
    ))
    print_tool[].string_flag(name="color", shorthand="c", usage="Text color", default="#3464eb")
    print_tool[].string_flag(name="hue", shorthand="x", usage="Text color", default="#3464eb")
    print_tool[].mark_flags_mutually_exclusive("color", "hue")
```

If you want to require at least one flag from a group to be present, you can use `mark_flags_one_required`. This can be combined with `mark_flags_mutually_exclusive` to enforce exactly one flag from a given group:

```mojo
   print_tool = Arc(Command(
        name="tool", description="This is a dummy command!", run=tool_func, aliases=List[String]("object", "thing")
    ))
    print_tool[].flags.string_flag(name="color", shorthand="c", usage="Text color", default="#3464eb")
    print_tool[].flags.string_flag(name="formatting", shorthand="f", usage="Text formatting")
    print_tool[].mark_flags_one_required("color", "formatting")
    print_tool[].mark_flags_mutually_exclusive("color", "formatting")
```

In these cases:

- Both local and persistent flags can be used.
  - NOTE: the group is only enforced on commands where every flag is defined.
- A flag may appear in multiple groups.
- A group may contain any number of flags.

![Flag Groups](https://github.com/thatstoasty/prism/blob/main/doc/tapes/flag_groups.gif)

> NOTE: If you want to enforce a rule on persistent flags, then the child command must be added to the parent command **BEFORE** setting the rule.

See `examples/flag_groups/child.mojo` for an example.

```mojo
fn main() -> None:
    root = Command(
        name="my",
        description="This is a dummy command!",
        run=test,
    )
    # Persistent flags are defined on the parent command.
    root.persistent_flags.bool_flag(name="required", shorthand="r", usage="Always required.")
    root.persistent_flags.string_flag(name="host", shorthand="h", usage="Host")
    root.persistent_flags.string_flag(name="port", shorthand="p", usage="Port")
    root.mark_persistent_flag_required("required")

    print_tool = Arc(Command(
        name="tool", description="This is a dummy command!", run=tool_func
    ))
    print_tool[].flags.bool_flag(name="also", shorthand="a", usage="Also always required.")
    print_tool[].flags.string_flag(name="uri", shorthand="u", usage="URI")

    # Child commands are added to the parent command.
    root.add_subcommand(print_tool)

    # Rules are set on the child command, which can include persistent flags inherited from the parent command.
    # When executing `mark_flags_required_together()` or `mark_flags_mutually_exclusive()`,
    # the inherited flags from all parents will merged into the print_tool[].flags FlagSet.
    print_tool[].mark_flag_required("also")
    print_tool[].mark_flags_required_together("host", "port")
    print_tool[].mark_flags_mutually_exclusive("host", "uri")

    root.execute()
```

![Flag Groups 2](https://github.com/thatstoasty/prism/blob/main/doc/tapes/flag_groups-2.gif)

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

If `arg_validator` is undefined, it defaults to `arbitrary_args`.

Moreover, `match_all[arg_validators: List[ArgValidator]]` enables combining existing checks with arbitrary other checks. For instance, if you want to report an error if there are not exactly N positional args OR if there are any positional args that are not in the ValidArgs field of Command, you can call `match_all` on `exact_args` and `valid_args`, as shown below:

```mojo
fn test_match_all():
    result = match_all[
        List[ArgValidator](
            range_args[0, 1](),
            valid_args()
        )
    ]()(List[String]("abc", "123"))
    testing.assert_equal(result.value()[], "Command accepts between 0 to 1 argument(s). Received: 2.")
```

![Arg Validators](https://github.com/thatstoasty/prism/blob/main/doc/tapes/arg_validators.gif)

## Help Commands

Commands are configured to accept a `--help` flag by default. This will print the output of a default help function. You can also configure a custom help function to be run when the `--help` flag is passed.

```mojo
fn help_func(inout command: Arc[Command]) -> String:
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

## Notes

- Flags can have values passed by using the `=` operator. Like `--count=5` OR like `--count 5`.

## TODO

## Features

- Add suggestion logic to `Command` struct.
- Autocomplete generation.
- Enable usage function to return the results of a usage function upon calling wrong functions or commands.
- Replace print usage with writers to enable stdout/stderr/file writing.
- Update default help command to improve available commands and flags section.

## Improvements

- Tree traversal improvements.
- `Arc[Command]` being passed to validators and command functions is marked as inout because the compiler complains about forming a reference to a borrowed register value. This is a temporary fix, I will try to get it back to a borrowed reference.
- For now, help functions and arg validators will need to be set after the command is constructed. This is to help reduce cyclical dependencies, but I will work on a way to set these values in the constructor as the type system matures.

## Bugs
