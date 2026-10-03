from std import testing
from prism.value import FromValue, ToValue
from std.memory import ArcPointer
from prism.args import (
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
from prism.arg import _argument_order_problem
from prism.opt_type import OptType

import prism


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


def test_match_all() raises:
    var validator = match_all[range_args[0, 1](), exact_args[1]()]()
    validator(["abc"])
    with testing.assert_raises(contains="accepts between 0 to 1 argument(s). Received: 2"):
        validator(["abc", "123"])
    with testing.assert_raises(contains="accepts exactly 1 argument(s). Received: 0"):
        validator([])


def test_match_all_is_exported() raises:
    # Regression: the README documents `match_all`, but the package did not export it.
    _ = prism.match_all[no_args]()


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


@fieldwise_init
struct _Tag(FromValue, ToValue, ImplicitlyCopyable, Movable, Writable):
    """A custom argument type whose display differs from its wire form."""

    var v: String

    @staticmethod
    def from_value(value: StringSpan) raises -> Self:
        if not value.startswith("#"):
            raise Error(t"Tag must start with '#': {value}")
        return Self(String(value))

    def to_value(self) -> String:
        return self.v.copy()

    def write_to(self, mut writer: Some[Writer]) -> None:
        writer.write("Tag<", self.v, ">")


def test_custom_typed_arg_is_validated_at_bind() raises:
    # Regression: binding switched on the runtime OptType, which cannot name a user-defined type,
    # so custom and list arguments were never checked. The failure surfaced later inside `get`,
    # from the command's own `run`, rather than being reported before it started.
    var args: List[Arg] = [Arg.new[_Tag](name="tag", usage="A tag.")]
    var values: List[String] = ["nope"]

    with assert_raises():
        _ = _bound(args^, values^)


def test_custom_typed_arg_accepts_a_valid_value() raises:
    var args: List[Arg] = [Arg.new[_Tag](name="tag", usage="A tag.")]
    var values: List[String] = ["#release"]
    var bound = _bound(args^, values^)

    testing.assert_equal(bound.get[_Tag]("tag").value().v, "#release")


def test_list_round_trips_through_to_value() raises:
    # Regression: `List.to_value` rendered elements with `Writable` while `from_value` parses them
    # with `FromValue`, so a type whose display differs from its wire form did not survive.
    var tags: List[_Tag] = [_Tag("#a"), _Tag("#b")]
    var rendered = tags.to_value()
    testing.assert_equal(rendered, "#a\0#b")

    var back = List[_Tag].from_value(rendered)
    testing.assert_equal(len(back), 2)
    testing.assert_equal(back[1].v, "#b")


def test_last_list_argument_is_variadic() raises:
    # A list argument declared last takes every remaining value, so `cp DEST FILES...` works.
    var args: List[Arg] = [
        Arg.new[String](name="dest", usage="Where."),
        Arg.new[List[String]](name="files", usage="Files.", required=False),
    ]
    var values: List[String] = ["out", "a", "b c", "d"]
    var bound = _bound(args^, values^)

    var expected: List[String] = ["a", "b c", "d"]
    testing.assert_equal(bound.get[String]("dest").value(), "out")
    testing.assert_equal(bound.get[List[String]]("files").value(), expected)
    testing.assert_equal(bound.usage(), "DEST [FILES]...")


def test_variadic_argument_checks_each_value() raises:
    var args: List[Arg] = [Arg.new[List[Int]](name="nums", usage="Numbers.")]
    var values: List[String] = ["1", "x"]
    with assert_raises(contains="Invalid value for argument `nums`"):
        _ = _bound(args^, values^)

    var shells: List[Arg] = [Arg.new[List[String]](name="shells", usage="Shells.", valid_values=["zsh", "bash"])]
    var shell_values: List[String] = ["zsh", "fish"]
    with assert_raises(contains="`fish`"):
        _ = _bound(shells^, shell_values^)


def test_argument_order_accepts_a_trailing_list() raises:
    var args: List[Arg] = [
        Arg.new[String](name="dest", usage="Where."),
        Arg.new[List[String]](name="files", usage="Files.", required=False),
    ]
    testing.assert_false(Bool(_argument_order_problem(args)))


def test_argument_order_rejects_a_list_before_another_argument() raises:
    # A list argument takes every remaining value, so one declared mid-list quietly took a single
    # value instead.
    var args: List[Arg] = [
        Arg.new[List[String]](name="files", usage="Files."),
        Arg.new[String](name="dest", usage="Where."),
    ]
    var problem = _argument_order_problem(args)
    testing.assert_true("The list argument `files` is declared before `dest`" in problem.value())

    var values: List[String] = ["a", "b"]
    with assert_raises(contains="must be declared last"):
        _ = _bound(args^, values^)


def test_argument_order_rejects_required_after_optional() raises:
    var args: List[Arg] = [
        Arg.new[String](name="first", usage="First.", default=String("x")),
        Arg.new[String](name="second", usage="Second."),
    ]
    var problem = _argument_order_problem(args)
    testing.assert_true("The required argument `second`" in problem.value())


def test_list_argument_takes_element_valid_values() raises:
    # `valid_values` for a list argument may name its elements directly, rather than as a list of
    # lists, which is what `T`'s own type would call for.
    var args: List[Arg] = [Arg.new[List[String]](name="shells", usage="Shells.", valid_values=["zsh", "bash"])]
    testing.assert_true(args[0].type.is_list_type())
    var expected_valid: List[String] = ["zsh", "bash"]
    testing.assert_equal(args[0].valid_values, expected_valid)

    var values: List[String] = ["bash", "zsh"]
    var bound = _bound(args^, values^)
    var expected: List[String] = ["bash", "zsh"]
    testing.assert_equal(bound.get[List[String]]("shells").value(), expected)


def test_nested_list_valid_values_are_flattened() raises:
    # Regression: `Arg.new[List[String]]` stored each valid value as one joined list, which no
    # element could match, so `valid_values=[["zsh", "bash"]]` rejected both shells.
    var nested: List[List[String]] = [["zsh", "bash"]]
    var args: List[Arg] = [Arg.new[List[String]](name="shells", usage="Shells.", valid_values=nested^)]
    var expected: List[String] = ["zsh", "bash"]
    testing.assert_equal(args[0].valid_values, expected)

    var values: List[String] = ["bash"]
    _ = _bound(args^, values^)


def test_arg_set_require() raises:
    var args: List[Arg] = [
        Arg.new[String](name="target", usage="Where."),
        Arg.new[Int](name="replicas", usage="How many.", default=Optional[Int](3)),
    ]
    var values: List[String] = ["prod"]
    var bound = _bound(args^, values^)

    testing.assert_equal(bound.require[String]("target"), "prod")
    testing.assert_equal(bound.require[Int]("replicas"), 3)
    with testing.assert_raises(contains="No argument named `traget` is declared. Did you mean `target`?"):
        _ = bound.require[String]("traget")


def test_arg_set_require_reports_an_omitted_argument() raises:
    var args: List[Arg] = [Arg.new[String](name="extra", usage="Extra.", required=False)]
    var bound = _bound(args^, List[String]())

    with testing.assert_raises(contains="Argument `extra` was not given and has no default."):
        _ = bound.require[String]("extra")


def test_valid_values_for_other_types_are_unchanged() raises:
    # Scalars, and numeric lists given as elements, render the same as before.
    var env = Arg.new[String](name="env", usage="Env.", valid_values=["staging", "production"])
    var expected_env: List[String] = ["staging", "production"]
    testing.assert_equal(env.valid_values, expected_env)

    var nums = Arg.new[List[Int]](name="nums", usage="Numbers.", valid_values=[1, 2])
    var expected_nums: List[String] = ["1", "2"]
    testing.assert_equal(nums.valid_values, expected_nums)

    var ratio = Arg.new(name="ratio", usage="Ratio.", default=Optional[Float64](1.0))
    testing.assert_equal(ratio.type, OptType.Float64)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
