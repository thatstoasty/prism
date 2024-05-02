from memory._arc import Arc
from tests.wrapper import MojoTest
from prism import CommandArc, Command
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


fn dummy(command: CommandArc, args: List[String]) -> None:
    return None


fn test_no_args():
    var test = MojoTest("Testing args.no_args")
    var cmd = Command(name="root", description="Base command.", run=dummy)
    var result = no_args(Arc(cmd), List[String]("abc"))
    test.assert_equal(result.value()[], String("The command `root` does not take any arguments."))


fn test_valid_args():
    var test = MojoTest("Testing args.valid_args")
    var cmd = Command(name="root", description="Base command.", run=dummy)
    var result = valid_args[List[String]("Pineapple")]()(Arc(cmd), List[String]("abc"))
    test.assert_equal(result.value()[], "Invalid argument: `abc`, for the command `root`.")


fn test_arbitrary_args():
    var test = MojoTest("Testing args.arbitrary_args")
    var cmd = Command(name="root", description="Base command.", run=dummy)
    var result = arbitrary_args(Arc(cmd), List[String]("abc", "blah", "blah"))

    # If the result is anything but None, fail the test.
    if result is not None:
        test.assert_false(True)


fn test_minimum_n_args():
    var test = MojoTest("Testing args.minimum_n_args")
    var cmd = Command(name="root", description="Base command.", run=dummy)
    var result = minimum_n_args[3]()(Arc(cmd), List[String]("abc", "123"))
    test.assert_equal(result.value()[], "The command `root` accepts at least 3 argument(s). Received: 2.")


fn test_maximum_n_args():
    var test = MojoTest("Testing args.maximum_n_args")
    var cmd = Command(name="root", description="Base command.", run=dummy)
    var result = maximum_n_args[1]()(Arc(cmd), List[String]("abc", "123"))
    test.assert_equal(result.value()[], "The command `root` accepts at most 1 argument(s). Received: 2.")


fn test_exact_args():
    var test = MojoTest("Testing args.exact_args")
    var cmd = Command(name="root", description="Base command.", run=dummy)
    var result = exact_args[1]()(Arc(cmd), List[String]("abc", "123"))
    test.assert_equal(result.value()[], "The command `root` accepts exactly 1 argument(s). Received: 2.")


fn test_range_args():
    var test = MojoTest("Testing args.range_args")
    var cmd = Command(name="root", description="Base command.", run=dummy)
    var result = range_args[0, 1]()(Arc(cmd), List[String]("abc", "123"))
    test.assert_equal(result.value()[], "The command `root`, accepts between 0 to 1 argument(s). Received: 2.")


# fn test_match_all():
#     var test = MojoTest("Testing args.match_all")
#     var cmd = Command(name="root", description="Base command.", run=dummy)
#     var args = List[String]("abc", "123")
#     alias validators = List[ArgValidator](
#         range_args[0, 1](),
#         valid_args[List[String]("Pineapple")]()
#     )
#     var validator = match_all[validators]()
#     var results = validator(cmd, args)
#     test.assert_equal(results.value()[], "Command accepts between 0 to 1 argument(s). Received: 2.")


fn main():
    test_no_args()
    test_valid_args()
    test_arbitrary_args()
    test_minimum_n_args()
    test_maximum_n_args()
    test_exact_args()
    test_range_args()
    # test_match_all()
