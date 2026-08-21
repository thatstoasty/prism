from std import testing
from prism.flag import Flag, FType
from prism.suggest import flag_from_error, jaro_distance, jaro_winkler, suggest_flag, suggest_name
from prism._util import UNKNOWN_FLAG_ERROR
from std.testing import TestSuite


@fieldwise_init
struct TestCase(ImplicitlyCopyable, Movable):
    var a: String
    var b: String
    var expected: Float64


def test_jaro_distance() raises:
    var test_cases: List[TestCase] = [
        TestCase(
            a="",
            b="",
            expected=1.0,
        ),
        TestCase(
            a="a",
            b="",
            expected=0.0,
        ),
        TestCase(
            a="",
            b="a",
            expected=0.0,
        ),
        TestCase(
            a="MARTHA",
            b="MARHTA",
            expected=0.9444444444,
        ),
        TestCase(
            a="DIXON",
            b="DICKSONX",
            expected=0.7666666667,
        ),
        TestCase(
            a="JELLYFISH",
            b="SMELLYFISH",
            expected=0.8962962963,
        ),
        TestCase(
            a="café",
            b="cafe",
            expected=0.8333333333,
        ),
    ]

    for test_case in test_cases:
        var result = jaro_distance(test_case.a, test_case.b)
        testing.assert_almost_equal(
            result,
            test_case.expected,
            String("Expected: ", test_case.expected, ", got: ", result, " for ", test_case.a, " and ", test_case.b),
        )


def test_jaro_winkler() raises:
    var test_cases: List[TestCase] = [
        TestCase(
            a="",
            b="",
            expected=1.0,
        ),
        TestCase(
            a="a",
            b="",
            expected=0.0,
        ),
        TestCase(
            a="",
            b="a",
            expected=0.0,
        ),
        TestCase(
            a="a",
            b="a",
            expected=1.0,
        ),
        TestCase(
            a="a",
            b="b",
            expected=0.0,
        ),
        TestCase(
            a="aa",
            b="aa",
            expected=1.0,
        ),
        TestCase(
            a="aa",
            b="bb",
            expected=0.0,
        ),
        TestCase(
            a="aaa",
            b="aaa",
            expected=1.0,
        ),
        TestCase(
            a="aa",
            b="ab",
            expected=0.6666666666666666,
        ),
        TestCase(
            a="aa",
            b="ba",
            expected=0.6666666666666666,
        ),
        TestCase(
            a="ba",
            b="aa",
            expected=0.6666666666666666,
        ),
        TestCase(
            a="ab",
            b="aa",
            expected=0.6666666666666666,
        ),
        TestCase(
            a="café",
            b="cafe",
            expected=0.8833333333,
        ),
    ]

    for test_case in test_cases:
        var result = jaro_winkler(test_case.a, test_case.b)
        testing.assert_almost_equal(
            result,
            test_case.expected,
            String("Expected: ", test_case.expected, ", got: ", result, " for ", test_case.a, " and ", test_case.b),
        )


@fieldwise_init
struct SuggestTestCase(ImplicitlyCopyable, Movable):
    var provided: String
    var expected: String


def test_suggest_flag() raises:
    var flags: List[Flag] = [
        Flag(name="another-flag", shorthand="b", usage="Another flag", type=FType.String),
        Flag(name="help", shorthand="h", usage="Help flag", type=FType.Bool),
        Flag(name="version", shorthand="v", usage="Version flag", type=FType.Bool),
        Flag(name="short-flag", shorthand="s", usage="Short flag", type=FType.String),
    ]

    var test_cases: List[SuggestTestCase] = [
        SuggestTestCase(
            provided="",
            expected="",
        ),
        SuggestTestCase(
            provided="a",
            expected="--another-flag",
        ),
        SuggestTestCase(
            provided="hlp",
            expected="--help",
        ),
        SuggestTestCase(
            provided="k",
            expected="",
        ),
        SuggestTestCase(
            provided="s",
            expected="-s",
        ),
    ]

    for test_case in test_cases:
        var result = suggest_flag(Span(flags), test_case.provided)
        testing.assert_equal(
            result,
            test_case.expected,
            String("Expected: ", test_case.expected, ", got: ", result, " for ", test_case.provided),
        )


def test_flag_from_error() raises:
    var error = Error(UNKNOWN_FLAG_ERROR, "unknown")
    var result = flag_from_error(error)
    testing.assert_equal(result.value(), "unknown")


def test_flag_from_error_wrong_error() raises:
    var error = Error("Some other error.")
    result = flag_from_error(error)
    testing.assert_false(Bool(result))


def test_flag_from_error_ignores_other_errors_naming_a_flag() raises:
    # Regression: this matched on a bare "Name: ", so errors that merely mention a flag name were
    # mistaken for unknown-flag errors and their precise message was replaced by a "did you mean".
    var error = Error("Flag requires a value to be set but reached the end of arguments. Name: output")
    testing.assert_false(Bool(flag_from_error(error)))

    var other = Error("Flag requires a value to be set but found another flag instead. Name: output")
    testing.assert_false(Bool(flag_from_error(other)))


def test_suggest_below_threshold_returns_nothing() raises:
    # Regression: a weak partial match was still offered. Against a command whose only flag is
    # `--help`, `--verbos` scores 0.47 and used to be answered with "did you mean --help?".
    var flags: List[Flag] = [Flag(name="help", shorthand="h", usage="Help.", type=FType.Bool)]
    testing.assert_equal(suggest_flag(Span(flags), "verbos"), "")

    var candidates: List[String] = ["status"]
    testing.assert_equal(suggest_name(Span(candidates), "xyzabc"), "")


def test_suggest_name() raises:
    var candidates: List[String] = ["status", "deploy", "rollback"]
    testing.assert_equal(suggest_name(Span(candidates), "sttaus"), "status")
    testing.assert_equal(suggest_name(Span(candidates), "rolback"), "rollback")
    # Nothing in common with any candidate yields no suggestion rather than an arbitrary one.
    testing.assert_equal(suggest_name(Span(candidates), "zzzzz"), "")


def test_suggest_flag_ignores_shorthands_for_multi_character_input() raises:
    # Regression: a one-character shorthand scores spuriously high against any longer string
    # containing that character, so `count` used to be answered with `-o`.
    var flags: List[Flag] = [
        Flag(name="output", shorthand="o", usage="Output.", type=FType.String),
        Flag(name="verbose", shorthand="V", usage="Verbose.", type=FType.Bool),
    ]
    testing.assert_not_equal(suggest_flag(Span(flags), "count"), "-o")
    # A single character the user typed can still match a shorthand.
    testing.assert_equal(suggest_flag(Span(flags), "o"), "-o")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
