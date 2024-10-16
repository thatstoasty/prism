from .command import Command
from .completions import ShellCompDirectiveError, ShellCompDirectiveNoSpace, ShellCompDirectiveNoFileComp, ShellCompDirectiveFilterFileExt, ShellCompDirectiveFilterDirs, ShellCompDirectiveKeepOrder, activeHelpMarker
import gojo.io
import gojo.bytes
import gojo.fmt

# ShellCompRequestCmd is the name of the hidden command that is used to request
# completion results from the program.  It is used by the shell completion scripts.
alias ShellCompRequestCmd = "__complete"

# ShellCompNoDescRequestCmd is the name of the hidden command that is used to request
# completion results without their description.  It is used by the shell completion scripts.
alias ShellCompNoDescRequestCmd = "__completeNoDesc"



# # GenZshCompletionFile generates zsh completion file including descriptions.
# fn GenZshCompletionFile(command: Command, file_name: String) raises -> None:
# 	return genZshCompletionFile(command, file_name, True)


# GenZshCompletion generates zsh completion file including descriptions
# and writes it to the passed writer.
fn GenZshCompletion(command: Command, inout writer: bytes.Buffer) raises -> None:
	return genZshCompletion(command, writer, True)


# # GenZshCompletionFileNoDesc generates zsh completion file without descriptions.
# fn GenZshCompletionFileNoDesc(command: Command, file_name: String) raises -> None:
# 	return genZshCompletionFile(command, file_name, False)


# GenZshCompletionNoDesc generates zsh completion file without descriptions
# and writes it to the passed writer.
fn GenZshCompletionNoDesc(command: Command, inout writer: bytes.Buffer) raises -> None:
	return genZshCompletion(command, writer, False)


# fn genZshCompletionFile(command: Command, file_name: String, include_desc: Bool) raises -> None:
#     with open(file_name, "w") as f:
# 	    return genZshCompletion(command, f, include_desc)


fn genZshCompletion(command: Command, inout writer: bytes.Buffer, include_desc: Bool) raises -> None:
    var buf = bytes.Buffer()
    genZshComp(buf, command.name, include_desc)
    _, err = buf.write_to(writer)
    if err:
        raise err

