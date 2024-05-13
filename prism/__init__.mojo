from .command import (
    Command,
    CommandFunction,
    ArgValidator,
)
from .args import no_args, valid_args, arbitrary_args, minimum_n_args, maximum_n_args, exact_args, range_args, match_all
from .flag import Flag
from .flag_set import FlagSet


alias i1 = __mlir_type.i1
alias i1_1 = __mlir_attr.`1: i1`
alias i1_0 = __mlir_attr.`0: i1`
