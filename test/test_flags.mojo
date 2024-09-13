from memory.arc import Arc
import testing
from prism.flag import Flag, get_flags, parse_flag, parse_shorthand_flag
from prism.flag_set import FlagSet, string_to_bool, string_to_float


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
    flag_set.add_string_flag("key", "description", "default")
    flag_set.add_bool_flag("flag", "description", "False")
    var flags = List[String]("--key=value", "positional", "--flag")

    var remaining_args: List[String]
    var err: Error
    remaining_args, err = get_flags(flag_set, flags)
    testing.assert_equal(flag_set.get_as_string("key").value(), "value")
    testing.assert_equal(flag_set.get_as_bool("flag").value(), True)


def test_parse_flag():
    var flag_set = FlagSet()
    flag_set.add_string_flag(name="key", usage="description", default="default")
    flag_set.add_bool_flag(name="flag", usage="description", default=False)

    var name: String
    var value: String
    var increment_by: Int
    var err: Error
    name, value, increment_by, err = parse_flag(0, String("--key"), List[String]("--key", "value"), flag_set)
    testing.assert_equal(name, "key")
    testing.assert_equal(value, "value")
    testing.assert_equal(increment_by, 2)

    name, value, increment_by, err = parse_flag(0, String("--key=value"), List[String]("--key=value"), flag_set)
    testing.assert_equal(name, "key")
    testing.assert_equal(value, "value")
    testing.assert_equal(increment_by, 1)


def test_parse_shorthand_flag():
    var flag_set = FlagSet()
    flag_set.add_string_flag(name="key", usage="description", default="default", shorthand="k")
    flag_set.add_bool_flag(name="flag", usage="description", default=False, shorthand="f")

    var name: String
    var value: String
    var increment_by: Int
    var err: Error
    name, value, increment_by, err = parse_shorthand_flag(0, String("-k"), List[String]("-k", "value"), flag_set)
    testing.assert_equal(name, "key")
    testing.assert_equal(value, "value")
    testing.assert_equal(increment_by, 2)

    name, value, increment_by, err = parse_shorthand_flag(0, String("-k=value"), List[String]("-k=value"), flag_set)
    testing.assert_equal(name, "key")
    testing.assert_equal(value, "value")
    testing.assert_equal(increment_by, 1)
