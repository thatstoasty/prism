from std import testing
from prism._util import string_to_bool
from prism._arg_parse import parse_args_from_stdin
from std.testing import TestSuite, assert_raises


def test_string_to_bool() raises:
    var truthy: List[String] = ["1", "t", "T", "true", "True", "TRUE"]
    for t in truthy:
        testing.assert_true(string_to_bool(t), String("expected ", t, " to be truthy"))


def test_string_to_bool_falsy() raises:
    var falsy: List[String] = ["0", "f", "F", "false", "False", "FALSE"]
    for f in falsy:
        testing.assert_false(string_to_bool(f), String("expected ", f, " to be falsy"))


def test_string_to_bool_rejects_unrecognized() raises:
    # Regression: unrecognized input used to return False, so `--verbose=maybe` silently disagreed
    # with the user instead of reporting the typo.
    var invalid: List[String] = ["maybe", "yes", "no", "2", "", "truthy"]
    for value in invalid:
        with assert_raises():
            _ = string_to_bool(value)


def test_stdin_splits_on_whitespace_and_quotes() raises:
    var expected: List[String] = ["run", "--name", "a b", "last"]
    testing.assert_equal(parse_args_from_stdin('run --name "a b"  last\n'), expected)


def test_stdin_keeps_double_dash_and_what_follows() raises:
    # Regression: `--` stopped parsing and dropped the rest, when it is what marks the rest as
    # positional.
    var expected: List[String] = ["run", "--", "--weird", "x"]
    testing.assert_equal(parse_args_from_stdin("run -- --weird x"), expected)


def test_stdin_keeps_empty_and_whitespace_arguments() raises:
    # Regression: `""` and quoted whitespace were dropped rather than passed as arguments.
    var expected: List[String] = ["a", "", "  ", "b"]
    testing.assert_equal(parse_args_from_stdin('a "" "  " b'), expected)


def test_stdin_joins_quotes_within_an_argument() raises:
    var expected: List[String] = ["--name=a b", "x"]
    testing.assert_equal(parse_args_from_stdin('--name="a b" x'), expected)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
