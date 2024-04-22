from tests.wrapper import MojoTest
from prism.flag import string_to_bool, string_to_float, Flag, FlagSet, get_flags, parse_flag, parse_shorthand_flag


fn test_string_to_bool():
    var test = MojoTest("Testing string_to_bool")
    var truthy = List[String]("true", "True", "1")
    for t in truthy:
        test.assert_true(string_to_bool(t[]))


fn test_string_to_float() raises:
    var test = MojoTest("Testing string_to_float")
    var floats = List[String]("1.0", "1.000000005", "12345667.12345667")
    var results = List[Float64](1.0, 1.000000005, 12345667.12345667)
    for i in range(len(floats)):
        test.assert_true(string_to_float(floats[i]) == results[i])


fn test_get_flags():
    var test = MojoTest("Testing get_flags")
    var flag_set = FlagSet()
    flag_set.add_string_flag["key", "description", "default"]()
    flag_set.add_bool_flag["flag", "description", "False"]()
    var flags = List[String]("--key=value", "positional", "--flag")

    var remaining_args: List[String]
    var err: Error
    remaining_args, err = get_flags(flag_set, flags)
    test.assert_equal(flag_set.get_as_string("key").value(), "value")
    test.assert_equal(flag_set.get_as_bool("flag").value(), True)


fn test_parse_flag() raises:
    var test = MojoTest("Testing parse_flag")
    var flag_set = FlagSet()
    flag_set.add_string_flag[name="key", usage="description", default="default"]()
    flag_set.add_bool_flag[name="flag", usage="description", default=False]()

    var name: String
    var value: String
    var increment_by: Int
    name, value, increment_by = parse_flag(0, String("--key"), List[String]("--key", "value"), flag_set)
    test.assert_equal(name, "key")
    test.assert_equal(value, "value")
    test.assert_equal(increment_by, 2)

    name, value, increment_by = parse_flag(0, String("--key=value"), List[String]("--key=value"), flag_set)
    test.assert_equal(name, "key")
    test.assert_equal(value, "value")
    test.assert_equal(increment_by, 1)


fn test_parse_shorthand_flag() raises:
    var test = MojoTest("Testing parse_shorthand_flag")
    var flag_set = FlagSet()
    flag_set.add_string_flag[name="key", usage="description", default="default", shorthand="k"]()
    flag_set.add_bool_flag[name="flag", usage="description", default=False, shorthand="f"]()

    var name: String
    var value: String
    var increment_by: Int
    name, value, increment_by = parse_shorthand_flag(0, String("-k"), List[String]("-k", "value"), flag_set)
    test.assert_equal(name, "key")
    test.assert_equal(value, "value")
    test.assert_equal(increment_by, 2)

    name, value, increment_by = parse_shorthand_flag(0, String("-k=value"), List[String]("-k=value"), flag_set)
    test.assert_equal(name, "key")
    test.assert_equal(value, "value")
    test.assert_equal(increment_by, 1)


fn main() raises:
    test_string_to_bool()
    test_string_to_float()
    test_get_flags()
    test_parse_flag()
    test_parse_shorthand_flag()
