from collections.optional import Optional
from external.gojo.fmt import sprintf
from .vector import contains


# TODO: Until Error is a CollectionElement, return a string and throw the error from the caller.
# TODO: It is difficult to have recursive relationships, not passing the command to the arg validator for now.
# alias ArgValidator = fn (
#     command: CommandArc, args: List[String]
# ) escaping -> Optional[String]

alias ArgValidator = fn (args: List[String]) escaping -> Optional[String]


fn no_args(args: List[String]) -> Optional[String]:
    """Returns an error if the command has any arguments.

    Args:
        args: The arguments to check.
    """
    if len(args) > 0:
        return String("Command ") + String("does not take any arguments")
    return None


fn arbitrary_args(args: List[String]) -> Optional[String]:
    """Never returns an error.

    Args:
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

    fn less_than_n_args(args: List[String]) -> Optional[String]:
        if len(args) < n:
            return sprintf(
                "Command accepts at least %d arguments. Received: %d.",
                n,
                len(args),
            )
        return None

    return less_than_n_args


fn maximum_n_args[n: Int]() -> ArgValidator:
    """Returns an error if there are more than n arguments.

    Params:
        n: The maximum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn more_than_n_args(args: List[String]) -> Optional[String]:
        if len(args) > n:
            return sprintf("Command accepts at most %d arguments. Received: %d", n, len(args))
        return None

    return more_than_n_args


fn exact_args[n: Int]() -> ArgValidator:
    """Returns an error if there are not exactly n arguments.

    Params:
        n: The number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn exactly_n_args(args: List[String]) -> Optional[String]:
        if len(args) != n:
            return sprintf("Command accepts at exactly %d arguments. Received: %d", n, len(args))
        return None

    return exactly_n_args


fn valid_args[valid: List[String]]() -> ArgValidator:
    """Returns an error if threre are any positional args that are not in the command's valid_args.

    Params:
        valid: The valid arguments to check against.
    """

    fn only_valid_args(args: List[String]) -> Optional[String]:
        if len(valid) > 0:
            for arg in args:
                if not contains(valid, arg[]):
                    return String("Invalid argument ") + arg[] + String(" for command.")
        return None

    return only_valid_args


fn range_args[minimum: Int, maximum: Int]() -> ArgValidator:
    """Returns an error if there are not exactly n arguments.

    Params:
        minimum: The minimum number of arguments.
        maximum: The maximum number of arguments.

    Returns:
        A function that checks the number of arguments.
    """

    fn range_n_args(args: List[String]) -> Optional[String]:
        if len(args) < minimum or len(args) > maximum:
            return sprintf(
                "Command accepts between %d and %d arguments. Received: %d",
                minimum,
                maximum,
                len(args),
            )
        return None

    return range_n_args


# TODO: Having some issues with varadic list of functions, so using List for now.
fn match_all[arg_validators: List[ArgValidator]]() -> ArgValidator:
    """Returns an error if any of the arg_validators return an error."""

    fn match_all_args(args: List[String]) -> Optional[String]:
        for i in range(len(arg_validators)):
            var error = arg_validators[i](args)
            if error:
                return error
        return None

    return match_all_args


fn get_args(arguments: List[String]) -> List[String]:
    """Parses flags and args from the args passed via the command line and adds them to their appropriate collections.
    """
    var args = List[String]()
    for i in range(len(arguments)):
        # Argument is not a shorthand or full flag.
        var argument = arguments[i]
        if not (argument.startswith("-", 0, 1)):
            args.append(argument)
    return args
