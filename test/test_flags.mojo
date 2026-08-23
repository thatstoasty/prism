from std import testing
from prism.flag import Flag
from prism.opt_type import OptType
from prism.value import FromValue, ToValue
from std.testing import TestSuite, assert_raises

from prism import ArgSet, Command, FlagSet, Version


def dummy(args: ArgSet, flags: FlagSet) -> None:
    return None


def test_gets() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.new[String](name="key", usage="usage"),
            Flag.new[Bool](name="flag", usage="usage"),
        ],
    )

    var args: List[String] = ["--key=value", "positional", "--flag"]
    _ = cmd.flags.from_args(args)
    testing.assert_equal(cmd.flags.get[String]("key").value(), "value")
    testing.assert_equal(cmd.flags.get[Bool]("flag").value(), True)


def test_parse() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.new[String](name="key", usage="usage"),
            Flag.new[Bool](name="flag", usage="usage"),
        ],
    )
    var args: List[String] = ["--key=value"]
    remaining_args = cmd.flags.from_args(args)
    testing.assert_equal(len(remaining_args), 0)


def test_unicode_flag_name() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.new[String](name="cléf", usage="usage"),
        ],
    )

    var args: List[String] = ["--cléf=valeur", "positional"]
    _ = cmd.flags.from_args(args)
    testing.assert_equal(cmd.flags.get[String]("cléf").value(), "valeur")


def test_new_records_the_parametrized_type() raises:
    # Regression: `Flag.new[T]` computed `opt_type` from `T` and then passed `OptType.String`
    # anyway, so every flag it built was declared a String. `--help` became a flag that wanted a
    # value, and nothing caught it because no test asserted the type `new` produces.
    testing.assert_equal(Flag.new[Bool](name="b", usage="u").type.value, OptType.Bool.value)
    testing.assert_equal(Flag.new[String](name="s", usage="u").type.value, OptType.String.value)
    testing.assert_equal(Flag.new[Int](name="i", usage="u").type.value, OptType.Int.value)
    testing.assert_equal(Flag.new[UInt8](name="u8", usage="u").type.value, OptType.UInt8.value)
    testing.assert_equal(Flag.new[Float64](name="f", usage="u").type.value, OptType.Float64.value)


def test_help_and_version_flags_are_bool() raises:
    # These two are the ones a user hits first, and both are built through `Flag.new[Bool]`.
    var cmd = Command(name="app", usage="Base command.", run=dummy, version=Version("1.0.0"))

    testing.assert_equal(cmd.flags.lookup("help").value()[].type.value, OptType.Bool.value)
    testing.assert_equal(cmd.flags.lookup("version").value()[].type.value, OptType.Bool.value)


@fieldwise_init
struct _Alpha(FromValue, ToValue, ImplicitlyCopyable, Movable):
    """A user-defined flag type, for checking that two of them stay distinct."""

    var v: Int

    @staticmethod
    def from_value(value: StringSpan) raises -> Self:
        return Self(atol(value))

    def to_value(self) -> String:
        return String(self.v)


@fieldwise_init
struct _Beta(FromValue, ToValue, ImplicitlyCopyable, Movable):
    """A second user-defined flag type, unrelated to `_Alpha`."""

    var v: Int

    @staticmethod
    def from_value(value: StringSpan) raises -> Self:
        return Self(atol(value))

    def to_value(self) -> String:
        return String(self.v)


def test_custom_types_do_not_collide() raises:
    # Regression: every user-defined type mapped to the single `OptType.Custom` value, so the
    # type-checked lookup in `get` could not tell them apart. Reading an `_Alpha` flag as a `_Beta`
    # matched and reinterpreted the text instead of reading as None.
    var flags: List[Flag] = [Flag.new[_Alpha](name="alpha", usage="An Alpha.")]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["--alpha", "5"]
    _ = flag_set.from_args(Span(args))

    testing.assert_equal(flag_set.get[_Alpha]("alpha").value().v, 5)
    testing.assert_false(
        Bool(flag_set.get[_Beta]("alpha")), "an unrelated custom type should not match"
    )


def test_custom_type_is_reported_as_custom() raises:
    var flag = Flag.new[_Alpha](name="alpha", usage="An Alpha.")

    # `== OptType.Custom` does not hold, because the name distinguishes it.
    testing.assert_true(flag.type.is_custom_type(), "should report as a custom type")
    testing.assert_false(flag.type == OptType.Custom, "carries its own name, so it is not equal")
    testing.assert_false(Flag.new[Int](name="i", usage="u").type.is_custom_type())


def test_narrow_int_rejects_out_of_range() raises:
    # Regression: `Scalar[dtype](atol(value))` narrowed silently, so `--n 999` on an Int8 flag
    # became -25 and the command ran on corrupt data.
    var flags: List[Flag] = [Flag.new[Int8](name="n", usage="A small number.")]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["--n", "999"]
    _ = flag_set.from_args(Span(args))

    with assert_raises():
        _ = flag_set.get[Int8]("n")


def test_unsigned_rejects_negative() raises:
    var flags: List[Flag] = [Flag.new[UInt8](name="u", usage="An unsigned number.")]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["--u", "-5"]
    _ = flag_set.from_args(Span(args))

    with assert_raises():
        _ = flag_set.get[UInt8]("u")


def test_widest_unsigned_accepts_zero() raises:
    # The range check compares in a width that holds the bound: `UInt64.MAX` does not fit in a
    # signed Int, and converting it wrapped to -1, which rejected every value including 0.
    var flags: List[Flag] = [
        Flag.new[UInt64](name="a", usage="u"),
        Flag.new[UInt](name="b", usage="u"),
        Flag.new[Int64](name="c", usage="u"),
    ]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["--a", "0", "--b", "7", "--c", "-9"]
    _ = flag_set.from_args(Span(args))

    testing.assert_equal(flag_set.get[UInt64]("a").value(), UInt64(0))
    testing.assert_equal(flag_set.get[UInt]("b").value(), UInt(7))
    testing.assert_equal(flag_set.get[Int64]("c").value(), Int64(-9))


def test_in_range_narrow_int_still_works() raises:
    var flags: List[Flag] = [Flag.new[Int8](name="n", usage="u")]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["--n", "-128"]
    _ = flag_set.from_args(Span(args))

    testing.assert_equal(flag_set.get[Int8]("n").value(), Int8(-128))


def test_list_element_types_do_not_collide() raises:
    # Regression: every list collapsed to one `OptType.List`, so a lookup for `List[Int]` matched a
    # `List[String]` flag and then threw a raw parse error instead of reading as None.
    var flags: List[Flag] = [Flag.new[List[String]](name="tags", usage="Tags.")]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["--tags", "a", "--tags", "b"]
    _ = flag_set.from_args(Span(args))

    testing.assert_equal(len(flag_set.get[List[String]]("tags").value()), 2)
    testing.assert_false(
        Bool(flag_set.get[List[Int]]("tags")), "a list of a different element type should not match"
    )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
