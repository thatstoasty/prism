from memory import ArcPointerPointer
import testing
from prism.flag import Flag
from prism.flag_set import FlagSet, string_to_bool
from prism.flag_parser import FlagParser


def test_string_to_bool():
    truthy = List[String]("true", "True", "1")
    for t in truthy:
        testing.assert_true(string_to_bool(t[]))


def test_get_flags():
    flag_set = FlagSet()
    flag_set.string_flag("key", "usage", "default")
    flag_set.bool_flag("flag", "usage", "False")
    flags = List[String]("--key=value", "positional", "--flag")

    _ = flag_set.from_args(flags)
    testing.assert_equal(flag_set.get_string("key"), "value")
    testing.assert_equal(flag_set.get_bool("flag"), True)


def test_parse_flag():
    flag_set = FlagSet()
    flag_set.string_flag(name="key", usage="usage", default="default")
    flag_set.bool_flag(name="flag", usage="usage", default=False)

    parser = FlagParser()
    name, value, increment_by = parser.parse_flag("--key", List[String]("--key", "value"), flag_set)
    testing.assert_equal(name, "key")
    testing.assert_equal(value, "value")
    testing.assert_equal(increment_by, 2)

    name, value, increment_by = parser.parse_flag(String("--key=value"), List[String]("--key=value"), flag_set)
    testing.assert_equal(name, "key")
    testing.assert_equal(value, "value")
    testing.assert_equal(increment_by, 1)


def test_parse_shorthand_flag():
    flag_set = FlagSet()
    flag_set.string_flag(name="key", usage="usage", default="default", shorthand="k")
    flag_set.bool_flag(name="flag", usage="usage", default=False, shorthand="f")

    parser = FlagParser()
    name, value, increment_by = parser.parse_shorthand_flag("-k", List[String]("-k", "value"), flag_set)
    testing.assert_equal(name, "key")
    testing.assert_equal(value, "value")
    testing.assert_equal(increment_by, 2)

    name, value, increment_by = parser.parse_shorthand_flag("-k=value", List[String]("-k=value"), flag_set)
    testing.assert_equal(name, "key")
    testing.assert_equal(value, "value")
    testing.assert_equal(increment_by, 1)
