from std import os, testing
from std.tempfile import gettempdir
from prism.flag import Flag
from prism.opt_type import OptType
from prism.value import FromValue, ToValue
from std.testing import TestSuite, assert_raises

from prism import ArgSet, Command, FlagSet, Version

from prism.suggest import flag_from_error, suggest_flag


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
    var remaining_args = cmd.flags.from_args(args)
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


def test_repeated_list_flag_keeps_each_value_whole() raises:
    # Regression: repeated values were joined and split on spaces, so curl-style headers
    # `-H "A: 1" -H "B: 2"` read back as ["A:", "1", "B:", "2"].
    var flags: List[Flag] = [Flag.new[List[String]](name="header", shorthand="H", usage="Headers.")]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["-H", "A: 1", "--header", "B: 2", "-H=C: 3"]
    _ = flag_set.from_args(Span(args))

    var expected: List[String] = ["A: 1", "B: 2", "C: 3"]
    testing.assert_equal(flag_set.get[List[String]]("header").value(), expected)


def test_flag_values_are_checked_against_their_type() raises:
    # Regression: `--port abc` parsed cleanly and only failed inside `run`, when the handler read
    # it, after the pre-run hooks had already run, and without naming the flag.
    var flags: List[Flag] = [
        Flag.new[Int](name="port", usage="Port."),
        Flag.new[List[Int]](name="nums", usage="Numbers."),
    ]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["--port", "abc"]
    _ = flag_set.from_args(Span(args))
    with assert_raises(contains="--port"):
        flag_set.validate_flag_values()

    var list_flags: List[Flag] = [Flag.new[List[Int]](name="nums", usage="Numbers.")]
    var list_set = FlagSet(list_flags^)
    var list_args: List[String] = ["--nums", "1", "--nums", "x"]
    _ = list_set.from_args(Span(list_args))
    with assert_raises(contains="--nums"):
        list_set.validate_flag_values()


def test_valid_flag_values_pass_the_check() raises:
    var flags: List[Flag] = [Flag.new[Int](name="port", usage="Port."), Flag.new[String](name="name", usage="Name.")]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["--port", "8080", "--name", "x"]
    _ = flag_set.from_args(Span(args))
    flag_set.validate_flag_values()


def test_empty_list_default_reads_as_an_empty_list() raises:
    # Regression: an empty list rendered as "", which split back into one empty element, so the
    # default read as `[""]`, or failed to parse for a list of numbers.
    var flags: List[Flag] = [
        Flag.new[List[String]](name="tags", usage="Tags.", default=List[String]()),
        Flag.new[List[Int]](name="nums", usage="Numbers.", default=List[Int]()),
    ]
    var flag_set = FlagSet(flags^)
    testing.assert_equal(len(flag_set.get[List[String]]("tags").value()), 0)
    testing.assert_equal(len(flag_set.get[List[Int]]("nums").value()), 0)


def test_dash_and_negative_numbers_are_values() raises:
    # Regression: anything starting with `-` went to the shorthand parser, so `-` (stdin) and `-5`
    # could not be positional arguments, and `--out -` was rejected as a missing value.
    var flags: List[Flag] = [
        Flag.new[String](name="out", shorthand="o", usage="Output."),
        Flag.new[Int](name="num", shorthand="n", usage="Number."),
    ]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["-", "-5", "--out", "-", "-n", "-3"]
    var remaining = flag_set.from_args(Span(args))

    var expected: List[String] = ["-", "-5"]
    testing.assert_equal(remaining, expected)
    testing.assert_equal(flag_set.get[String]("out").value(), "-")
    testing.assert_equal(flag_set.get[Int]("num").value(), -3)


def test_digit_shorthand_wins_over_negative_number() raises:
    var flags: List[Flag] = [Flag.new[Bool](name="five", shorthand="5", usage="Five.")]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["-5"]
    var remaining = flag_set.from_args(Span(args))

    testing.assert_equal(len(remaining), 0)
    testing.assert_true(flag_set.get[Bool]("five").value())


def _temp_path(name: StringSpan) raises -> String:
    return os.path.join(gettempdir().value(), String("prism_test_", name))


