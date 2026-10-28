from std import testing
from std.testing import TestSuite, assert_raises

from prism import FlagSet
from prism._flag_parser import FlagParser
from prism.flag import Flag
from prism.opt_type import OptType


def _flags() -> FlagSet:
    """Builds the flag set every test in this module parses against."""
    var flags: List[Flag] = [
        Flag.new[Bool](name="verbose", shorthand="V", usage="Verbose output."),
        Flag.new[Bool](name="quiet", shorthand="q", usage="Quiet output."),
        Flag.new[String](name="output", shorthand="o", usage="Output path."),
        Flag.new[Int](name="count", shorthand="c", usage="A count."),
    ]
    return FlagSet(flags^)


def test_parse_flag_with_equals() raises:
    var args: List[String] = ["--output=out.txt"]
    var parser = FlagParser(Span(args))
    var result = parser.parse_flag(args[0], _flags())

    testing.assert_equal(result.name, "output")
    testing.assert_equal(result.value, "out.txt")
    testing.assert_equal(result.increment, 1)


def test_parse_flag_with_space() raises:
    var args: List[String] = ["--output", "out.txt"]
    var parser = FlagParser(Span(args))
    var result = parser.parse_flag(args[0], _flags())

    testing.assert_equal(result.name, "output")
    testing.assert_equal(result.value, "out.txt")
    # Two arguments were consumed: the name and the value.
    testing.assert_equal(result.increment, 2)


def test_parse_flag_empty_value() raises:
    var args: List[String] = ["--output="]
    var parser = FlagParser(Span(args))
    var result = parser.parse_flag(args[0], _flags())

    testing.assert_equal(result.name, "output")
    testing.assert_equal(result.value, "")
    testing.assert_equal(result.increment, 1)


def test_parse_flag_value_containing_equals() raises:
    # Only the first `=` separates the name from the value.
    var args: List[String] = ["--output=a=b=c"]
    var parser = FlagParser(Span(args))
    var result = parser.parse_flag(args[0], _flags())

    testing.assert_equal(result.name, "output")
    testing.assert_equal(result.value, "a=b=c")


def test_parse_bool_flag_takes_no_value() raises:
    var args: List[String] = ["--verbose", "positional"]
    var parser = FlagParser(Span(args))
    var result = parser.parse_flag(args[0], _flags())

    testing.assert_equal(result.name, "verbose")
    testing.assert_equal(result.value, "True")
    # A bool flag must not swallow the argument after it.
    testing.assert_equal(result.increment, 1)


def test_parse_bool_flag_with_explicit_false() raises:
    # `--verbose=false` must round-trip the literal value rather than forcing True.
    var args: List[String] = ["--verbose=false"]
    var parser = FlagParser(Span(args))
    var result = parser.parse_flag(args[0], _flags())

    testing.assert_equal(result.name, "verbose")
    testing.assert_equal(result.value, "false")


def test_parse_flag_unknown_raises() raises:
    var args: List[String] = ["--nope"]
    var parser = FlagParser(Span(args))
    with assert_raises():
        _ = parser.parse_flag(args[0], _flags())


def test_parse_flag_unknown_with_equals_raises() raises:
    var args: List[String] = ["--nope=1"]
    var parser = FlagParser(Span(args))
    with assert_raises():
        _ = parser.parse_flag(args[0], _flags())


def test_parse_flag_missing_value_raises() raises:
    var args: List[String] = ["--output"]
    var parser = FlagParser(Span(args))
    with assert_raises():
        _ = parser.parse_flag(args[0], _flags())


def test_parse_flag_negative_number_value() raises:
    # Regression: any next argument starting with `-` was rejected as "another flag", which made
    # negative numbers impossible to pass.
    var args: List[String] = ["--count", "-5"]
    var parser = FlagParser(Span(args))
    var result = parser.parse_flag(args[0], _flags())

    testing.assert_equal(result.name, "count")
    testing.assert_equal(result.value, "-5")
    testing.assert_equal(result.increment, 2)


def test_parse_shorthand_negative_number_value() raises:
    var args: List[String] = ["-c", "-5"]
    var parser = FlagParser(Span(args))
    var result = parser.parse_shorthand_flag(args[0], _flags())

    testing.assert_equal(result.names[0], "count")
    testing.assert_equal(result.values[0], "-5")
    testing.assert_equal(result.increment, 2)


def test_parse_flag_followed_by_flag_raises() raises:
    var args: List[String] = ["--output", "--verbose"]
    var parser = FlagParser(Span(args))
    with assert_raises():
        _ = parser.parse_flag(args[0], _flags())


def test_parse_shorthand_flag_with_equals() raises:
    # Regression: the separator index was used unadjusted, so the value kept its leading `=`
    # and `-o=hello` parsed as `=hello`.
    var args: List[String] = ["-o=hello"]
    var parser = FlagParser(Span(args))
    var result = parser.parse_shorthand_flag(args[0], _flags())

    testing.assert_equal(len(result.names), 1)
    testing.assert_equal(result.names[0], "output")
    testing.assert_equal(result.values[0], "hello")
    testing.assert_equal(result.increment, 1)


def test_parse_shorthand_flag_with_space() raises:
    var args: List[String] = ["-o", "hello"]
    var parser = FlagParser(Span(args))
    var result = parser.parse_shorthand_flag(args[0], _flags())

    testing.assert_equal(len(result.names), 1)
    testing.assert_equal(result.names[0], "output")
    testing.assert_equal(result.values[0], "hello")
    testing.assert_equal(result.increment, 2)


