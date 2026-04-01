from std.memory import OwnedPointer
from prism.command import Command
from prism.flag import Flag, FType
from prism.completion.shared import SMALL_BUFFER_SIZE, DEFAULT_BUFFER_SIZE, SCRIPT_HEADER


fn _zsh_escape(s: StringSlice, mut writer: Some[Writer]):
    """Escapes special characters in a string for use in ZSH completion specs.

    ZSH completion descriptions need certain characters escaped:
    - Single quotes need to be escaped as '\\''
    - Colons need backslash escaping as \\:
    - Square brackets need backslash escaping as \\[ and \\]

    Args:
        s: The string to escape.
        writer: A Writer to write the escaped string to.
    """
    comptime QUOTE = Codepoint.ord("'")
    comptime ESCAPED_QUOTE = "'\\''"
    comptime COLON = Codepoint.ord(":")
    comptime ESCAPED_COLON = "\\:"
    comptime LEFT_BRACKET = Codepoint.ord("[")
    comptime ESCAPED_LEFT_BRACKET = "\\["
    comptime RIGHT_BRACKET = Codepoint.ord("]")
    comptime ESCAPED_RIGHT_BRACKET = "\\]"
    for c in s.codepoints():
        if c == QUOTE:
            writer.write(ESCAPED_QUOTE)
        elif c == COLON:
            writer.write(ESCAPED_COLON)
        elif c == LEFT_BRACKET:
            writer.write(ESCAPED_LEFT_BRACKET)
        elif c == RIGHT_BRACKET:
            writer.write(ESCAPED_RIGHT_BRACKET)
        else:
            writer.write(c)


fn _zsh_flag_spec(flag: Flag) -> String:
    """Generates a ZSH completion spec for a single flag.

    Args:
        flag: The flag to generate a spec for.

    Returns:
        A ZSH _arguments spec string for the flag.
    """
    var escaped_usage = String(capacity=DEFAULT_BUFFER_SIZE)
    _zsh_escape(flag.usage, escaped_usage)
    var is_bool = flag.type == FType.Bool
    var is_list = flag.type.is_list_type()
    var prefix = "'*" if is_list else "'"

    if flag.shorthand:
        # Flag has both long and short forms
        var exclusion = t"(-{flag.shorthand} --{flag.name})"
        if is_bool:
            return String(t"'{exclusion}'{{-{flag.shorthand},--{flag.name}}'[{escaped_usage}]'")

        return String(
            t"{prefix}{exclusion}'{{-{flag.shorthand},--{flag.name}}'=[{escaped_usage}]:{flag.name}:'"
        )

    # Flag has only long form
    if is_bool:
        return String(t"'--{flag.name}'[{escaped_usage}]'")

    return String(t"{prefix}--{flag.name}=[{escaped_usage}]:{flag.name}:'")


fn _zsh_function_name(root_name: StringSlice, prefix: StringSlice) -> String:
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
    return String(t"_{root_name}{prefix}")


fn _zsh_command_function(
    cmd: Command, prefix: StringSlice, root_name: StringSlice, is_root: Bool
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
    var builder = String(capacity=DEFAULT_BUFFER_SIZE)

    builder.write(func_name, "() {\n")

    if has_children:
        builder.write(
            "    local curcontext=\"$curcontext\" state line\n",
            "    typeset -A opt_args\n",
            "    _arguments -C \\\n"
        )
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
        builder.write(t"        {flag_specs[i]} \\\n")

    if has_children:
        builder.write(
            "        '1: :->cmd' \\\n",
            "        '*:: :->args'\n"
        )

        # Generate case statement for subcommands
        builder.write(
            "    case $state in\n",
            "    cmd)\n",
            "        local -a commands\n",
            "        commands=(\n"
        )

        for i in range(len(cmd.children)):
            builder.write(t"            '{cmd.children[i][].name}:")
            _zsh_escape(cmd.children[i][].usage, builder)
            builder.write("'\n")

        builder.write(
            "        )\n",
            t"        _describe -t commands '{cmd.name} commands' commands\n",
            "        ;;\n",
            "    args)\n",
            "        case $line[1] in\n"
        )

        for i in range(len(cmd.children)):
            ref child_name = cmd.children[i][].name
            ref child_aliases = cmd.children[i][].aliases
            var child_prefix = String(t"{prefix}__{child_name}")
            var child_func = _zsh_function_name(root_name, child_prefix)

            # Build case pattern: name|alias1|alias2
            var pattern = child_name
            for j in range(len(child_aliases)):
                pattern.write("|", child_aliases[j])

            builder.write("        ", pattern, ") ", child_func, " ;;\n")

        builder.write(
            "        esac\n",
            "        ;;\n",
            "    esac\n"
        )
    else:
        # Leaf command - add valid_args completion if present
        if cmd.valid_args:
            var args_list = String(capacity=SMALL_BUFFER_SIZE)
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
    cmd: Command, prefix: StringSlice, root_name: StringSlice, is_root: Bool
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
        var child_prefix = String(t"{prefix}__{child_name}")
        builder.write(
            "\n",
            _zsh_functions_recursive(cmd.children[i][].copy(), child_prefix, root_name, is_root=False)
        )

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
    ref root_name = cmd[].name
    var builder = String(capacity=DEFAULT_BUFFER_SIZE)

    # Header
    builder.write(t"#compdef {root_name}\n", SCRIPT_HEADER)

    # Generate all functions recursively
    builder.write(_zsh_functions_recursive(cmd[], "", root_name, is_root=True))

    # Entry point: detect whether loaded by compinit (fpath) or sourced manually.
    # When compinit autoloads the file, funcstack[1] equals the function name,
    # so we call it directly in the completion context. Otherwise we register
    # the function with compdef so `source`-ing the script works too.
    builder.write(
        t"\nif [ \"$funcstack[1]\" = \"_{root_name}\" ]; then\n",
        t"    _{root_name} \"$@\"\n",
        "else\n",
        t"    compdef _{root_name} {root_name}\n",
        "fi\n"
    )

    return builder^