def test_file_value_drops_trailing_newline() raises:
    # Regression: the file's trailing newline was kept, so a token file read as "secret\n".
    var path = _temp_path("token")
    with open(path, "w") as f:
        f.write("secret\n")

    var flags: List[Flag] = [Flag.new[String](name="token", usage="Token.", file_path=path)]
    var flag_set = FlagSet(flags^)
    _ = flag_set.from_args(Span(List[String]()))
    os.remove(path)

    testing.assert_equal(flag_set.get[String]("token").value(), "secret")


def test_missing_file_leaves_flag_unset() raises:
    # Regression: a missing file aborted the command, even for an optional flag.
    var flags: List[Flag] = [
        Flag.new[String](name="token", usage="Token.", file_path=_temp_path("does_not_exist"))
    ]
    var flag_set = FlagSet(flags^)
    _ = flag_set.from_args(Span(List[String]()))

    testing.assert_false(Bool(flag_set.get[String]("token")))


def test_unset_environment_variable_falls_back_to_file() raises:
    # Regression: a flag with an environment variable never read its file, even when the
    # variable was unset.
    var path = _temp_path("fallback")
    with open(path, "w") as f:
        f.write("from-file")

    var flags: List[Flag] = [
        Flag.new[String](
            name="token",
            usage="Token.",
            environment_variable=String("PRISM_TEST_UNSET_VARIABLE"),
            file_path=path,
        )
    ]
    var flag_set = FlagSet(flags^)
    _ = flag_set.from_args(Span(List[String]()))
    os.remove(path)

    testing.assert_equal(flag_set.get[String]("token").value(), "from-file")


def test_unknown_shorthand_gets_a_suggestion() raises:
    # Unknown shorthands now raise the same error as unknown long flags, which is what the
    # suggestion lookup keys off.
    var flags: List[Flag] = [Flag.new[Bool](name="verbose", shorthand="v", usage="Verbose.")]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["-V"]
    try:
        _ = flag_set.from_args(Span(args))
        testing.assert_true(False, "expected an unknown flag error")
    except e:
        var name = flag_from_error(e)
        testing.assert_equal(name.value(), "V")
        testing.assert_equal(suggest_flag(flag_set.flags, name.value()), "-v")


def test_value_separator_splits_environment_values() raises:
    _ = os.setenv("PRISM_TEST_TAGS", "a,b,,c")
    var flags: List[Flag] = [
        Flag.new[List[String], value_separator=","](
            name="tags", usage="Tags.", environment_variable=String("PRISM_TEST_TAGS")
        )
    ]
    var flag_set = FlagSet(flags^)
    _ = flag_set.from_args(Span(List[String]()))
    _ = os.unsetenv("PRISM_TEST_TAGS")

    var expected: List[String] = ["a", "b", "c"]
    testing.assert_equal(flag_set.get[List[String]]("tags").value(), expected)


def test_value_separator_splits_file_lines() raises:
    # One element per line, with blank lines, a trailing newline and Windows line endings dropped.
    var path = _temp_path("lines")
    with open(path, "w") as f:
        f.write("A: 1\r\n\nB: 2\n")

    var flags: List[Flag] = [
        Flag.new[List[String], value_separator="\n"](name="header", usage="Headers.", file_path=path)
    ]
    var flag_set = FlagSet(flags^)
    _ = flag_set.from_args(Span(List[String]()))
    os.remove(path)

    var expected: List[String] = ["A: 1", "B: 2"]
    testing.assert_equal(flag_set.get[List[String]]("header").value(), expected)


def test_list_from_environment_without_separator_is_one_element() raises:
    _ = os.setenv("PRISM_TEST_TAGS_WHOLE", "a,b")
    var flags: List[Flag] = [
        Flag.new[List[String]](name="tags", usage="Tags.", environment_variable=String("PRISM_TEST_TAGS_WHOLE"))
    ]
    var flag_set = FlagSet(flags^)
    _ = flag_set.from_args(Span(List[String]()))
    _ = os.unsetenv("PRISM_TEST_TAGS_WHOLE")

    var expected: List[String] = ["a,b"]
    testing.assert_equal(flag_set.get[List[String]]("tags").value(), expected)


def test_value_separator_does_not_split_command_line_values() raises:
    var flags: List[Flag] = [Flag.new[List[String], value_separator=","](name="tags", usage="Tags.")]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["--tags", "a,b"]
    _ = flag_set.from_args(Span(args))

    var expected: List[String] = ["a,b"]
    testing.assert_equal(flag_set.get[List[String]]("tags").value(), expected)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
