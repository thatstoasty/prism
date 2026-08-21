from std import testing
from std.testing import TestSuite, assert_raises

from prism import FlagSet
from prism._flag_parser import FlagParser
from prism.flag import Flag, FType


def _flags() -> FlagSet:
    """Builds the flag set every test in this module parses against."""
    var flags: List[Flag] = [
        Flag.bool(name="verbose", shorthand="V", usage="Verbose output."),
        Flag.bool(name="quiet", shorthand="q", usage="Quiet output."),
        Flag.string(name="output", shorthand="o", usage="Output path."),
        Flag.int(name="count", shorthand="c", usage="A count."),
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
    testing.assert_equal(result.value, "-5")
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
    testing.assert_equal(result.value, "hello")
    testing.assert_equal(result.increment, 1)


def test_parse_shorthand_flag_with_space() raises:
    var args: List[String] = ["-o", "hello"]
    var parser = FlagParser(Span(args))
    var result = parser.parse_shorthand_flag(args[0], _flags())

    testing.assert_equal(len(result.names), 1)
    testing.assert_equal(result.names[0], "output")
    testing.assert_equal(result.value, "hello")
    testing.assert_equal(result.increment, 2)


def test_parse_shorthand_bool_flag() raises:
    var args: List[String] = ["-V", "positional"]
    var parser = FlagParser(Span(args))
    var result = parser.parse_shorthand_flag(args[0], _flags())

    testing.assert_equal(len(result.names), 1)
    testing.assert_equal(result.names[0], "verbose")
    testing.assert_equal(result.value, "True")
    testing.assert_equal(result.increment, 1)


def test_parse_shorthand_bool_cluster() raises:
    # `-Vq` is shorthand for `-V -q`, and both resolve to their full names.
    var args: List[String] = ["-Vq"]
    var parser = FlagParser(Span(args))
    var result = parser.parse_shorthand_flag(args[0], _flags())

    testing.assert_equal(len(result.names), 2)
    testing.assert_equal(result.names[0], "verbose")
    testing.assert_equal(result.names[1], "quiet")
    testing.assert_equal(result.value, "True")
    testing.assert_equal(result.increment, 1)


def test_parse_shorthand_mixed_cluster_raises() raises:
    # Regression: a cluster mixing a bool shorthand with a value-taking one raised internally, and
    # the handler swallowed that error without advancing the scan, looping forever. If this
    # regresses the test hangs rather than fails, so a stalled run here means this case.
    var args: List[String] = ["-Vo", "foo"]
    var parser = FlagParser(Span(args))
    with assert_raises():
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


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
