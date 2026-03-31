from std.memory import OwnedPointer
from prism.command import Command
from prism.flag import Flag, FType


comptime CompletionFn = fn (OwnedPointer[Command], String) raises -> String
"""The function to generate shell completion output. Takes the root command and shell name."""


fn _zsh_escape(s: String) -> String:
    """Escapes special characters in a string for use in ZSH completion specs.

    ZSH completion descriptions need certain characters escaped:
    - Single quotes need to be escaped as '\\''
    - Colons need backslash escaping as \\:
    - Square brackets need backslash escaping as \\[ and \\]

    Args:
        s: The string to escape.

    Returns:
        The escaped string safe for ZSH completion specs.
    """
    var result = String()
    for c in s.codepoint_slices():
        if c == "'":
            result.write("'\\''")
        elif c == ":":
            result.write("\\:")
        elif c == "[":
            result.write("\\[")
        elif c == "]":
            result.write("\\]")
        else:
            result.write(c)
    return result^


fn _zsh_flag_spec(flag: Flag) -> String:
    """Generates a ZSH completion spec for a single flag.

    Args:
        flag: The flag to generate a spec for.

    Returns:
        A ZSH _arguments spec string for the flag.
    """
    var escaped_usage = _zsh_escape(flag.usage)
    var is_bool = flag.type == FType.Bool
    var is_list = flag.type.is_list_type()

    if flag.shorthand:
        # Flag has both long and short forms
        var exclusion = String("(-", flag.shorthand, " --", flag.name, ")")
        if is_bool:
            return String(
                "'", exclusion, "'{-", flag.shorthand, ",--", flag.name, "}'[", escaped_usage, "]'"
            )
        else:
            var prefix: String
            if is_list:
                prefix = String("'*")
            else:
                prefix = String("'")
            return String(
                prefix, exclusion, "'{-", flag.shorthand, ",--", flag.name, "}'=[", escaped_usage, "]:", flag.name, ":'"
            )
    else:
        # Flag has only long form
        if is_bool:
            return String("'--", flag.name, "[", escaped_usage, "]'")
        else:
            var prefix: String
            if is_list:
                prefix = String("'*")
            else:
                prefix = String("'")
            return String(prefix, "--", flag.name, "=[", escaped_usage, "]:", flag.name, ":'")


fn _zsh_function_name(root_name: String, prefix: String) -> String:
    """Builds the ZSH function name for a command.

    Uses double-underscore as separator between command levels.
    E.g. root "myapp", prefix "" -> "_myapp"
    E.g. root "myapp", prefix "__sub" -> "_myapp__sub"

    Args:
        root_name: The root command name.
        prefix: The accumulated prefix for nested commands.

    Returns:
        The ZSH function name.
    """
    return String("_", root_name, prefix)


fn _zsh_command_function(
    cmd: Command, prefix: String, root_name: String, is_root: Bool
) raises -> String:
    """Generates a ZSH completion function for a single command.

    Args:
        cmd: The command to generate the function for.
        prefix: The accumulated prefix for nested commands (e.g. "__sub__nested").
        root_name: The root command name.
        is_root: Whether this is the root command.

    Returns:
        The ZSH function body as a string.

    Raises:
        If an error occurs during generation.
    """
    var func_name = _zsh_function_name(root_name, prefix)
    var has_children = Bool(cmd.children)
    var builder = String()

    builder.write(func_name, "() {\n")

    if has_children:
        builder.write("    local curcontext=\"$curcontext\" state line\n")
        builder.write("    typeset -A opt_args\n")
        builder.write("    _arguments -C \\\n")
    else:
        builder.write("    _arguments \\\n")

    # Collect flags for this command
    # The command's flags already include the help flag (and version flag if root).
    # For non-root commands, persistent flags from ancestors would be merged at execution time,
    # but at generation time we need to walk the tree. Since we generate from the root command tree
    # (before execution), we collect persistent flags from ancestors.
    var seen_flags = Dict[String, Bool]()
    var flag_specs = List[String]()

    # Add this command's own flags
    for flag in cmd.flags:
        if flag.name not in seen_flags:
            seen_flags[flag.name] = True
            flag_specs.append(_zsh_flag_spec(flag))

    # Add inherited persistent flags from ancestors (if not root)
    if not is_root and cmd.has_parent():
        var inherited = cmd.inherited_flags()
        for flag in inherited:
            if flag.name not in seen_flags:
                seen_flags[flag.name] = True
                flag_specs.append(_zsh_flag_spec(flag))

    for i in range(len(flag_specs)):
        builder.write("        ", flag_specs[i], " \\\n")

    if has_children:
        builder.write("        '1: :->cmd' \\\n")
        builder.write("        '*:: :->args'\n")

        # Generate case statement for subcommands
        builder.write("    case $state in\n")
        builder.write("    cmd)\n")
        builder.write("        local -a commands\n")
        builder.write("        commands=(\n")

        for i in range(len(cmd.children)):
            var escaped_child_usage = _zsh_escape(cmd.children[i][].usage)
            builder.write("            '", cmd.children[i][].name, ":", escaped_child_usage, "'\n")

        builder.write("        )\n")
        builder.write("        _describe -t commands '", cmd.name, " commands' commands\n")
        builder.write("        ;;\n")

        builder.write("    args)\n")
        builder.write("        case $line[1] in\n")

        for i in range(len(cmd.children)):
            var child_name = cmd.children[i][].name
            var child_aliases = cmd.children[i][].aliases.copy()
            var child_prefix = String(prefix, "__", child_name)
            var child_func = _zsh_function_name(root_name, child_prefix)

            # Build case pattern: name|alias1|alias2
            var pattern = child_name
            for j in range(len(child_aliases)):
                pattern.write("|", child_aliases[j])

            builder.write("        ", pattern, ") ", child_func, " ;;\n")

        builder.write("        esac\n")
        builder.write("        ;;\n")
        builder.write("    esac\n")
    else:
        # Leaf command - add valid_args completion if present
        if cmd.valid_args:
            var args_list = String()
            for i in range(len(cmd.valid_args)):
                if i > 0:
                    args_list.write(" ")
                args_list.write(cmd.valid_args[i])
            builder.write("        '1:arg:(", args_list, ")'\n")
        else:
            # Remove trailing backslash from last flag spec line if any flags were written
            pass

    builder.write("}\n")
    return builder^


