# Prism

A Budding CLI Library!

Prism is a Mojo library designed to help you build command-line interfaces (CLI) with ease. It provides a simple and intuitive way to define commands, subcommands, flags, and hooks, making it easier to create powerful CLI applications. This is primarily a pet project of mine, so expect it to be a bit rough around the edges. I plan to add more features and polish it up as I go along!

Inspired by: `Cobra` and `urfave/cli`!

![Mojo Version](https://img.shields.io/badge/Mojo%F0%9F%94%A5-1.0.0-orange)
![Build Status](https://github.com/thatstoasty/prism/actions/workflows/build.yml/badge.svg)
![Test Status](https://github.com/thatstoasty/prism/actions/workflows/test.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Adding the `prism` package to your project

First, you'll need to enable the `pixi-build` preview by adding this to the `workspace` section of your `pixi.toml` file.

```bash
preview = ["pixi-build"]
```

### Building it from source

There's two ways to build `prism` from source: directly from the Git repository or by cloning the repository locally.

#### Building from source: Git

Run the following commands in your terminal:

```bash
pixi add prism --git "https://github.com/thatstoasty/prism.git" --tag "v0.4.0" && pixi install
```

#### Building from source: Local

```bash
# Clone the repository to your local machine
git clone https://github.com/thatstoasty/prism.git

# Add the package to your project from the local path
pixi add -s ./path/to/prism && pixi install
```

## Basic Command and Subcommand

Here's an example of a basic command and subcommand!

```mojo
from prism import ArgSet, Command, FlagSet, read_args

def test(args: ArgSet, flags: FlagSet) -> None:
    print("Pass chromeria as a subcommand!")

def hello(args: ArgSet, flags: FlagSet) -> None:
    print("Hello from Chromeria!")

def main() -> None:
    var cli = Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        children=[
            Command(
                name="chromeria",
                usage="This is a dummy command!",
                run=hello
            )
        ],
    )
    cli.execute(read_args())
```

![Chromeria](https://github.com/thatstoasty/prism/blob/main/doc/tapes/hello-chromeria.gif)

## Why are subcommands wrapped with `ArcPointer`?

Due to the nature of self-referential structs, we need to use a smart pointer to reference the subcommand. The child command is owned by the `ArcPointer`, and that pointer is then shared across the program execution.

## Accessing arguments

`prism` provides the parsed cli arguments as command function arguments.

```mojo
from prism import ArgSet, Command, FlagSet, read_args

def printer(args: ArgSet, flags: FlagSet) raises -> None:
    if len(args) == 0:
        raise Error("No args provided.")

    for arg in args:
        print(arg)

def main() -> None:
    var cli = Command(name="printer", usage="Print the args.", run=printer)
    cli.execute(read_args())
```

## Command Aliases

Commands can also be aliased to enable different ways to call the same command. You can change the command underneath the alias and maintain the same behavior.

```mojo
from prism import ArgSet, Command, FlagSet, read_args

def tool_func(args: ArgSet, flags: FlagSet) -> None:
    print("Running tool!")

def main():
    var cli = Command(
        name="tool",
        usage="This is a dummy command!",
        run=tool_func,
        aliases=["object", "thing"]
    )
    cli.execute(read_args())
```

![Aliases](https://github.com/thatstoasty/prism/blob/main/doc/tapes/aliases.gif)

## Pre and Post Run Hooks

Commands can be configured to run pre-hook and post-hook functions before and after the command's main run function.

Hook functions must be declared `raises`, even when they never raise. Unlike `run`, hooks are held
as `Optional`, and a non-raising function does not convert that far implicitly. Leaving `raises` off
reports a mismatch against the whole `Command` constructor rather than naming the hook, so it is
worth checking first if a hook will not compile.

```mojo
from prism import ArgSet, Command, FlagSet, read_args

def pre_hook(args: ArgSet, flags: FlagSet) raises -> None:
    print("Pre-hook executed!")

def post_hook(args: ArgSet, flags: FlagSet) raises -> None:
    print("Post-hook executed!")

def printer(args: ArgSet, flags: FlagSet) -> None:
    for arg in args:
        print(arg)

def main() -> None:
    var cli = Command(
        name="printer",
        usage="Base command.",
        run=printer,
        pre_run=pre_hook,
        post_run=post_hook,
    )
    cli.execute(read_args())
```

![Printer](https://github.com/thatstoasty/prism/blob/main/doc/tapes/printer.gif)

## Flags

Commands can have typed flags added to them to enable different behaviors.

```mojo
from prism import ArgSet, Command, Flag, FlagSet, read_args

def handler(args: ArgSet, flags: FlagSet) raises -> None:
    print("Formatting type:", flags.get[String]("type").or_else("none"))

def main() -> None:
    var cli = Command(
        name="logger",
        usage="Base command.",
        run=handler,
        flags=[
            Flag.new[String](
                name="type",
                shorthand="t",
                usage="Formatting type: [json, custom]",
            )
        ],
    )
    cli.execute(read_args())
```

![Logging](https://github.com/thatstoasty/prism/blob/main/doc/tapes/logging.gif)

### Default flag values from environment variables

Flag values can also be retrieved from environment variables, if a value is not provided as an argument.

```mojo
from prism import ArgSet, Command, Flag, FlagSet, read_args

def test(args: ArgSet, flags: FlagSet) raises -> None:
    if name := flags.get[String]("name"):
        print("Hello ", name[])

def main() -> None:
    var cli = Command(
        name="greet",
        usage="Greet a user!",
        run=test,
        flags=[
            Flag.new[String](
                name="name",
                shorthand="n",
                usage="The name of the person to greet.",
                environment_variable="NAME",
            )
        ],
    )
    cli.execute(read_args())
```

### Default flag values from files

Likewise, flag values can also be retrieved from a file as well, if a value is not provided as an argument.

```mojo
from prism import ArgSet, Command, Flag, FlagSet, read_args
import prism

def test(args: ArgSet, flags: FlagSet) raises -> None:
    if name := flags.get[String]("name"):
        print("Hello ", name[])

def main() -> None:
    var cli = Command(
        name="greet",
        usage="Greet a user!",
        run=test,
        flags=[
            Flag.new[String](
                name="name",
                shorthand="n",
                usage="The name of the person to greet.",
                file_path="~/.myapp/config",
            )
        ],
    )
    cli.execute(read_args())
```

### Reading flag values

Flag values are read with `get[T]`, naming the type you expect. It returns `None` when no flag of
that name is defined, or when the flag has neither a value nor a default.

```mojo
from prism import ArgSet, Command, FlagSet, Flag, read_args

def handler(args: ArgSet, flags: FlagSet) raises -> None:
    var region = flags.get[String]("region")
    var port = flags.get[Int]("port")
    var tags = flags.get[List[String]]("tags")
    print("region:", region.or_else(String("none")), "port:", port.or_else(0))

def main() -> None:
    var cli = Command(
        name="deploy",
        usage="Deploy the app.",
        run=handler,
        flags=[
            Flag.new[String](name="region", usage="Target region."),
            Flag.new[Int](name="port", usage="Port to bind."),
            Flag.new[List[String]](name="tags", usage="Tags to apply."),
        ],
    )
    cli.execute(read_args())
```

`get[T]` matches on the flag's name alone, and raises if the value cannot be read as a `T`. Asking
for `get[Int]("region")` on a string flag reports that the value is not a number rather than quietly
yielding nothing.

`T` can be any type conforming to `FromValue`, so a type of your own works too:

```mojo
from prism import FromValue

@fieldwise_init
struct Port(FromValue, Copyable, Movable):
    var value: UInt16

    @staticmethod
    def from_value(value: StringSpan) raises -> Self:
        var parsed = atol(value)
        if parsed < 1 or parsed > 65535:
            raise Error(t"Port out of range: {parsed}")
        return Self(UInt16(parsed))

def main() -> None:
    print("Implement FromValue to read a flag as your own type.")
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
from prism import ArgSet, Command, Flag, FlagSet, read_args

def base(args: ArgSet, flags: FlagSet) -> None:
    print("Base command.")

def print_information(args: ArgSet, flags: FlagSet) raises -> None:
    print("Animal lover:", flags.get[Bool]("lover").or_else(False))

def pre_hook(args: ArgSet, flags: FlagSet) raises -> None:
    print("Pre-hook executed!")

def post_hook(args: ArgSet, flags: FlagSet) raises -> None:
    print("Post-hook executed!")

def main() -> None:
    var cli = Command(
        name="nested",
        usage="Base command.",
        run=base,
        children=[
            Command(
                name="get",
                usage="Base command for getting some data.",
                run=print_information,
                persistent_pre_run=pre_hook,
                persistent_post_run=post_hook,
            )
        ],
        flags=[
            Flag.new[Bool](
                name="lover",
                shorthand="l",
                usage="Are you an animal lover?",
                persistent=True,
            )
        ],
    )
    cli.execute(read_args())
```

![Persistent](https://github.com/thatstoasty/prism/blob/main/doc/tapes/persistent.gif)

### Required flags

Flags can be grouped together to enable relationships between them. This can be used to enable different behaviors based on the flags that are passed.

By default flags are considered optional. If you want your command to report an error when a flag has not been set, mark it as required:

```mojo
from prism import ArgSet, Command, Flag, FlagSet, read_args

def tool_func(args: ArgSet, flags: FlagSet) -> None:
    print("Running tool!")

def main():
    var cli = Command(
        name="tool",
        usage="This is a dummy command!",
        run=tool_func,
        aliases=["object", "thing"],
        flags=[
            Flag.new[Bool](
                name="required",
                shorthand="r",
                usage="Always required.",
                required=True,
            )
        ],
    )
    cli.execute(read_args())
```

### Flag Groups

If you have different flags that must be provided together (e.g. if they provide the `--color` flag they MUST provide the `--formatting` flag as well) then Prism can enforce that requirement:

```mojo
from prism import ArgSet, Command, Flag, FlagSet, read_args

def tool_func(args: ArgSet, flags: FlagSet) -> None:
    print("Running tool!")

def main():
    var cli = Command(
        name="tool",
        usage="This is a dummy command!",
        run=tool_func,
        aliases=["object", "thing"],
        flags=[
            Flag.new[UInt32](
                name="color",
                shorthand="c",
                usage="Text color",
                default=UInt32(0x3464eb),
            ),
            Flag.new[String](
                name="formatting",
                shorthand="f",
                usage="Text formatting",
            ),
        ],
        flags_required_together=["color", "formatting"],
    )
    cli.execute(read_args())
```

You can also prevent different flags from being provided together if they represent mutually exclusive options such as specifying an output format as either `--color` or `--hue` but never both:

```mojo
from prism import ArgSet, Command, Flag, FlagSet, read_args

def tool_func(args: ArgSet, flags: FlagSet) -> None:
    print("Running tool!")

def main():
    var cli = Command(
        name="tool",
        usage="This is a dummy command!",
        run=tool_func,
        aliases=["object", "thing"],
        flags=[
            Flag.new[UInt32](
                name="color",
                shorthand="c",
                usage="Text color",
                default=UInt32(0x3464eb),
            ),
            Flag.new[UInt32](
                name="hue",
                shorthand="x",
                usage="Text color",
                default=UInt32(0x3464eb),
            ),
        ],
        mutually_exclusive_flags=["color", "hue"],
    )
    cli.execute(read_args())
```

If you want to require at least one flag from a group to be present, you can use `mark_flags_one_required`. This can be combined with `mark_flags_mutually_exclusive` to enforce exactly one flag from a given group:

```mojo
from prism import ArgSet, Command, Flag, FlagSet, read_args

def tool_func(args: ArgSet, flags: FlagSet) -> None:
    print("Running tool!")

def main():
    var cli = Command(
        name="tool",
        usage="This is a dummy command!",
        run=tool_func,
        aliases=["object", "thing"],
        flags=[
            Flag.new[UInt32](
                name="color",
                shorthand="c",
                usage="Text color",
                default=UInt32(0x3464eb),
            ),
            Flag.new[String](
                name="formatting",
                shorthand="f",
                usage="Text formatting",
            ),
        ],
        one_required_flags=["color", "formatting"],
        mutually_exclusive_flags=["color", "formatting"],
    )
    cli.execute(read_args())
```

In these cases:

- The group is only enforced on commands where every flag is defined.
- A flag may appear in multiple groups.
- A group may contain any number of flags.

![Flag Groups](https://github.com/thatstoasty/prism/blob/main/doc/tapes/flag_groups.gif)

### Suggesting alternative flags

If a flag is not provided, you can suggest an alternative flag to the user. This can be useful for providing hints to the user about what they may have meant to type.

```mojo
from prism import ArgSet, Command, Flag, FlagSet, read_args

def tool_func(args: ArgSet, flags: FlagSet) -> None:
    print("Running tool!")

def main():
    var cli = Command(
        name="tool",
        usage="This is a dummy command!",
        run=tool_func,
        aliases=["object", "thing"],
        flags=[
            Flag.new[String](
                name="color",
                shorthand="c",
                usage="Text color",
                default=String("#3464eb"),
            ),
            Flag.new[String](
                name="formatting",
                shorthand="f",
                usage="Text formatting",
            ),
        ],
        suggest=True,
    )
    cli.execute(read_args())
```

If you run the command with an invalid flag, it will suggest the closest match to the flag you provided.

```bash
mojo cli.mojo --volor
```

will suggest:

```txt
Unknown flag: volor
Did you mean: --color?

Run 'tool --help' for usage.
```

A suggestion is only offered when a flag is a close enough match. Against a command whose flags
share nothing with what was typed, `prism` reports the unknown flag without guessing at a
correction.

### Unknown subcommands

A command that has subcommands dispatches to them, so a leftover positional argument is a mistyped
subcommand rather than data. `prism` reports it instead of silently running the parent command:

```mojo
from prism import ArgSet, Command, FlagSet, read_args

def tool_func(args: ArgSet, flags: FlagSet) -> None:
    print("Running tool!")

def status(args: ArgSet, flags: FlagSet) -> None:
    print("Status!")

def main() -> None:
    var cli = Command(
        name="tool",
        usage="This is a dummy command!",
        run=tool_func,
        suggest=True,
        children=[Command(name="status", usage="Show status.", run=status)],
    )
    cli.execute(read_args())
```

```bash
mojo cli.mojo sttaus
```

```txt
Unknown command: "sttaus" for "tool".

Did you mean this?
	status

Run 'tool --help' for usage.
```

The `suggest` field covers subcommands as well as flags. With `suggest=False` the unknown command
is still reported, just without the correction. Either way the command exits non-zero.

If a parent command genuinely takes positional arguments of its own, set
`reject_unknown_subcommands=False` to opt out and have the arguments passed through to it:

```mojo
from prism import ArgSet, Command, FlagSet, read_args

def tool_func(args: ArgSet, flags: FlagSet) -> None:
    print("Running tool with:", args)

def status(args: ArgSet, flags: FlagSet) -> None:
    print("Status!")

def main() -> None:
    var cli = Command(
        name="tool",
        usage="This is a dummy command!",
        run=tool_func,
        reject_unknown_subcommands=False,
        children=[Command(name="status", usage="Show status.", run=status)],
    )
    cli.execute(read_args())
```

The `completion` subcommand that `enable_completion=True` generates does not count as a subcommand
for this purpose, so turning on shell completion will not start rejecting a command's arguments.

## Named Arguments

A command can declare the positional arguments it accepts. Declared arguments are bound by position
in the order they appear, then read back by name:

```mojo
from prism import Command, Arg, ArgSet, FlagSet, read_args

def deploy(args: ArgSet, flags: FlagSet) raises -> None:
    var target = args.get[String]("target").value()
    var replicas = args.get[Int]("replicas").value()
    print("deploying", replicas, "replicas to", target)

def main() -> None:
    var cli = Command(
        name="deploy",
        usage="Deploy the app.",
        run=deploy,
        args=[
            Arg.new[String](name="target", usage="Where to deploy."),
            Arg.new[Int](name="replicas", usage="How many replicas."),
            Arg.new[Float64](name="ratio", usage="Traffic ratio.", default=Optional[Float64](1.0)),
        ],
    )
    cli.execute(read_args())
```

Declaring arguments buys three things. Their count and types are checked before `run` is called, so
a bad argument is reported rather than surfacing partway through the command:

```txt
deploy: Invalid value for argument `replicas`: String is not convertible to integer with base 10: 'many'

Run 'deploy --help' for usage.
```

They name themselves in the usage line and get their own help section, with optional ones bracketed:

```txt
Usage: deploy [OPTIONS] TARGET REPLICAS [RATIO]

Deploy the app.

Arguments:
  TARGET      Where to deploy.
  REPLICAS    How many replicas.
  [RATIO]     Traffic ratio. (default: 1.0)
```

And they are read by name and type rather than by index, so `args.get[Int]("replicas")` replaces
`atol(args[1])`.

An argument can also name the values it accepts, which are enforced at bind time and offered as
shell completion candidates:

```mojo
from prism import Command, Arg, ArgSet, FlagSet, read_args

def deploy(args: ArgSet, flags: FlagSet) raises -> None:
    print("deploying to", args.get[String]("env").value())

def main() -> None:
    var cli = Command(
        name="deploy",
        usage="Deploy the app.",
        run=deploy,
        args=[Arg.new[String](name="env", usage="Environment.", valid_values=["staging", "production"])],
    )
    cli.execute(read_args())
```

```txt
deploy: Invalid value for argument `env`: `dev`. Valid values are: staging, production.

Run 'deploy --help' for usage.
```

An argument is required unless it is given a `default`. `ArgSet` still exposes the raw values, so
`len(args)`, `args[0]` and iteration all work as before, and a command that declares no arguments
accepts any number of them — which is what leaves `arg_validator` in charge for commands that do
their own checking.

## Positional and Custom Arguments

Validation of positional arguments can be specified using the `arg_validator` field of `Command`. The following validators are built in:

- Number of arguments:
  - `no_args` - report an error if there are any positional args.
  - `arbitrary_args` - accept any number of args.
  - `minimum_n_args[Int]` - report an error if less than N positional args are provided.
  - `maximum_n_args[Int]` - report an error if more than N positional args are provided.
  - `exact_args[Int]` - report an error if there are not exactly N positional args.
  - `range_args[min, max]` - report an error if the number of args is not between min and max.
- Composition of validators:
  - `match_all` - pass a list of validators to ensure all of them pass.

If `arg_validator` is undefined, it defaults to `arbitrary_args`.

Validators check the *number* of arguments. To constrain what an argument may contain, declare it
and give it `valid_values`, as described under [Named Arguments](#named-arguments) -- the constraint
then belongs to the argument it constrains, and shows up in help and shell completion.

![Arg Validators](https://github.com/thatstoasty/prism/blob/main/doc/tapes/arg_validators.gif)

## Common Flags

### Help

Commands are configured to accept a `--help` and `-h` flag by default. This will print the output of a default help function. You can also configure a custom help function to be run when the `--help` flag is passed. You can use the `help` argument of the `Command` constructor to configure the help function, and the help flag itself.

```mojo
from prism import ArgSet, Command, FlagSet, Flag, Help, HelpContext, read_args

def test(args: ArgSet, flags: FlagSet) -> None:
    print("Hello from Chromeria!")

def help_func(cmd: HelpContext) raises -> String:
    return "My help function."

def main() -> None:
    var cli = Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        help=Help(
            flag=Flag.new[Bool](name="custom-help", shorthand="ch", usage="My Cool Help Flag."),
            action=help_func,
        ),
    )
    cli.execute(read_args())
```

![Help](https://github.com/thatstoasty/prism/blob/main/doc/tapes/help.gif)

### Version

Commands can be configured to accept `--version` and `-v` flag to run a version function. This will print the result of the version function using the output writer that's configured for the command. You can also configure the flag and function to run when the version flag is passed by using the `version` argument of the `Command` constructor.

By default the version is reported as `<command> version <version>`:

```bash
mojo cli.mojo --version
```

```txt
hello version 0.1.0
```

A version function receives the command's full name alongside the version, so a subcommand carrying
its own `Version` can name itself:

```text
VersionFn = def (String, String) thin -> String
```

The name is the command's full path, so `--version` on a subcommand of `hello` is passed
`"hello sub"`. A version function that only wants the version can ignore the first argument.

```mojo
from prism import ArgSet, Command, FlagSet, Version, Flag, read_args

def test(args: ArgSet, flags: FlagSet) -> None:
    print("Pass -v to see the version!")

def version(name: String, version: String) -> String:
    return "MyCLI version: " + version

def main() -> None:
    var cli = Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        version=Version(
            "0.1.0",
            flag=Flag.new[Bool](name="custom-version", shorthand="cv", usage="My Cool Version Flag."),
            action=version
        ),
    )
    cli.execute(read_args())
```

## Output Redirection

The standard output and error output behavior can be customized by providing writer functions. By default, the writer is set to `print` to stdout and stderr, but you can provide custom writer functions that satisfy the expected function signatures.

```mojo
from prism import ArgSet, Command, FlagSet, Version, read_args
from std.sys import stderr

def my_output_writer(arg: String):
    print(arg)

def my_error_writer(arg: String):
    print(arg, file=stderr)

def test(args: ArgSet, flags: FlagSet) -> None:
    print("Pass -v to see the version!")

def main() -> None:
    var cli = Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        version=Version("0.1.0"),
        output_writer=my_output_writer,
        error_writer=my_error_writer,
    )
    cli.execute(read_args())
```

## Reading arguments in from stdin

Commands can additionally read arguments in from `stdin`. Pass the result of `read_args_from_stdin`
to `execute` instead of `read_args`. This should only be done on the root command.

```mojo
from prism import ArgSet, Command, FlagSet, read_args_from_stdin

def test(args: ArgSet, flags: FlagSet) -> None:
    for arg in args:
        print("Received:", arg)

def main() raises -> None:
    var cli = Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
    )
    cli.execute(read_args_from_stdin())
```

## Exiting the program

By default, `prism` will exit with a status code of `1` if any `Errors` are raised during the execution of the program. However, the exit behavior can be customized by providing an exit function to the `Command` struct. It's a bit manual with error handling now, but it will be improved in the future.

```mojo
from prism import ArgSet, Command, FlagSet, read_args
from std.sys import exit


def test(args: ArgSet, flags: FlagSet) raises -> None:
    raise Error("Error: Exit Code 2")


def my_exit(e: Error) -> None:
    if String(e) == "Error: Exit Code 2":
        exit(2)
    else:
        exit(1)


def main() -> None:
    var cli = Command(
        name="hello",
        usage="This is a dummy command!",
        run=test,
        exit=my_exit,
    )
    cli.execute(read_args())
```

## Notes

- Flags can have values passed by using the `=` operator. Like `--count=5` OR like `--count 5`.

## TODO

Should error and output writers even be supported for commands? It seems like unneccessary complexity to have them for every command, when they can be set at the top level. Perhaps we can make it so that the top level command has a default writer, and child commands can override it if needed.

### Features

- Add support for configurable delimiter (default: `--`) to indicate the end of flags.
- Add persistent flag mutually exclusive and required together checks back in. Right now, the subcommands are created before
the parent command, so they can't inherit the persistent flags at construction.
- Typed arguments.
- Once the stdlib supports reading from stdin (currently only supports `readline` and `read_until_delimiter`), reading args from stdin will be updated to support newlines.

### Improvements

- Tree traversal improvements.
- Once we have trait objects, use actual typed flags instead of converting values to and from strings.
- Commands without children can be created at compile time, but those with them cannot. Perhaps I can find a way to make this work.

## Bugs

- The `CLI.help` is temporarily no longer optional due to a bug in Mojo. It should be optional in order to disable the help flag, but the optional argument in the constructor with a default value leads to an issue where the pointer to the help function is null.
