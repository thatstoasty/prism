"""Example demonstrating shell completion generation with prism.

Build and run:
    mojo build completion_example.mojo && ./completion_example completion zsh
    mojo build completion_example.mojo && ./completion_example completion bash

Install ZSH completions:
    ./completion_example completion zsh > ~/.zsh/completions/_completion_example
    # Then restart your shell or run: source ~/.zsh/completions/_completion_example

Install Bash completions:
    ./completion_example completion bash > ~/.local/share/bash-completion/completions/completion_example
    # Or source directly: source <(./completion_example completion bash)
"""
from prism import Arg, ArgSet, Command, FlagSet, Flag, read_args


def serve(args: ArgSet, flags: FlagSet) raises -> None:
    print("Starting server...")


def build(args: ArgSet, flags: FlagSet) raises -> None:
    print("Building project...")


def deploy(args: ArgSet, flags: FlagSet) raises -> None:
    print("Deploying...")


def base(args: ArgSet, flags: FlagSet) raises -> None:
    print("Use --help for usage information.")


def main():
    var cli = Command(
        name="myapp",
        usage="An example CLI with shell completions.",
        run=base,
        enable_completion=True,
        flags=[
            Flag.new[String](name="config", shorthand="c", usage="Path to config file.", persistent=True),
            Flag.new[Bool](name="verbose", shorthand="v", usage="Enable verbose output.", persistent=True),
        ],
        children=[
            Command(
                name="serve",
                usage="Start the development server.",
                run=serve,
                aliases=["s"],
                flags=[
                    Flag.new[Int](name="port", shorthand="p", usage="Port to listen on.", default=8080),
                    Flag.new[String](name="host", usage="Host to bind to.", default="localhost"),
                ],
            ),
            Command(
                name="build",
                usage="Build the project.",
                run=build,
                flags=[
                    Flag.new[Bool](name="release", shorthand="r", usage="Build in release mode."),
                    Flag.new[String](name="target", shorthand="t", usage="Build target."),
                ],
            ),
            Command(
                name="deploy",
                usage="Deploy the project.",
                run=deploy,
                args=[Arg.new[String](name="action", usage="What to do.", valid_values=["staging", "production"])],
            ),
        ],
    )
    cli.execute(read_args())
