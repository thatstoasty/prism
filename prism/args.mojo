# from memory._arc import Arc
# from collections.optional import Optional
# from .vector import contains
# from .fmt import sprintf
# from .command import Command, PositionalArgs


# fn no_args(command: Arc[Command], args: List[String]) -> Optional[Error]:
#     """Returns an error if the command has any arguments.

#     Args:
#         command: The command to check.
#         args: The arguments to check.
#     """
#     if len(args) > 0:
#         return Error("Command " + command[].name + "does not take any arguments")
#     return None


# fn valid_args(command: Arc[Command], args: List[String]) -> Optional[Error]:
#     """Returns an error if threre are any positional args that are not in the command's valid_args.

#     Args:
#         command: The command to check.
#         args: The arguments to check.
#     """
#     if len(command[].valid_args) > 0:
#         for arg in args:
#             if not contains(command[].valid_args, arg[]):
#                 return Error(
#                     "Invalid argument " + arg[] + " for command " + command[].name
#                 )
#     return None


# fn arbitrary_args(command: Arc[Command], args: List[String]) -> Optional[Error]:
#     """Never returns an error.

#     Args:
#         command: The command to check.
#         args: The arguments to check.
#     """
#     return None


# fn minimum_n_args[n: Int]() -> PositionalArgs:
#     """Returns an error if there is not at least n arguments.

#     Args:
#         n: The minimum number of arguments.

#     Returns:
#         A function that checks the number of arguments.
#     """

#     fn less_than_n_args(command: Arc[Command], args: List[String]) -> Optional[Error]:
#         if len(args) < n:
#             return Error(
#                 sprintf(
#                     "Command %s accepts at least %d arguments. Received: %d.",
#                     command[].name,
#                     n,
#                     len(args),
#                 )
#             )
#         return None

#     return less_than_n_args


# fn maximumn_args[n: Int]() -> PositionalArgs:
#     """Returns an error if there are more than n arguments.

#     Args:
#         n: The maximum number of arguments.

#     Returns:
#         A function that checks the number of arguments.
#     """

#     fn more_than_n_args(command: Arc[Command], args: List[String]) -> Optional[Error]:
#         if len(args) > n:
#             return Error(
#                 "Command "
#                 + command[].name
#                 + " accepts at most "
#                 + n
#                 + " arguments. Received: "
#                 + len(args)
#             )
#         return None

#     return more_than_n_args


# fn exact_args[n: Int]() -> PositionalArgs:
#     """Returns an error if there are not exactly n arguments.

#     Args:
#         n: The number of arguments.

#     Returns:
#         A function that checks the number of arguments.
#     """

#     fn exactly_n_args(command: Arc[Command], args: List[String]) -> Optional[Error]:
#         if len(args) == n:
#             return Error(
#                 "Command "
#                 + command[].name
#                 + " accepts exactly "
#                 + n
#                 + " arguments. Received: "
#                 + len(args)
#             )
#         return None

#     return exactly_n_args


# fn range_args[minimum: Int, maximum: Int]() -> PositionalArgs:
#     """Returns an error if there are not exactly n arguments.

#     Args:
#         minimum: The minimum number of arguments.
#         maximum: The maximum number of arguments.

#     Returns:
#         A function that checks the number of arguments.
#     """

#     fn range_n_args(command: Arc[Command], args: List[String]) -> Optional[Error]:
#         if len(args) < minimum or len(args) > maximum:
#             return Error(
#                 "Command "
#                 + command[].name
#                 + " accepts between "
#                 + str(minimum)
#                 + "and "
#                 + str(maximum)
#                 + " arguments. Received: "
#                 + len(args)
#             )
#         return None

#     return range_n_args


# # fn match_all[*arg_validators: PositionalArgs]() -> PositionalArgs:
# #     fn match_all_args(command: Arc[Command], args: List[String]) -> Optional[Error]:
# #         for arg_validator in arg_validators:
# #             var error = arg_validator(command, args):
# #             if error:
# #                 return error
# #         return None
# #     return match_all_args
