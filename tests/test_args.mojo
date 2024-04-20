from tests.wrapper import MojoTest
from prism.args import (
    no_args,
    valid_args,
    arbitrary_args,
    minimum_n_args,
    maximum_n_args,
    exact_args,
    range_args,
    match_all,
    ArgValidator,
)


fn test_no_args():
    var test = MojoTest("Testing args.no_args")
    var result = no_args(List[String]("abc"))
    test.assert_equal(result.value(), String("Command does not take any arguments."))


fn test_valid_args():
    var test = MojoTest("Testing args.valid_args")
    var result = valid_args[List[String]("Pineapple")]()(List[String]("abc"))
    test.assert_equal(result.value(), "Invalid argument abc for command.")


fn test_arbitrary_args():
    var test = MojoTest("Testing args.arbitrary_args")
    var result = arbitrary_args(List[String]("abc", "blah", "blah"))

    # If the result is anything but None, fail the test.
    if result is not None:
        test.assert_false(True)


fn test_minimum_n_args():
    var test = MojoTest("Testing args.minimum_n_args")
    var result = minimum_n_args[3]()(List[String]("abc", "123"))
    test.assert_equal(result.value(), "Command accepts at least 3 argument(s). Received: 2.")


fn test_maximum_n_args():
    var test = MojoTest("Testing args.maximum_n_args")
    var result = maximum_n_args[1]()(List[String]("abc", "123"))
    test.assert_equal(result.value(), "Command accepts at most 1 argument(s). Received: 2.")


fn test_exact_args():
    var test = MojoTest("Testing args.exact_args")
    var result = exact_args[1]()(List[String]("abc", "123"))
    test.assert_equal(result.value(), "Command accepts exactly 1 argument(s). Received: 2.")


fn test_range_args():
    var test = MojoTest("Testing args.range_args")
    var result = range_args[0, 1]()(List[String]("abc", "123"))
    test.assert_equal(result.value(), "Command accepts between 0 to 1 argument(s). Received: 2.")


# fn test_match_all():
#     var test = MojoTest("Testing args.match_all")
#     var result = match_all[List[ArgValidator](range_args[0, 1](), valid_args[List[String]("Pineapple")]())]()(List[String]("abc", "123"))
#     test.assert_equal(result.value(), "Command accepts between 0 to 1 argument(s). Received: 2.")


fn main():
    test_no_args()
    test_valid_args()
    test_arbitrary_args()
    test_minimum_n_args()
    test_maximum_n_args()
    test_exact_args()
    test_range_args()
    # test_match_all()
