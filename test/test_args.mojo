from memory.arc import Arc
import testing
from prism import Command
from prism.args import (
    no_args,
    valid_args,
    arbitrary_args,
    minimum_n_args,
    maximum_n_args,
    exact_args,
    range_args,
    match_all,
    ArgValidatorFn,
)


# fn dummy(inout command: CommandArc, args: List[String]) -> None:
#     return None


# TODO: renable these when we have assert raises in testing
# def test_no_args():
#     var cmd = Command(name="root", usage="Base command.", run=dummy)
#     var arc = Arc(cmd)
#     var result = no_args(arc, List[String]("abc"))
#     testing.assert_equal(result.value(), String("The command `root` does not take any arguments."))


# def test_valid_args():
#     var cmd = Command(name="root", usage="Base command.", run=dummy)
#     var result = valid_args[List[String]("Pineapple")]()(Arc(cmd), List[String]("abc"))
#     testing.assert_equal(result.value(), "Invalid argument: `abc`, for the command `root`.")


# def test_arbitrary_args():
#     var cmd = Command(name="root", usage="Base command.", run=dummy)
#     var result = arbitrary_args(Arc(cmd), List[String]("abc", "blah", "blah"))

#     # If the result is anything but None, fail the test.
#     if result is not None:
#         testing.assert_false(True)


# def test_minimum_n_args():
#     var cmd = Command(name="root", usage="Base command.", run=dummy)
#     var result = minimum_n_args[3]()(Arc(cmd), List[String]("abc", "123"))
#     testing.assert_equal(result.value(), "The command `root` accepts at least 3 argument(s). Received: 2.")


# def test_maximum_n_args():
#     var cmd = Command(name="root", usage="Base command.", run=dummy)
#     var result = maximum_n_args[1]()(Arc(cmd), List[String]("abc", "123"))
#     testing.assert_equal(result.value(), "The command `root` accepts at most 1 argument(s). Received: 2.")


# def test_exact_args():
#     var cmd = Command(name="root", usage="Base command.", run=dummy)
#     var result = exact_args[1]()(Arc(cmd), List[String]("abc", "123"))
#     testing.assert_equal(result.value(), "The command `root` accepts exactly 1 argument(s). Received: 2.")


# def test_range_args():
#     var cmd = Command(name="root", usage="Base command.", run=dummy)
#     var result = range_args[0, 1]()(Arc(cmd), List[String]("abc", "123"))
#     testing.assert_equal(result.value(), "The command `root`, accepts between 0 to 1 argument(s). Received: 2.")


# def test_match_all():
#     var cmd = Command(name="root", usage="Base command.", run=dummy)
#     var args = List[String]("abc", "123")
#     alias validators = List[ArgValidatorFn](
#         range_args[0, 1](),
#         valid_args[List[String]("Pineapple")]()
#     )
#     var validator = match_all[validators]()
#     var results = validator(cmd, args)
#     testing.assert_equal(results.value(), "Command accepts between 0 to 1 argument(s). Received: 2.")
