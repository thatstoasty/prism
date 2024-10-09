from memory.arc import Arc
import testing
from prism.flag import Flag
from prism.flag_set import FlagSet, string_to_bool, string_to_float
from prism.flag_parser import FlagParser


def test_string_to_bool():
    var truthy = List[String]("true", "True", "1")
    for t in truthy:
        testing.assert_true(string_to_bool(t[]))


def test_string_to_float():
    var floats = List[String]("1.0", "1.000000005", "12345667.12345667")
    var results = List[Float64](1.0, 1.000000005, 12345667.12345667)
    for i in range(len(floats)):
        testing.assert_true(string_to_float(floats[i]) == results[i])


def test_get_flags():
    var flag_set = FlagSet()
    flag_set.string_flag("key", "usage", "default")
    flag_set.bool_flag("flag", "usage", "False")
    var flags = List[String]("--key=value", "positional", "--flag")

    _ = flag_set.from_args(flags)
    testing.assert_equal(flag_set.get_string("key"), "value")
    testing.assert_equal(flag_set.get_bool("flag"), True)


def test_parse_flag():
    var flag_set = FlagSet()
    flag_set.string_flag(name="key", usage="usage", default="default")
    flag_set.bool_flag(name="flag", usage="usage", default=False)

    var parser = FlagParser()
    var name: String
    var value: String
    var increment_by: Int
    name, value, increment_by = parser.parse_flag(String("--key"), List[String]("--key", "value"), flag_set)
    testing.assert_equal(name, "key")
    testing.assert_equal(value, "value")
    testing.assert_equal(increment_by, 2)

    name, value, increment_by = parser.parse_flag(String("--key=value"), List[String]("--key=value"), flag_set)
    testing.assert_equal(name, "key")
    testing.assert_equal(value, "value")
    testing.assert_equal(increment_by, 1)


def test_parse_shorthand_flag():
    var flag_set = FlagSet()
    flag_set.string_flag(name="key", usage="usage", default="default", shorthand="k")
    flag_set.bool_flag(name="flag", usage="usage", default=False, shorthand="f")

    var parser = FlagParser()
    var name: String
    var value: String
    var increment_by: Int
    name, value, increment_by = parser.parse_shorthand_flag("-k", List[String]("-k", "value"), flag_set)
    testing.assert_equal(name, "key")
    testing.assert_equal(value, "value")
    testing.assert_equal(increment_by, 2)

    name, value, increment_by = parser.parse_shorthand_flag("-k=value", List[String]("-k=value"), flag_set)
    testing.assert_equal(name, "key")
    testing.assert_equal(value, "value")
    testing.assert_equal(increment_by, 1)