fn _zsh_functions_recursive(
    cmd: Command, prefix: String, root_name: String, is_root: Bool
) raises -> String:
    """Recursively generates ZSH completion functions for a command and all its children.

    Args:
        cmd: The command to generate functions for.
        prefix: The accumulated prefix for nested commands.
        root_name: The root command name.
        is_root: Whether this is the root command.

    Returns:
        All ZSH function definitions concatenated.

    Raises:
        If an error occurs during generation.
    """
    var builder = _zsh_command_function(cmd, prefix, root_name, is_root)

    for i in range(len(cmd.children)):
        var child_name = cmd.children[i][].name
        var child_prefix = String(prefix, "__", child_name)
        builder.write("\n")
        builder.write(_zsh_functions_recursive(cmd.children[i][].copy(), child_prefix, root_name, is_root=False))

    return builder^


fn generate_zsh_completion(cmd: OwnedPointer[Command]) raises -> String:
    """Generates a complete ZSH completion script for the given command tree.

    The generated script uses ZSH's _arguments completion system and creates
    a function hierarchy matching the command tree structure. Function names
    use double-underscore separators (e.g. _myapp__sub__nested).

    Args:
        cmd: The root command to generate completions for.

    Returns:
        A complete ZSH completion script as a string.

    Raises:
        If an error occurs during generation.
    """
    var root_name = cmd[].name
    var builder = String()

    # Header
    builder.write("#compdef ", root_name, "\n")
    builder.write("# Generated by prism - https://github.com/thatstoasty/prism\n")
    builder.write("# Do not edit manually.\n\n")

    # Generate all functions recursively
    builder.write(_zsh_functions_recursive(cmd[], String(""), root_name, is_root=True))

    # Entry point: detect whether loaded by compinit (fpath) or sourced manually.
    # When compinit autoloads the file, funcstack[1] equals the function name,
    # so we call it directly in the completion context. Otherwise we register
    # the function with compdef so `source`-ing the script works too.
    builder.write(
        "\nif [ \"$funcstack[1]\" = \"_", root_name, "\" ]; then\n"
    )
    builder.write("    _", root_name, " \"$@\"\n")
    builder.write("else\n")
    builder.write("    compdef _", root_name, " ", root_name, "\n")
    builder.write("fi\n")

    return builder^


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
    else:
        raise Error(String("Unsupported shell: '", shell, "'. Supported shells: zsh"))


struct Completion(Copyable):
    """Configuration for shell completion generation.

    When set on a root `Command`, a `completion` subcommand is automatically
    added. Running `myapp completion zsh` generates a ZSH completion script
    that can be sourced or installed.

    Example usage:
    ```mojo
    from prism import Command, Completion, read_args

    fn run(args: List[String], flags: FlagSet) raises -> None:
        print("Hello!")

    fn main():
        var cli = Command(
            name="myapp",
            usage="My application",
            run=run,
            completion=Completion(),
        )
        cli.execute(read_args())
    ```

    Then generate completions:
    ```sh
    myapp completion zsh > ~/.zsh/completions/_myapp
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