fn genZshComp(inout buf: bytes.Buffer, name: String, include_desc: Bool) -> None:
    alias script = """
compdef _%s %s

# zsh completion for %-36[1]s -*- shell-script -*-

__%s_debug()
{
    local file="$BASH_COMP_DEBUG_FILE"
    if [[ -n ${file} ]]; then
        echo "$*" >> "${file}"
    fi
}

_%s()
{
    local shellCompDirectiveError=%[3]d
    local shellCompDirectiveNoSpace=%[4]d
    local shellCompDirectiveNoFileComp=%[5]d
    local shellCompDirectiveFilterFileExt=%[6]d
    local shellCompDirectiveFilterDirs=%[7]d
    local shellCompDirectiveKeepOrder=%[8]d

    local lastParam lastChar flagPrefix requestComp out directive comp lastComp noSpace keepOrder
    local -a completions

    __%s_debug "\n========= starting completion logic =========="
    __%s_debug "CURRENT: ${CURRENT}, words[*]: ${words[*]}"

    # The user could have moved the cursor backwards on the command-line.
    # We need to trigger completion from the $CURRENT location, so we need
    # to truncate the command-line ($words) up to the $CURRENT location.
    # (We cannot use $CURSOR as its value does not work when a command is an alias.)
    words=("${=words[1,CURRENT]}")
    __%s_debug "Truncated words[*]: ${words[*]},"

    lastParam=${words[-1]}
    lastChar=${lastParam[-1]}
    __%s_debug "lastParam: ${lastParam}, lastChar: ${lastChar}"

    # For zsh, when completing a flag with an = (e.g., %s -n=<TAB>)
    # completions must be prefixed with the flag
    setopt local_options BASH_REMATCH
    if [[ "${lastParam}" =~ '-.*=' ]]; then
        # We are dealing with a flag with an =
        flagPrefix="-P ${BASH_REMATCH}"
    fi

    # Prepare the command to obtain completions
    requestComp="${words[1]} %[2]s ${words[2,-1]}"
    if [ "${lastChar}" = "" ]; then
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go completion code.
        __%s_debug "Adding extra empty parameter"
        requestComp="${requestComp} \"\""
    fi

    __%s_debug "About to call: eval ${requestComp}"

    # Use eval to handle any environment variables and such
    out=$(eval ${requestComp} 2>/dev/null)
    __%s_debug "completion output: ${out}"

    # Extract the directive integer following a : from the last line
    local lastLine
    while IFS='\n' read -r line; do
        lastLine=${line}
    done < <(printf "%%s\n" "${out[@]}")
    __%s_debug "last line: ${lastLine}"

    if [ "${lastLine[1]}" = : ]; then
        directive=${lastLine[2,-1]}
        # Remove the directive including the : and the newline
        local suffix
        (( suffix=${#lastLine}+2))
        out=${out[1,-$suffix]}
    else
        # There is no directive specified.  Leave $out as is.
        __%s_debug "No directive found.  Setting do default"
        directive=0
    fi

    __%s_debug "directive: ${directive}"
    __%s_debug "completions: ${out}"
    __%s_debug "flagPrefix: ${flagPrefix}"

    if [ $((directive & shellCompDirectiveError)) -ne 0 ]; then
        __%s_debug "Completion received error. Ignoring completions."
        return
    fi

    local activeHelpMarker="%[9]s"
    local endIndex=${#activeHelpMarker}
    local startIndex=$((${#activeHelpMarker}+1))
    local hasActiveHelp=0
    while IFS='\n' read -r comp; do
        # Check if this is an activeHelp statement (i.e., prefixed with $activeHelpMarker)
        if [ "${comp[1,$endIndex]}" = "$activeHelpMarker" ];then
            __%s_debug "ActiveHelp found: $comp"
            comp="${comp[$startIndex,-1]}"
            if [ -n "$comp" ]; then
                compadd -x "${comp}"
                __%s_debug "ActiveHelp will need delimiter"
                hasActiveHelp=1
            fi

            continue
        fi

        if [ -n "$comp" ]; then
            # If requested, completions are returned with a description.
            # The description is preceded by a TAB character.
            # For zsh's _describe, we need to use a : instead of a TAB.
            # We first need to escape any : as part of the completion itself.
            comp=${comp//:/\\:}

            local tab="$(printf '\t')"
            comp=${comp//$tab/:}

            __%s_debug "Adding completion: ${comp}"
            completions+=${comp}
            lastComp=$comp
        fi
    done < <(printf "%%s\n" "${out[@]}")

    # Add a delimiter after the activeHelp statements, but only if:
    # - there are completions following the activeHelp statements, or
    # - file completion will be performed (so there will be choices after the activeHelp)
    if [ $hasActiveHelp -eq 1 ]; then
        if [ ${#completions} -ne 0 ] || [ $((directive & shellCompDirectiveNoFileComp)) -eq 0 ]; then
            __%s_debug "Adding activeHelp delimiter"
            compadd -x "--"
            hasActiveHelp=0
        fi
    fi

    if [ $((directive & shellCompDirectiveNoSpace)) -ne 0 ]; then
        __%s_debug "Activating nospace."
        noSpace="-S ''"
    fi

    if [ $((directive & shellCompDirectiveKeepOrder)) -ne 0 ]; then
        __%s_debug "Activating keep order."
        keepOrder="-V"
    fi

    if [ $((directive & shellCompDirectiveFilterFileExt)) -ne 0 ]; then
        # File extension filtering
        local filteringCmd
        filteringCmd='_files'
        for filter in ${completions[@]}; do
            if [ ${filter[1]} != '*' ]; then
                # zsh requires a glob pattern to do file filtering
                filter="\\*.$filter"
            fi
            filteringCmd+=" -g $filter"
        done
        filteringCmd+=" ${flagPrefix}"

        __%s_debug "File filtering command: $filteringCmd"
        _arguments '*:filename:'"$filteringCmd"
    elif [ $((directive & shellCompDirectiveFilterDirs)) -ne 0 ]; then
        # File completion for directories only
        local subdir
        subdir="${completions[1]}"
        if [ -n "$subdir" ]; then
            __%s_debug "Listing directories in $subdir"
            pushd "${subdir}" >/dev/null 2>&1
        else
            __%s_debug "Listing directories in ."
        fi

        local result
        _arguments '*:dirname:_files -/'" ${flagPrefix}"
        result=$?
        if [ -n "$subdir" ]; then
            popd >/dev/null 2>&1
        fi
        return $result
    else
        __%s_debug "Calling _describe"
        if eval _describe $keepOrder "completions" completions $flagPrefix $noSpace; then
            __%s_debug "_describe found some completions"

            # Return the success of having called _describe
            return 0
        else
            __%s_debug "_describe did not find completions."
            __%s_debug "Checking if we should do file completion."
            if [ $((directive & shellCompDirectiveNoFileComp)) -ne 0 ]; then
                __%s_debug "deactivating file completion"

                # We must return an error code here to let zsh know that there were no
                # completions found by _describe; this is what will trigger other
                # matching algorithms to attempt to find completions.
                # For example zsh can match letters in the middle of words.
                return 1
            else
                # Perform file completion
                __%s_debug "Activating file completion"

                # We must return the result of this command, so it must be the
                # last command, or else we must store its result to return it.
                _arguments '*:filename:_files'" ${flagPrefix}"
            fi
        fi
    fi
}

# don't run the completion function when being source-ed or eval-ed
if [ "$funcstack[1]" = "_%s" ]; then
    _%s
fi
"""
    var compCmd = ShellCompRequestCmd
    if not include_desc:
        compCmd = ShellCompNoDescRequestCmd
	
    _, err = buf.write(
        fmt.sprintf(
            script, name, str(compCmd), ShellCompDirectiveError, ShellCompDirectiveNoSpace, ShellCompDirectiveNoFileComp,
            ShellCompDirectiveFilterFileExt, ShellCompDirectiveFilterDirs, ShellCompDirectiveKeepOrder,
            str(activeHelpMarker)
        ).as_bytes_slice()
    )