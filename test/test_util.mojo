import testing
from prism._util import string_to_bool
from testing import TestSuite


def test_string_to_bool():
    var truthy: List[String] = ["true", "True", "1"]
    for t in truthy:
        testing.assert_true(string_to_bool(t))


fn main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
