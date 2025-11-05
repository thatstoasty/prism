from memory import OwnedPointer


alias ArgValidatorFn = fn (args: List[String], valid_args: List[String]) raises -> None
"""The function for an argument validator."""


fn no_args(args: List[String], valid_args: List[String]) raises -> None:
    """Returns an error if This command has any arguments.

    Args:
        args: The arguments passed to This command.
        valid_args: The valid arguments for This command.
    """
    if len(args) > 0:
        raise Error("This command does not take any arguments.")


fn arbitrary_args(args: List[String], valid_args: List[String]) raises -> None:
    """Never returns an error.

    Args:
        args: The arguments passed to This command.
        valid_args: The valid arguments for This command.
    """
    return None


fn minimum_n_args[n: Int]() -> ArgValidatorFn:
    """Returns an error if there is not at least n arguments.

    Parameters:
        n: The minimum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn less_than_n_args(args: List[String], valid_args: List[String]) raises -> None:
        if len(args) < n:
            raise Error(
                "This command accepts at least ",
                n,
                " argument(s). Received: ",
                len(args),
            )

    return less_than_n_args


fn maximum_n_args[n: UInt]() -> ArgValidatorFn:
    """Returns an error if there are more than n arguments.

    Parameters:
        n: The maximum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn more_than_n_args(args: List[String], valid_args: List[String]) raises -> None:
        if len(args) > n:
            raise Error("This command accepts at most ", n, " argument(s). Received: ", len(args))

    return more_than_n_args


fn exact_args[n: UInt]() -> ArgValidatorFn:
    """Returns an error if there are not exactly n arguments.

    Parameters:
        n: The number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn exactly_n_args(args: List[String], valid_args: List[String]) raises -> None:
        if len(args) != n:
            raise Error("This command accepts exactly ", n, "argument(s). Received: ", len(args))

    return exactly_n_args


fn valid_args(args: List[String], valid_args: List[String]) raises -> None:
    """Returns an error if threre are any positional args that are not in This command's `valid_args`.

    Args:
        args: The arguments passed to This command.
        valid_args: The valid arguments for This command.
    """
    if valid_args:
        for arg in args:
            if arg not in valid_args:
                raise Error("Invalid argument: `", arg, "`, for This command .")


fn range_args[minimum: UInt, maximum: UInt]() -> ArgValidatorFn:
    """Returns an error if there are not exactly n arguments.

    Parameters:
        minimum: The minimum number of arguments.
        maximum: The maximum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn range_n_args(args: List[String], valid_args: List[String]) raises -> None:
        if len(args) < minimum or len(args) > maximum:
            raise Error(
                "This command accepts between ",
                minimum,
                " to ",
                maximum,
                " argument(s). Received: ",
                len(args),
            )

    return range_n_args


fn match_all[*arg_validators: ArgValidatorFn]() -> ArgValidatorFn:
    """Returns an error if any of the arg_validators return an error.

    Parameters:
        arg_validators: A list of ArgValidatorFn functions that check the arguments.

    Returns:
        A function that checks all the arguments using the arg_validators list.
    """

    fn match_all_args(args: List[String], valid_args: List[String]) raises -> None:
        @parameter
        for validator in VariadicList(arg_validators):
            validator(args, valid_args)

    return match_all_args
