from memory.arc import Arc
from collections.optional import Optional
import gojo.fmt
from .command import ArgValidatorFn
from .context import Context


fn no_args(ctx: Context) raises -> None:
    """Returns an error if the command has any arguments.

    Args:
        ctx: The context of the command being executed.
    """
    if len(ctx.args) > 0:
        raise Error(fmt.sprintf("The command `%s` does not take any arguments.", ctx.command[].name))


fn arbitrary_args(ctx: Context) raises -> None:
    """Never returns an error.

    Args:
        ctx: The context of the command being executed.
    """
    return None


fn minimum_n_args[n: Int]() -> ArgValidatorFn:
    """Returns an error if there is not at least n arguments.

    Params:
        n: The minimum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn less_than_n_args(ctx: Context) raises -> None:
        if len(ctx.args) < n:
            raise Error(
                fmt.sprintf(
                    "The command `%s` accepts at least %d argument(s). Received: %d.",
                    ctx.command[].name,
                    n,
                    len(ctx.args),
                )
            )

    return less_than_n_args


fn maximum_n_args[n: Int]() -> ArgValidatorFn:
    """Returns an error if there are more than n arguments.

    Params:
        n: The maximum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn more_than_n_args(ctx: Context) raises -> None:
        if len(ctx.args) > n:
            raise Error(
                fmt.sprintf(
                    "The command `%s` accepts at most %d argument(s). Received: %d.",
                    ctx.command[].name,
                    n,
                    len(ctx.args),
                )
            )

    return more_than_n_args


fn exact_args[n: Int]() -> ArgValidatorFn:
    """Returns an error if there are not exactly n arguments.

    Params:
        n: The number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn exactly_n_args(ctx: Context) raises -> None:
        if len(ctx.args) != n:
            raise Error(
                fmt.sprintf(
                    "The command `%s` accepts exactly %d argument(s). Received: %d.",
                    ctx.command[].name,
                    n,
                    len(ctx.args),
                )
            )

    return exactly_n_args


fn valid_args(ctx: Context) raises -> None:
    """Returns an error if threre are any positional args that are not in the command's `valid_args`.

    Args:
        ctx: The context of the command being executed.
    """
    if ctx.command[].valid_args:
        for arg in ctx.args:
            if arg[] not in ctx.command[].valid_args:
                raise Error(fmt.sprintf("Invalid argument: `%s`, for the command `%s`.", arg[], ctx.command[].name))


fn range_args[minimum: Int, maximum: Int]() -> ArgValidatorFn:
    """Returns an error if there are not exactly n arguments.

    Params:
        minimum: The minimum number of arguments.
        maximum: The maximum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn range_n_args(ctx: Context) raises -> None:
        if len(ctx.args) < minimum or len(ctx.args) > maximum:
            raise Error(
                fmt.sprintf(
                    "The command `%s`, accepts between %d to %d argument(s). Received: %d.",
                    ctx.command[].name,
                    minimum,
                    maximum,
                    len(ctx.args),
                )
            )

    return range_n_args


# TODO: Having some issues with varadic list of functions, so using List for now.
# Broken until alias list of functions is fixed. Pointer to function incorrectly points to 0x0.
# fn match_all[arg_validators: List[ArgValidatorFn]]() -> ArgValidatorFn:
#     """Returns an error if any of the arg_validators return an error.

#     Params:
#         arg_validators: A list of ArgValidatorFn functions that check the arguments.

#     Returns:
#         A function that checks all the arguments using the arg_validators list..
#     """

#     fn match_all_args(ctx: Context) raises -> None:
#         for i in range(len(arg_validators)):
#             arg_validators[i](ctx)

#     return match_all_args


fn get_args(arguments: List[String]) -> List[String]:
    """Parses flags and args from the args passed via the command line
    and adds them to their appropriate collections.

    Args:
        arguments: The arguments passed via the command line.

    Returns:
        The arguments that are not flags.
    """
    args = List[String](capacity=len(arguments))
    for argument in arguments:
        # Argument is not a shorthand or full flag.
        if not (argument[].startswith("-", 0, 1)):
            args.append(argument[])
    return args
