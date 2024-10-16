# ShellCompDirectiveError indicates an error occurred and completions should be ignored.
alias ShellCompDirectiveError: Int = 1

# ShellCompDirectiveNoSpace indicates that the shell should not add a space
# after the completion even if there is a single completion provided.
alias ShellCompDirectiveNoSpace: Int = 2

# ShellCompDirectiveNoFileComp indicates that the shell should not provide
# file completion even when no completion is provided.
alias ShellCompDirectiveNoFileComp: Int = 3

# ShellCompDirectiveFilterFileExt indicates that the provided completions
# should be used as file extension filters.
# For flags, using Command.MarkFlagFilename() and Command.MarkPersistentFlagFilename()
# is a shortcut to using this directive explicitly.  The BashCompFilenameExt
# annotation can also be used to obtain the same behavior for flags.
alias ShellCompDirectiveFilterFileExt: Int = 4

# ShellCompDirectiveFilterDirs indicates that only directory names should
# be provided in file completion.  To request directory names within another
# directory, the returned completions should specify the directory within
# which to search.  The BashCompSubdirsInDir annotation can be used to
# obtain the same behavior but only for flags.
alias ShellCompDirectiveFilterDirs: Int = 5

# ShellCompDirectiveKeepOrder indicates that the shell should preserve the order
# in which the completions are provided
alias ShellCompDirectiveKeepOrder: Int = 6

# ===========================================================================

# All directives using iota should be above this one.
# For internal use.
alias shellCompDirectiveMaxValue: Int = 7

# ShellCompDirectiveDefault indicates to let the shell perform its default
# behavior after completions have been provided.
# This one must be last to avoid messing up the iota count.
alias ShellCompDirectiveDefault: Int = 0

alias activeHelpMarker = "_activeHelp_ "