def test_parse_shorthand_bool_flag() raises:
    var args: List[String] = ["-V", "positional"]
    var parser = FlagParser(Span(args))
    var result = parser.parse_shorthand_flag(args[0], _flags())

    testing.assert_equal(len(result.names), 1)
    testing.assert_equal(result.names[0], "verbose")
    testing.assert_equal(result.values[0], "True")
    testing.assert_equal(result.increment, 1)


def test_parse_shorthand_bool_cluster() raises:
    # `-Vq` is shorthand for `-V -q`, and both resolve to their full names.
    var args: List[String] = ["-Vq"]
    var parser = FlagParser(Span(args))
    var result = parser.parse_shorthand_flag(args[0], _flags())

    testing.assert_equal(len(result.names), 2)
    testing.assert_equal(result.names[0], "verbose")
    testing.assert_equal(result.names[1], "quiet")
    testing.assert_equal(result.values[0], "True")
    testing.assert_equal(result.values[1], "True")
    testing.assert_equal(result.increment, 1)


def test_parse_shorthand_mixed_cluster() raises:
    # A cluster of bools may end in a value-taking shorthand, which takes the next argument. This
    # used to be rejected, and before that it looped forever, so a stalled run here means this case.
    var args: List[String] = ["-Vo", "foo"]
    var parser = FlagParser(Span(args))
    var result = parser.parse_shorthand_flag(args[0], _flags())

    testing.assert_equal(len(result.names), 2)
    testing.assert_equal(result.names[0], "verbose")
    testing.assert_equal(result.values[0], "True")
    testing.assert_equal(result.names[1], "output")
    testing.assert_equal(result.values[1], "foo")
    testing.assert_equal(result.increment, 2)


def test_parse_shorthand_attached_value() raises:
    # `-c5`, `-Vofoo` and `-Vo=foo` give the value in the same argument.
    var cases: List[String] = ["-c5", "-Vofoo", "-Vo=foo"]
    var expected_names: List[String] = ["count", "output", "output"]
    var expected_values: List[String] = ["5", "foo", "foo"]
    for i in range(len(cases)):
        var args: List[String] = [cases[i]]
        var parser = FlagParser(Span(args))
        var result = parser.parse_shorthand_flag(args[0], _flags())
        testing.assert_equal(result.names[len(result.names) - 1], expected_names[i])
        testing.assert_equal(result.values[len(result.values) - 1], expected_values[i])
        testing.assert_equal(result.increment, 1)


def test_parse_shorthand_bool_cluster_with_equals() raises:
    var args: List[String] = ["-qV=false"]
    var parser = FlagParser(Span(args))
    var result = parser.parse_shorthand_flag(args[0], _flags())

    testing.assert_equal(result.values[0], "True")
    testing.assert_equal(result.values[1], "false")


def test_parse_shorthand_unknown_is_reported_as_unknown_flag() raises:
    # Unknown shorthands use the same error as unknown long flags, so they get suggestions.
    var args: List[String] = ["-Vz"]
    var parser = FlagParser(Span(args))
    with assert_raises(contains="Command does not accept the flag supplied. Name: z"):
        _ = parser.parse_shorthand_flag(args[0], _flags())


def test_parse_shorthand_unknown_raises() raises:
    var args: List[String] = ["-z"]
    var parser = FlagParser(Span(args))
    with assert_raises():
        _ = parser.parse_shorthand_flag(args[0], _flags())


def test_parse_shorthand_unknown_with_equals_raises() raises:
    var args: List[String] = ["-z=1"]
    var parser = FlagParser(Span(args))
    with assert_raises():
        _ = parser.parse_shorthand_flag(args[0], _flags())


def test_parse_shorthand_missing_value_raises() raises:
    var args: List[String] = ["-o"]
    var parser = FlagParser(Span(args))
    with assert_raises():
        _ = parser.parse_shorthand_flag(args[0], _flags())


def test_parse_shorthand_followed_by_flag_raises() raises:
    var args: List[String] = ["-o", "-V"]
    var parser = FlagParser(Span(args))
    with assert_raises():
        _ = parser.parse_shorthand_flag(args[0], _flags())


def test_parse_shorthand_cluster_with_multi_character_shorthands() raises:
    # Each position matches the longest shorthand defined there, so `-r0vvas` is `-r0 -vv -a -s`.
    var flags: List[Flag] = [
        Flag.new[Bool](name="required", shorthand="r0", usage="R."),
        Flag.new[Bool](name="verbose", shorthand="vv", usage="V."),
        Flag.new[Bool](name="auto", shorthand="a", usage="A."),
        Flag.new[Bool](name="secure", shorthand="s", usage="S."),
        Flag.new[String](name="host", shorthand="hl", usage="H."),
    ]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["-r0vvas"]
    var parser = FlagParser(Span(args))
    var result = parser.parse_shorthand_flag(args[0], flag_set)

    var expected: List[String] = ["required", "verbose", "auto", "secure"]
    testing.assert_equal(result.names, expected)

    var value_args: List[String] = ["-ahllocalhost"]
    var value_parser = FlagParser(Span(value_args))
    var value_result = value_parser.parse_shorthand_flag(value_args[0], flag_set)
    testing.assert_equal(value_result.names[1], "host")
    testing.assert_equal(value_result.values[1], "localhost")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
