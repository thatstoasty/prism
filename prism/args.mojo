from memory import OwnedPointer


alias ArgValidatorFn = fn (cmd: OwnedPointer[Command], args: List[String]) raises -> None
"""The function for an argument validator."""


fn no_args(cmd: OwnedPointer[Command], args: List[String]) raises -> None:
    """Returns an error if the command has any arguments.

    Args:
        cmd: The command being executed.
        args: The arguments passed to the command.
    """
    if len(args) > 0:
        raise Error("The command `", cmd[].name, "` does not take any arguments.")


fn arbitrary_args(cmd: OwnedPointer[Command], args: List[String]) raises -> None:
    """Never returns an error.

    Args:
        cmd: The command being executed.
        args: The arguments passed to the command.
    """
    return None


fn minimum_n_args[n: Int]() -> ArgValidatorFn:
    """Returns an error if there is not at least n arguments.

    Parameters:
        n: The minimum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn less_than_n_args(cmd: OwnedPointer[Command], args: List[String]) raises -> None:
        if len(args) < n:
            raise Error(
                "The command `",
                cmd[].name,
                "` accepts at least ",
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

    fn more_than_n_args(cmd: OwnedPointer[Command], args: List[String]) raises -> None:
        if len(args) > n:
            raise Error("The command `", cmd[].name, "` accepts at most ", n, " argument(s). Received: ", len(args))

    return more_than_n_args


fn exact_args[n: UInt]() -> ArgValidatorFn:
    """Returns an error if there are not exactly n arguments.

    Parameters:
        n: The number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn exactly_n_args(cmd: OwnedPointer[Command], args: List[String]) raises -> None:
        if len(args) != n:
            alias msg = StaticString("The command `{}` accepts exactly {} argument(s). Received: {}.")
            raise Error(msg.format(cmd[].name, n, len(args)))

    return exactly_n_args


fn valid_args(cmd: OwnedPointer[Command], args: List[String]) raises -> None:
    """Returns an error if threre are any positional args that are not in the command's `valid_args`.

    Args:
        cmd: The command being executed.
        args: The arguments passed to the command.
    """
    if cmd[].valid_args:
        for arg in args:
            if arg not in cmd[].valid_args:
                raise Error("Invalid argument: `", arg, "`, for the command `", cmd[].name, "`.")


fn range_args[minimum: UInt, maximum: UInt]() -> ArgValidatorFn:
    """Returns an error if there are not exactly n arguments.

    Parameters:
        minimum: The minimum number of arguments.
        maximum: The maximum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn range_n_args(cmd: OwnedPointer[Command], args: List[String]) raises -> None:
        if len(args) < minimum or len(args) > maximum:
            raise Error(
                "The command `",
                cmd[].name,
                "`, accepts between ",
                minimum,
                " to ",
                maximum,
                " argument(s). Received: ",
                len(args),
            )

    return range_n_args


# fn match_all[*arg_validators: ArgValidatorFn]() -> ArgValidatorFn:
#     """Returns an error if any of the arg_validators return an error.

#     Parameters:
#         arg_validators: A list of ArgValidatorFn functions that check the arguments.

#     Returns:
#         A function that checks all the arguments using the arg_validators list..
#     """
#     fn match_all_args(cmd: OwnedPointer[Command], args: List[String]) raises -> None:
#         # alias validators = VariadicList(arg_validators)
#         @parameter
#         for i in range(len(arg_validators)):
#             print(i)
#             arg_validators[i](cmd, args)

#     return match_all_args
