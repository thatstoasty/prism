from .command import (
    Command,
    CommandFn,
    CommandFnErr,
    ParentVisitorFn,
    HelpFn,
)

from .args import (
    no_args,
    valid_args,
    arbitrary_args,
    minimum_n_args,
    maximum_n_args,
    exact_args,
    range_args,
    match_all,
    ArgValidatorFn,
)
from .flag import Flag
from .flag_set import FlagSet
from .cli import CLI

alias ID = Int

# Set to True to traverse all parents' persistent pre and post run hooks. If False, it'll only run the first match.
# If False, starts from the child command and goes up the parent chain. If True, starts from root and goes down.
# TODO: For now it's locked to False until file scope variables.
alias ENABLE_TRAVERSE_RUN_HOOKS = False
