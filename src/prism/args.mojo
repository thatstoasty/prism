from memory.arc import Arc
from collections.optional import Optional
import gojo.fmt
from .command import CommandArc, ArgValidator


fn no_args(command: CommandArc, args: List[String]) raises -> None:
    """Returns an error if the command has any arguments.

    Args:
        command: Reference to the command being executed.
        args: The arguments to check.
    """
    var cmd = command
    if len(args) > 0:
        raise Error(fmt.sprintf("The command `%s` does not take any arguments.", cmd[].name))


fn arbitrary_args(command: CommandArc, args: List[String]) raises -> None:
    """Never returns an error.

    Args:
        command: Reference to the command being executed.
        args: The arguments to check.
    """
    return None


fn minimum_n_args[n: Int]() -> ArgValidator:
    """Returns an error if there is not at least n arguments.

    Params:
        n: The minimum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn less_than_n_args(command: CommandArc, args: List[String]) raises -> None:
        var cmd = command
        if len(args) < n:
            raise Error(
                fmt.sprintf(
                    "The command `%s` accepts at least %d argument(s). Received: %d.",
                    cmd[].name,
                    n,
                    len(args),
                )
            )

    return less_than_n_args


fn maximum_n_args[n: Int]() -> ArgValidator:
    """Returns an error if there are more than n arguments.

    Params:
        n: The maximum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn more_than_n_args(command: CommandArc, args: List[String]) raises -> None:
        var cmd = command
        if len(args) > n:
            raise Error(
                fmt.sprintf("The command `%s` accepts at most %d argument(s). Received: %d.", cmd[].name, n, len(args))
            )

    return more_than_n_args


fn exact_args[n: Int]() -> ArgValidator:
    """Returns an error if there are not exactly n arguments.

    Params:
        n: The number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn exactly_n_args(command: CommandArc, args: List[String]) raises -> None:
        var cmd = command
        if len(args) != n:
            raise Error(
                fmt.sprintf("The command `%s` accepts exactly %d argument(s). Received: %d.", cmd[].name, n, len(args))
            )

    return exactly_n_args


fn valid_args() -> ArgValidator:
    """Returns an error if threre are any positional args that are not in the command's valid_args.

    Params:
        valid: The valid arguments to check against.
    """

    fn only_valid_args(command: CommandArc, args: List[String]) raises -> None:
        var cmd = command
        if cmd[].valid_args:
            for arg in args:
                if arg[] not in cmd[].valid_args:
                    raise Error(fmt.sprintf("Invalid argument: `%s`, for the command `%s`.", arg[], cmd[].name))

    return only_valid_args


fn range_args[minimum: Int, maximum: Int]() -> ArgValidator:
    """Returns an error if there are not exactly n arguments.

    Params:
        minimum: The minimum number of arguments.
        maximum: The maximum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn range_n_args(command: CommandArc, args: List[String]) raises -> None:
        var cmd = command
        if len(args) < minimum or len(args) > maximum:
            raise Error(
                fmt.sprintf(
                    "The command `%s`, accepts between %d to %d argument(s). Received: %d.",
                    cmd[].name,
                    minimum,
                    maximum,
                    len(args),
                )
            )

    return range_n_args


# TODO: Having some issues with varadic list of functions, so using List for now.
fn match_all[arg_validators: List[ArgValidator]]() -> ArgValidator:
    """Returns an error if any of the arg_validators return an error.

    Params:
        arg_validators: A list of ArgValidator functions that check the arguments.

    Returns:
        A function that checks all the arguments using the arg_validators list..
    """

    fn match_all_args(command: CommandArc, args: List[String]) raises -> None:
        for i in range(len(arg_validators)):
            arg_validators[i](command, args)

    return match_all_args


fn get_args(arguments: List[String]) -> List[String]:
    """Parses flags and args from the args passed via the command line
    and adds them to their appropriate collections.

    Args:
        arguments: The arguments passed via the command line.

    Returns:
        The arguments that are not flags.
    """
    var args = List[String](capacity=len(arguments))
    for argument in arguments:
        # Argument is not a shorthand or full flag.
        if not (argument[].startswith("-", 0, 1)):
            args.append(argument[])
    return args