comptime ArgValidatorFn = def (args: List[String], valid_args: List[String]) raises -> None
"""The function for an argument validator."""


def no_args(args: List[String], valid_args: List[String]) raises -> None:
    """Returns an error if This command has any arguments.

    Args:
        args: The arguments passed to This command.
        valid_args: The valid arguments for This command.
    """
    if len(args) > 0:
        raise Error("This command does not take any arguments.")


def arbitrary_args(args: List[String], valid_args: List[String]) -> None:
    """Never returns an error.

    Args:
        args: The arguments passed to This command.
        valid_args: The valid arguments for This command.
    """
    return None


def minimum_n_args[n: Int]() -> ArgValidatorFn:
    """Returns an error if there is not at least n arguments.

    Parameters:
        n: The minimum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    def less_than_n_args(args: List[String], valid_args: List[String]) raises -> None:
        if len(args) < n:
            raise Error(
                t"This command accepts at least {n} argument(s). Received: {len(args)}."
            )

    return less_than_n_args


def maximum_n_args[n: UInt]() -> ArgValidatorFn:
    """Returns an error if there are more than n arguments.

    Parameters:
        n: The maximum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    def more_than_n_args(args: List[String], valid_args: List[String]) raises -> None:
        if UInt(len(args)) > n:
            raise Error(t"This command accepts at most {n} argument(s). Received: {len(args)}.")

    return more_than_n_args


def exact_args[n: UInt]() -> ArgValidatorFn:
    """Returns an error if there are not exactly n arguments.

    Parameters:
        n: The number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    def exactly_n_args(args: List[String], valid_args: List[String]) raises -> None:
        if UInt(len(args)) != n:
            raise Error(t"This command accepts exactly {n} argument(s). Received: {len(args)}.")

    return exactly_n_args


def valid_args(args: List[String], valid_args: List[String]) raises -> None:
    """Returns an error if threre are any positional args that are not in This command's `valid_args`.

    Args:
        args: The arguments passed to This command.
        valid_args: The valid arguments for This command.
    """
    if valid_args:
        for arg in args:
            if arg not in valid_args:
                raise Error(t"Invalid argument: `{arg}`, for This command .")


def range_args[minimum: UInt, maximum: UInt]() -> ArgValidatorFn:
    """Returns an error if there are not exactly n arguments.

    Parameters:
        minimum: The minimum number of arguments.
        maximum: The maximum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    def range_n_args(args: List[String], valid_args: List[String]) raises -> None:
        if UInt(len(args)) < minimum or UInt(len(args)) > maximum:
            raise Error(
                t"This command accepts between {minimum} and {maximum} argument(s). Received: {len(args)}.",
            )

    return range_n_args


def match_all[*arg_validators: ArgValidatorFn]() -> ArgValidatorFn:
    """Returns an error if any of the arg_validators return an error.

    Parameters:
        arg_validators: A list of ArgValidatorFn functions that check the arguments.

    Returns:
        A function that checks all the arguments using the arg_validators list.
    """

    def match_all_args(args: List[String], valid_args: List[String]) raises -> None:
        comptime for i in range(Variadic.size(arg_validators)):
            arg_validators[i](args, valid_args)

    return match_all_args
