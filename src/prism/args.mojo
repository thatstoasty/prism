from memory import ArcPointer
from collections.optional import Optional
from prism.command import ArgValidatorFn, Command
from prism.context import Context


fn no_args(ctx: Context) raises -> None:
    """Returns an error if the command has any arguments.

    Args:
        ctx: The context of the command being executed.
    """
    if len(ctx.args) > 0:
        raise Error("The command `{}` does not take any arguments.".format(ctx.command[].name))


fn arbitrary_args(ctx: Context) raises -> None:
    """Never returns an error.

    Args:
        ctx: The context of the command being executed.
    """
    return None


fn minimum_n_args[n: Int]() -> ArgValidatorFn:
    """Returns an error if there is not at least n arguments.

    Parameters:
        n: The minimum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn less_than_n_args(ctx: Context) raises -> None:
        if len(ctx.args) < n:
            raise Error(
                "The command `{}` accepts at least {} argument(s). Received: {}.".format(
                    ctx.command[].name,
                    n,
                    len(ctx.args),
                )
            )

    return less_than_n_args


fn maximum_n_args[n: UInt]() -> ArgValidatorFn:
    """Returns an error if there are more than n arguments.

    Parameters:
        n: The maximum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn more_than_n_args(ctx: Context) raises -> None:
        if len(ctx.args) > n:
            raise Error(
                "The command `{}` accepts at most {} argument(s). Received: {}.".format(
                    ctx.command[].name,
                    n,
                    len(ctx.args),
                )
            )

    return more_than_n_args


fn exact_args[n: UInt]() -> ArgValidatorFn:
    """Returns an error if there are not exactly n arguments.

    Parameters:
        n: The number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn exactly_n_args(ctx: Context) raises -> None:
        if len(ctx.args) != n:
            raise Error(
                "The command `{}` accepts exactly {} argument(s). Received: {}.".format(
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
            if String(arg[]) not in ctx.command[].valid_args:
                raise Error("Invalid argument: `{}`, for the command `{}`.".format(arg[], ctx.command[].name))


fn range_args[minimum: UInt, maximum: UInt]() -> ArgValidatorFn:
    """Returns an error if there are not exactly n arguments.

    Parameters:
        minimum: The minimum number of arguments.
        maximum: The maximum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn range_n_args(ctx: Context) raises -> None:
        if len(ctx.args) < minimum or len(ctx.args) > maximum:
            raise Error(
                "The command `{}`, accepts between {} to {} argument(s). Received: {}.".format(
                    ctx.command[].name,
                    minimum,
                    maximum,
                    len(ctx.args),
                )
            )

    return range_n_args


# TODO: Having some issues with varadic list of functions, so using List for now.
# Broken until alias list of functions is fixed. Pointer to function incorrectly points to 0x0.
fn match_all[*arg_validators: ArgValidatorFn]() -> ArgValidatorFn:
    """Returns an error if any of the arg_validators return an error.

    Parameters:
        arg_validators: A list of ArgValidatorFn functions that check the arguments.

    Returns:
        A function that checks all the arguments using the arg_validators list..
    """

    fn match_all_args(ctx: Context) raises -> None:
        alias validators = VariadicList(arg_validators)
        for validator in validators:
            validator(ctx)

    return match_all_args
