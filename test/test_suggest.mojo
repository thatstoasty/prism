import testing
from prism.flag import Flag, FType
from prism.suggest import flag_from_error, jaro_distance, jaro_winkler, suggest_flag


@fieldwise_init
struct TestCase(Copyable, Movable):
    var a: String
    var b: String
    var expected: Float64


fn test_jaro_distance() raises:
    var test_cases = List[TestCase](
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
    )

    for test_case in test_cases:
        var result = jaro_distance(test_case.a, test_case.b)
        testing.assert_almost_equal(
            result,
            test_case.expected,
            String("Expected: ", test_case.expected, ", got: ", result, " for ", test_case.a, " and ", test_case.b),
        )


fn test_jaro_winkler() raises:
    var test_cases = List[TestCase](
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
    )

    for test_case in test_cases:
        var result = jaro_winkler(test_case.a, test_case.b)
        testing.assert_almost_equal(
            result,
            test_case.expected,
            String("Expected: ", test_case.expected, ", got: ", result, " for ", test_case.a, " and ", test_case.b),
        )


@fieldwise_init
struct SuggestTestCase(Copyable, Movable):
    var provided: String
    var expected: String


fn test_suggest_flag() raises:
    alias flags = List[Flag](
        Flag(name="another-flag", shorthand="b", usage="Another flag", type=FType.String),
        Flag(name="help", shorthand="h", usage="Help flag", type=FType.Bool),
        Flag(name="version", shorthand="v", usage="Version flag", type=FType.Bool),
        Flag(name="short-flag", shorthand="s", usage="Short flag", type=FType.String),
    )

    var test_cases = List[SuggestTestCase](
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
    )

    for test_case in test_cases:
        var result = suggest_flag(Span(flags), test_case.provided)
        testing.assert_equal(
            result,
            test_case.expected,
            String("Expected: ", test_case.expected, ", got: ", result, " for ", test_case.provided),
        )


fn test_flag_from_error() raises:
    var error = Error("An Error Occurred. Name: unknown")
    var result = flag_from_error(error)
    testing.assert_equal(result.value(), String("unknown"))


fn test_flag_from_error_wrong_error() raises:
    var error = Error("Some other error.")
    result = flag_from_error(error)
    testing.assert_false(Bool(result))
