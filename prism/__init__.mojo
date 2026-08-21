"""Prism, a library for building command-line interfaces in Mojo."""

from prism._arg_parse import read_args, read_args_from_stdin
from prism._flag_set import FlagSet
from prism.args import arbitrary_args, exact_args, maximum_n_args, minimum_n_args, no_args, range_args, valid_args
from prism.command import Command
from prism.flag import Flag
from prism.from_flag_value import FromFlagValue
from prism.help import Help, HelpContext
from prism.version import Version
