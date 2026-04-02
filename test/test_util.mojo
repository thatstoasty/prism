from std import testing
from prism._util import string_to_bool
from std.testing import TestSuite


def test_string_to_bool() raises:
    var truthy: List[String] = ["true", "True", "1"]
    for t in truthy:
        testing.assert_true(string_to_bool(t))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
