from std.memory import OwnedPointer
from prism.command import Command
from prism.flag import Flag


comptime CompletionFn = fn (OwnedPointer[Command], String) raises -> String
"""The function to generate shell completion output. Takes the root command and shell name."""


fn default_completion(cmd: OwnedPointer[Command], shell: String) raises -> String:
    """Default completion generator that dispatches to shell-specific generators.

    Args:
        cmd: The root command to generate completions for.
        shell: The shell to generate completions for (e.g. "zsh").

    Returns:
        The completion script for the given shell.

    Raises:
        If the shell is not supported.
    """
    if shell == "zsh":
        return generate_zsh_completion(cmd)
    elif shell == "bash":
        return generate_bash_completion(cmd)
    else:
        raise Error(t"Unsupported shell: '{shell}'. Supported shells: zsh, bash")


struct Completion(ImplicitlyCopyable):
    """Configuration for shell completion generation.

    When set on a root `Command`, a `completion` subcommand is automatically
    added. Running `myapp completion zsh` generates a ZSH completion script
    that can be sourced or installed.

    Example usage:
    ```mojo
    from prism import Command, read_args, FlagSet

    fn run(args: List[String], flags: FlagSet) raises -> None:
        print("Hello!")

    fn main():
        var cli = Command(
            name="myapp",
            usage="My application",
            run=run,
        )
        cli.execute(read_args())
    ```

    Then generate completions:
    ```sh
    myapp completion zsh > ~/.zsh/completions/_myapp
    myapp completion bash > ~/.local/share/bash-completion/completions/myapp
    ```
    """

    var action: CompletionFn
    """The function to generate completion output for a given shell."""

    fn __init__(out self, *, action: CompletionFn = default_completion):
        """Constructs a new `Completion` configuration.

        Args:
            action: The function to generate completion output. Defaults to the built-in generator.
        """
        self.action = action
