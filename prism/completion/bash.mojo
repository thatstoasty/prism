from prism.command import Command
from prism.flag import Flag, FType
from prism.completion.shared import SMALL_BUFFER_SIZE, DEFAULT_BUFFER_SIZE, SCRIPT_HEADER


fn _bash_escape(s: String, mut writer: Some[Writer]):
    """Escapes special characters in a string for use in bash completion descriptions.

    Single quotes in descriptions need to be escaped for bash.

    Args:
        s: The string to escape.
        writer: A Writer to write the escaped string to.
    """
    comptime QUOTE = Codepoint.ord("'")
    comptime ESCAPED_QUOTE = "'\\''"
    for c in s.codepoints():
        if c == QUOTE:
            writer.write(ESCAPED_QUOTE)
        else:
            writer.write(c)


fn _write_opts[origin: ImmutOrigin, //](flag_names: Span[String, origin], mut builder: Some[Writer]):
    """Writes the opts string for bash completion.

    Args:
        flag_names: The list of flag names to include in the opts string.
        builder: A Writer to write the opts string to.
    """
    builder.write(t'    opts="')
    for i in range(len(flag_names)):
        if i > 0:
            builder.write(" ")
        builder.write(flag_names[i])


fn _bash_command_function(
    cmd: Command, prefix: StringSlice, root_name: StringSlice, is_root: Bool
) raises -> String:
    """Generates a bash completion function for a single command.

    Args:
        cmd: The command to generate the function for.
        prefix: The accumulated prefix for nested commands.
        root_name: The root command name.
        is_root: Whether this is the root command.

    Returns:
        The bash function body as a string.

    Raises:
        If an error occurs during generation.
    """
    var has_children = Bool(cmd.children)
    var builder = String(capacity=DEFAULT_BUFFER_SIZE)

    builder.write(
        t"__{root_name}{prefix}() ", "{", "\n",
        "    local cur prev opts cmds\n",
        "    COMPREPLY=()\n",
        '    cur="${COMP_WORDS[COMP_CWORD]}"\n',
        '    prev="${COMP_WORDS[COMP_CWORD-1]}"\n'
    )

    # Collect flags
    var seen_flags = Dict[String, Bool]()
    var flag_names = List[String]()

    for flag in cmd.flags:
        if flag.name not in seen_flags:
            seen_flags[flag.name] = True
            flag_names.append(String(t"--{flag.name}"))
            if flag.shorthand:
                flag_names.append(String(t"-{flag.shorthand}"))

    # Add inherited persistent flags from ancestors (if not root)
    if not is_root and cmd.has_parent():
        var inherited = cmd.inherited_flags()
        for flag in inherited:
            if flag.name not in seen_flags:
                seen_flags[flag.name] = True
                flag_names.append(String(t"--{flag.name}"))
                if flag.shorthand:
                    flag_names.append(String(t"-{flag.shorthand}"))

    if has_children:
        # Collect subcommand names (including aliases)
        var subcmds = List[String]()
        for i in range(len(cmd.children)):
            subcmds.append(cmd.children[i][].name)
            var child_aliases = cmd.children[i][].aliases.copy()
            for j in range(len(child_aliases)):
                subcmds.append(child_aliases[j])

        # Write the cmds string for subcommands
        builder.write('    cmds="')
        for i in range(len(subcmds)):
            if i > 0:
                builder.write(" ")
            builder.write(subcmds[i])
        builder.write('"\n')

        # Write the opts string for flags
        builder.write('    opts="')
        for i in range(len(flag_names)):
            if i > 0:
                builder.write(" ")
            builder.write(flag_names[i])
        builder.write('"\n\n')

        # Determine which subcommand is being completed by scanning COMP_WORDS
        builder.write("    local i cmd_found=0\n")
        builder.write("    for ((i=1; i < COMP_CWORD; i++)); do\n")
        builder.write("        case \"${COMP_WORDS[i]}\" in\n")

        for i in range(len(cmd.children)):
            ref child_name = cmd.children[i][].name
            ref child_aliases = cmd.children[i][].aliases
            builder.write("           ", child_name)
            for j in range(len(child_aliases)):
                builder.write("|", child_aliases[j])

            # Write the end of aliases, and write the call to the child function.
            builder.write(
                ")\n",
                t"                __{root_name}{prefix}__{child_name}\n",
                t"                return\n",
                "                ;;\n"
            )

        builder.write("        esac\n", "    done\n\n")

        # If no subcommand matched, complete commands and flags
        builder.write(
            '    if [[ "${cur}" == -* ]]; then\n',
            '        COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )\n',
            "    else\n",
            '        COMPREPLY=( $(compgen -W "${cmds}" -- "${cur}") )\n',
            "    fi\n"
        )
    else:
        # Leaf command
        if cmd.valid_args:
            var args_list = String(capacity=SMALL_BUFFER_SIZE)
            for i in range(len(cmd.valid_args)):
                if i > 0:
                    args_list.write(" ")
                args_list.write(cmd.valid_args[i])
            _write_opts(flag_names, builder)
            builder.write(t' {args_list}"\n')
        else:
            _write_opts(flag_names, builder)
            builder.write(t'"\n')
        builder.write('    COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )\n')

    builder.write("}\n")
    return builder^


fn _bash_functions_recursive(
    cmd: Command, prefix: StringSlice, root_name: StringSlice, is_root: Bool
) raises -> String:
    """Recursively generates bash completion functions for a command and all its children.

    Args:
        cmd: The command to generate functions for.
        prefix: The accumulated prefix for nested commands.
        root_name: The root command name.
        is_root: Whether this is the root command.

    Returns:
        All bash function definitions concatenated.

    Raises:
        If an error occurs during generation.
    """
    var builder = _bash_command_function(cmd, prefix, root_name, is_root)

    for i in range(len(cmd.children)):
        ref child_name = cmd.children[i][].name
        ref child_prefix = String(prefix, "__", child_name)
        builder.write("\n", _bash_functions_recursive(cmd.children[i][], child_prefix, root_name, is_root=False))

    return builder^


fn generate_bash_completion(cmd: Command) raises -> String:
    """Generates a complete bash completion script for the given command tree.

    The generated script uses bash's `complete` builtin and `compgen` for
    completion. Function names use double-underscore separators
    (e.g. __myapp__sub__nested).

    Args:
        cmd: The root command to generate completions for.

    Returns:
        A complete bash completion script as a string.

    Raises:
        If an error occurs during generation.
    """
    ref root_name = cmd.name
    var builder = String(capacity=DEFAULT_BUFFER_SIZE)

    # Header
    builder.write("#!/usr/bin/env bash\n", SCRIPT_HEADER)

    # Generate all functions recursively
    builder.write(_bash_functions_recursive(cmd, "", root_name, is_root=True))

    # Register the completion
    builder.write("\ncomplete -F __", root_name, " ", root_name, "\n")

    return builder^
