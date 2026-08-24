from std import testing
from prism._util import string_to_bool
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


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
