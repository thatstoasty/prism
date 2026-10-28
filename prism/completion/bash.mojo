"""Bash completion script generation."""

from prism.command import Command
from prism.flag import Flag
from prism.opt_type import OptType
from prism.completion.shared import DEFAULT_BUFFER_SIZE, SCRIPT_HEADER, _arg_candidates, _completes_files


def _write_opts[origin: ImmOrigin, //](flag_names: Span[String, origin], mut builder: Some[Writer]):
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


comptime _COMPLETE_FILES = """        local IFS=$'\\n'
        COMPREPLY=( $(compgen -f -- "${cur}") )
"""
"""Completes file names. Splitting on newlines only keeps a name with spaces in it whole.

`compgen -f` is used rather than falling back to bash's own completion, which needs `compopt` to
switch on and off per word, and macOS still ships bash 3.2, which predates it."""


def _write_value_flag_case[file_origin: ImmOrigin, other_origin: ImmOrigin, //](
    file_flag_names: Span[String, file_origin],
    other_flag_names: Span[String, other_origin],
    mut builder: Some[Writer],
):
    """Writes a case that completes the value of a flag, when the previous word is one that takes a
    value, instead of suggesting flags where the value belongs.

    Args:
        file_flag_names: The long and short names of the flags whose values complete as file names.
        other_flag_names: The long and short names of the other flags that take a value. Nothing is
            offered for these, since a file name could only be wrong.
        builder: A Writer to write the case to.
    """
    if not file_flag_names and not other_flag_names:
        return

    builder.write('    case "${prev}" in\n')
    if file_flag_names:
        builder.write("        ", "|".join(file_flag_names), ")\n", _COMPLETE_FILES)
        builder.write("            return\n", "            ;;\n")
    if other_flag_names:
        builder.write("        ", "|".join(other_flag_names), ")\n")
        builder.write("            return\n", "            ;;\n")
    builder.write("    esac\n\n")


def _bash_command_function(
    cmd: Command, prefix: StringSpan, root_name: StringSpan, is_root: Bool
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
    var builder = String(capacity_bytes=DEFAULT_BUFFER_SIZE)

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

    # Names of the flags that take a value, split by whether that value completes as a file name.
    var file_flag_names = List[String]()
    var other_flag_names = List[String]()

    var flags = cmd.flags.flags.copy()
    # Add inherited persistent flags from ancestors (if not root)
    if not is_root and cmd.has_parent():
        for flag in cmd.inherited_flags():
            flags.append(flag.copy())

    for flag in flags:
        if flag.name not in seen_flags:
            seen_flags[flag.name] = True
            flag_names.append(String(t"--{flag.name}"))
            if flag.shorthand:
                flag_names.append(String(t"-{flag.shorthand}"))
            if _completes_files(flag):
                file_flag_names.append(String(t"--{flag.name}"))
                if flag.shorthand:
                    file_flag_names.append(String(t"-{flag.shorthand}"))
            elif flag.type != OptType.Bool:
                other_flag_names.append(String(t"--{flag.name}"))
                if flag.shorthand:
                    other_flag_names.append(String(t"-{flag.shorthand}"))

    if has_children:
        # Collect subcommand names (including aliases)
        var subcmds = List[String]()
        for i in range(len(cmd.children)):
            subcmds.append(cmd.children[i][].name)
            ref child_aliases = cmd.children[i][].aliases
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
        builder.write("    local i\n")
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
        _write_value_flag_case(file_flag_names, other_flag_names, builder)

        # If no subcommand matched, complete commands and flags
        builder.write(
            '    if [[ "${cur}" == -* ]]; then\n',
            '        COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )\n',
            "    else\n",
            '        COMPREPLY=( $(compgen -W "${cmds}" -- "${cur}") )\n',
            "    fi\n"
        )
    else:
        # Leaf command: flags when the word starts with `-`, otherwise the values its arguments
        # accept, or file names when it names none.
        _write_value_flag_case(file_flag_names, other_flag_names, builder)
        _write_opts(flag_names, builder)
        builder.write('"\n')

        var candidates = _arg_candidates(cmd)
        builder.write('    if [[ "${cur}" == -* ]]; then\n')
        builder.write('        COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )\n')
        builder.write("    else\n")
        if candidates:
            builder.write('        COMPREPLY=( $(compgen -W "', " ".join(candidates), '" -- "${cur}") )\n')
        else:
            builder.write(_COMPLETE_FILES)
        builder.write("    fi\n")

    builder.write("}\n")
    return builder^


def _bash_functions_recursive(
    cmd: Command, prefix: StringSpan, root_name: StringSpan, is_root: Bool
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


def generate_bash_completion(cmd: Command) raises -> String:
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
    var builder = String(capacity_bytes=DEFAULT_BUFFER_SIZE)

    # Header
    builder.write("#!/usr/bin/env bash\n", SCRIPT_HEADER)

    # Generate all functions recursively
    builder.write(_bash_functions_recursive(cmd, "", root_name, is_root=True))

    # Register the completion
    # `-o filenames` quotes completed file names and marks directories with a trailing slash. File
    # names are only offered where the script asks for them, so a parent command offers its
    # subcommands and nothing else, where `-o default` fell back to file names for any word.
    builder.write("\ncomplete -o filenames -F __", root_name, " ", root_name, "\n")

    return builder^
