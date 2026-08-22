from std import testing
from std.memory import ArcPointer
from prism.args import (  # match_all,
    arbitrary_args,
    exact_args,
    maximum_n_args,
    minimum_n_args,
    no_args,
    range_args,
    match_all,
)
from std.testing import TestSuite, assert_raises

from prism import Arg, ArgSet, Command, FlagSet


def dummy(args: ArgSet, flags: FlagSet) -> None:
    return None


def test_no_args() raises:
    with testing.assert_raises(contains="does not take any arguments."):
        no_args(
            args=["abc"]
        )


def test_arbitrary_args() raises:
    # It should not raise an error, ever.
    arbitrary_args(args=["abc", "blah", "blah"])


def test_minimum_n_args() raises:
    with testing.assert_raises(contains="accepts at least 3 argument(s). Received: 2"):
        minimum_n_args[3]()(args=["abc", "123"])


def test_maximum_n_args() raises:
    with testing.assert_raises(contains="accepts at most 1 argument(s). Received: 2"):
        maximum_n_args[1]()(args=["abc", "123"])


def test_exact_args() raises:
    with testing.assert_raises(contains="accepts exactly 1 argument(s). Received: 2"):
        exact_args[1]()(args=["abc", "123"])


def test_range_args() raises:
    with testing.assert_raises(contains="accepts between 0 to 1 argument(s). Received: 2"):
        range_args[0, 1]()(args=["abc", "123"])


# def test_match_all() raises:
#     with testing.assert_raises(contains="accepts between 0 to 1 argument(s). Received: 2"):
#         match_all[range_args[0, 1](), exact_args[1]()]()(args=["abc", "123"])


def _bound(var args: List[Arg], var values: List[String]) raises -> ArgSet:
    """Builds an argument set and binds `values` to it."""
    var arg_set = ArgSet(args^)
    arg_set.bind(values^)
    return arg_set^


def test_named_args_bind_positionally() raises:
    var args: List[Arg] = [
        Arg.new[String](name="target", usage="Where."),
        Arg.new[Int](name="replicas", usage="How many."),
    ]
    var values: List[String] = ["prod", "3"]
    var bound = _bound(args^, values^)

    testing.assert_equal(bound.get[String]("target").value(), "prod")
    testing.assert_equal(bound.get[Int]("replicas").value(), 3)
    # Positional access still works, so existing command bodies keep compiling.
    testing.assert_equal(len(bound), 2)
    testing.assert_equal(bound[0], "prod")


def test_named_args_use_defaults_when_omitted() raises:
    var args: List[Arg] = [
        Arg.new[String](name="target", usage="Where."),
        Arg.new[Float64](name="ratio", usage="Ratio.", default=Optional[Float64](1.0)),
    ]
    var values: List[String] = ["prod"]
    var bound = _bound(args^, values^)

    testing.assert_equal(bound.get[Float64]("ratio").value(), 1.0)


def test_named_args_reject_missing_required() raises:
    var args: List[Arg] = [
        Arg.new[String](name="target", usage="Where."),
        Arg.new[Int](name="replicas", usage="How many."),
    ]
    var values: List[String] = ["prod"]
    with assert_raises():
        _ = _bound(args^, values^)


def test_named_args_reject_extra() raises:
    var args: List[Arg] = [Arg.new[String](name="target", usage="Where.")]
    var values: List[String] = ["prod", "extra"]
    with assert_raises():
        _ = _bound(args^, values^)


def test_named_args_reject_wrong_type() raises:
    # Binding validates eagerly, so a mistyped argument is reported before `run` is called rather
    # than surfacing partway through it.
    var args: List[Arg] = [Arg.new[Int](name="replicas", usage="How many.")]
    var values: List[String] = ["many"]
    with assert_raises():
        _ = _bound(args^, values^)


def test_undeclared_args_are_permissive() raises:
    # A command that declares nothing accepts anything, which is what leaves `arg_validator` in
    # charge for commands that check their own arguments.
    var args = List[Arg]()
    var values: List[String] = ["a", "b", "c"]
    var bound = _bound(args^, values^)

    testing.assert_equal(len(bound), 3)
    testing.assert_false(Bool(bound.get[String]("nope")), "no argument is declared under that name")


def test_named_args_usage_line() raises:
    var args: List[Arg] = [
        Arg.new[String](name="target", usage="Where."),
        Arg.new[Int](name="replicas", usage="How many.", default=Optional[Int](1)),
    ]
    testing.assert_equal(ArgSet(args^).usage(), "TARGET [REPLICAS]")


def test_named_args_reject_invalid_value() raises:
    # `Arg.valid_values` replaces the command-level `valid_args` list and the validator that read
    # it, so the constraint now belongs to the argument it constrains.
    var args: List[Arg] = [
        Arg.new[String](name="env", usage="Environment.", valid_values=["staging", "production"])
    ]
    var values: List[String] = ["dev"]
    with assert_raises():
        _ = _bound(args^, values^)


def test_named_args_accept_a_valid_value() raises:
    var args: List[Arg] = [
        Arg.new[String](name="env", usage="Environment.", valid_values=["staging", "production"])
    ]
    var values: List[String] = ["staging"]
    var bound = _bound(args^, values^)

    testing.assert_equal(bound.get[String]("env").value(), "staging")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
