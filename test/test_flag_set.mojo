from std import testing
from prism.flag import Flag
from prism.opt_type import OptType
from std.testing import TestSuite, assert_raises

from prism import ArgSet, Command, FlagSet


def dummy(args: ArgSet, flags: FlagSet) -> None:
    return None

comptime BASE_COMMAND = Command(
    name="root",
    usage="Base command.",
    run=dummy,
)

def test_string() raises:
    var name = "key"
    var expected = "default"
    var cmd = materialize[BASE_COMMAND]()
    cmd.flags.append(Flag.new[String](name=name, usage="usage", default=expected))

    var flag = cmd.flags.lookup[String](name)
    testing.assert_equal(flag.value()[].type, OptType.String)
    testing.assert_equal(cmd.flags.get[String](name).value(), expected)


def test_bool() raises:
    var name = "flag"
    var expected = False
    var cmd = materialize[BASE_COMMAND]()
    cmd.flags.append(Flag.new[Bool](name=name, usage="usage", default=expected))

    var flag = cmd.flags.lookup[Bool](name)
    testing.assert_equal(flag.value()[].type, OptType.Bool)
    testing.assert_equal(cmd.flags.get[Bool](name).value(), expected)


def test_int() raises:
    var name = "flag"
    var expected = 0
    var cmd = materialize[BASE_COMMAND]()
    cmd.flags.append(Flag.new[Int](name=name, usage="usage", default=expected))

    var flag = cmd.flags.lookup[Int](name)
    testing.assert_equal(flag.value()[].type, OptType.Int)
    testing.assert_equal(cmd.flags.get[Int](name).value(), expected)


def test_int8() raises:
    var name = "flag"
    var expected: Int8 = 0
    var cmd = materialize[BASE_COMMAND]()
    cmd.flags.append(Flag.new[Int8](name=name, usage="usage", default=expected))

    var flag = cmd.flags.lookup[Int8](name)
    testing.assert_equal(flag.value()[].type, OptType.Int8)
    testing.assert_equal(cmd.flags.get[Int8](name).value(), expected)


def test_int16() raises:
    var name = "flag"
    var expected: Int16 = 0
    var cmd = materialize[BASE_COMMAND]()
    cmd.flags.append(Flag.new[Int16](name=name, usage="usage", default=expected))

    var flag = cmd.flags.lookup[Int16](name)
    testing.assert_equal(flag.value()[].type, OptType.Int16)
    testing.assert_equal(cmd.flags.get[Int16](name).value(), expected)


def test_int32() raises:
    var name = "flag"
    var expected: Int32 = 0
    var cmd = materialize[BASE_COMMAND]()
    cmd.flags.append(Flag.new[Int32](name=name, usage="usage", default=expected))

    var flag = cmd.flags.lookup[Int32](name)
    testing.assert_equal(flag.value()[].type, OptType.Int32)
    testing.assert_equal(cmd.flags.get[Int32](name).value(), expected)


def test_int64() raises:
    var name = "flag"
    var expected: Int64 = 0
    var cmd = materialize[BASE_COMMAND]()
    cmd.flags.append(Flag.new[Int64](name=name, usage="usage", default=expected))

    var flag = cmd.flags.lookup[Int64](name)
    testing.assert_equal(flag.value()[].type, OptType.Int64)
    testing.assert_equal(cmd.flags.get[Int64](name).value(), expected)


def test_uint() raises:
    var name = "flag"
    var expected: UInt = 0
    var cmd = materialize[BASE_COMMAND]()
    cmd.flags.append(Flag.new[UInt](name=name, usage="usage", default=expected))

    var flag = cmd.flags.lookup[UInt](name)
    testing.assert_equal(flag.value()[].type, OptType.UInt)
    testing.assert_equal(cmd.flags.get[UInt](name).value(), expected)


def test_uint8() raises:
    var name = "flag"
    var expected: UInt8 = 0
    var cmd = materialize[BASE_COMMAND]()
    cmd.flags.append(Flag.new[UInt8](name=name, usage="usage", default=expected))

    var flag = cmd.flags.lookup[UInt8](name)
    testing.assert_equal(flag.value()[].type, OptType.UInt8)
    testing.assert_equal(cmd.flags.get[UInt8](name).value(), expected)


def test_uint16() raises:
    var name = "flag"
    var expected: UInt16 = 0
    var cmd = materialize[BASE_COMMAND]()
    cmd.flags.append(Flag.new[UInt16](name=name, usage="usage", default=expected))

    var flag = cmd.flags.lookup[UInt16](name)
    testing.assert_equal(flag.value()[].type, OptType.UInt16)
    testing.assert_equal(cmd.flags.get[UInt16](name).value(), expected)


def test_uint32() raises:
    var name = "flag"
    var expected: UInt32 = 0
    var cmd = materialize[BASE_COMMAND]()
    cmd.flags.append(Flag.new[UInt32](name=name, usage="usage", default=expected))

    var flag = cmd.flags.lookup[UInt32](name)
    testing.assert_equal(flag.value()[].type, OptType.UInt32)
    testing.assert_equal(cmd.flags.get[UInt32](name).value(), expected)


def test_uint64() raises:
    var name = "flag"
    var expected: UInt64 = 0
    var cmd = materialize[BASE_COMMAND]()
    cmd.flags.append(Flag.new(name=name, usage="usage", default=expected))

    var flag = cmd.flags.lookup[UInt64](name)
    testing.assert_equal(flag.value()[].type, OptType.UInt64)
    testing.assert_equal(cmd.flags.get[UInt64](name).value(), expected)


def test_float16() raises:
    var name = "flag"
    var expected: Float16 = 0
    var cmd = materialize[BASE_COMMAND]()
    cmd.flags.append(Flag.new(name=name, usage="usage", default=expected))

    var flag = cmd.flags.lookup[Float16](name)
    testing.assert_equal(flag.value()[].type, OptType.Float16)
    testing.assert_equal(cmd.flags.get[Float16](name).value(), expected)


def test_float32() raises:
    var name = "flag"
    var expected: Float32 = 0
    var cmd = materialize[BASE_COMMAND]()
    cmd.flags.append(Flag.new(name=name, usage="usage", default=expected))

    var flag = cmd.flags.lookup[Float32](name)
    testing.assert_equal(flag.value()[].type, OptType.Float32)
    testing.assert_equal(cmd.flags.get[Float32](name).value(), expected)


def test_float64() raises:
    var name = "flag"
    var expected: Float64 = 0
    var cmd = materialize[BASE_COMMAND]()
    cmd.flags.append(Flag.new(name=name, usage="usage", default=0.0))

    var flag = cmd.flags.lookup[Float64](name)
    testing.assert_equal(flag.value()[].type, OptType.Float64)
    testing.assert_equal(cmd.flags.get[Float64](name).value(), expected)


def test_string_list() raises:
    var name = "flag"
    var expected: List[String] = ["a", "b"]
    var cmd = materialize[BASE_COMMAND]()
    cmd.flags.append(Flag.new(name=name, usage="usage", default=expected.copy()))

    var flag = cmd.flags.lookup(name)
    testing.assert_true(flag.value()[].type.is_list_type())
    testing.assert_equal(cmd.flags.get[List[String]](name).value(), expected)


def test_int_list() raises:
    var name = "flag"
    var expected: List[Int] = [0, 1]
    var cmd = materialize[BASE_COMMAND]()
    cmd.flags.append(Flag.new(name=name, usage="usage", default=expected.copy()))

    var flag = cmd.flags.lookup(name)
    testing.assert_true(flag.value()[].type.is_list_type())

    ref result = cmd.flags.get[List[Int]](name).value()
    testing.assert_equal(result[0], 0)
    testing.assert_equal(result[1], 1)


def test_float64_list() raises:
    var name = "flag"
    var expected: List[Float64] = [0.0, 1.0]
    var cmd = materialize[BASE_COMMAND]()
    cmd.flags.append(Flag.new(name=name, usage="usage", default=expected.copy()))

    var flag = cmd.flags.lookup(name)
    testing.assert_true(flag.value()[].type.is_list_type())

    ref result = cmd.flags.get[List[Float64]](name).value()
    testing.assert_equal(result[0], 0)
    testing.assert_equal(result[1], 1)


def test_unicode_flag_name() raises:
    var name = "cléf"
    var expected = "valeur"
    var cmd = materialize[BASE_COMMAND]()
    cmd.flags.append(Flag.new(name=name, usage="usage", default=expected))

    var flag = cmd.flags.lookup[String](name)
    testing.assert_equal(flag.value()[].name, name)
    testing.assert_equal(cmd.flags.get[String](name).value(), expected)


def test_double_dash_terminates_flag_parsing() raises:
    # Regression: `--` was parsed as a flag with an empty name and rejected as unknown.
    var flags: List[Flag] = [
        Flag.new[String](name="output", shorthand="o", usage="Output path."),
        Flag.new[Bool](name="verbose", shorthand="V", usage="Verbose."),
    ]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["--output", "x", "--", "-V", "positional"]
    var remaining = flag_set.from_args(Span(args))

    testing.assert_equal(flag_set.get[String]("output").value(), "x")
    # Everything after `--` is positional, even though `-V` names a real flag.
    testing.assert_equal(len(remaining), 2)
    testing.assert_equal(remaining[0], "-V")
    testing.assert_equal(remaining[1], "positional")
    testing.assert_false(flag_set.get[Bool]("verbose").or_else(False))


def test_repeated_scalar_flag_last_wins() raises:
    # Regression: repeats were concatenated for every type, so this produced the value "a b".
    var flags: List[Flag] = [Flag.new[String](name="name", usage="A name.")]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["--name", "a", "--name", "b"]
    _ = flag_set.from_args(Span(args))

    testing.assert_equal(flag_set.get[String]("name").value(), "b")


def test_repeated_list_flag_accumulates() raises:
    var flags: List[Flag] = [Flag.new[List[String]](name="tags", usage="Tags.")]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["--tags", "x", "--tags", "y"]
    _ = flag_set.from_args(Span(args))

    var tags = flag_set.get[List[String]]("tags").value().copy()
    testing.assert_equal(len(tags), 2)
    testing.assert_equal(tags[0], "x")
    testing.assert_equal(tags[1], "y")


def _parsed(var flags: List[Flag], var args: List[String]) raises -> FlagSet:
    """Builds a flag set and parses `args` into it."""
    var flag_set = FlagSet(flags^)
    _ = flag_set.from_args(Span(args))
    return flag_set^


def test_generic_get_scalars() raises:
    var flags: List[Flag] = [
        Flag.new[String](name="region", usage="Region."),
        Flag.new[Int](name="port", usage="Port."),
        Flag.new[UInt8](name="small", usage="Small."),
        Flag.new[Float64](name="ratio", usage="Ratio."),
        Flag.new[Bool](name="verbose", usage="Verbose."),
    ]
    var args: List[String] = ["--region", "us", "--port", "8080", "--small", "7", "--ratio", "0.25", "--verbose"]
    var flag_set = _parsed(flags^, args^)

    testing.assert_equal(flag_set.get[String]("region").value(), "us")
    testing.assert_equal(flag_set.get[Int]("port").value(), 8080)
    testing.assert_equal(flag_set.get[UInt8]("small").value(), UInt8(7))
    testing.assert_equal(flag_set.get[Float64]("ratio").value(), 0.25)
    testing.assert_true(flag_set.get[Bool]("verbose").value())


def test_generic_get_lists() raises:
    var flags: List[Flag] = [
        Flag.new[List[String]](name="tags", usage="Tags."),
        Flag.new[List[Int]](name="nums", usage="Nums."),
        Flag.new[List[Float64]](name="rates", usage="Rates."),
    ]
    var args: List[String] = ["--tags", "a", "--tags", "b", "--nums", "1", "--nums", "2", "--rates", "1.5"]
    var flag_set = _parsed(flags^, args^)

    var tags = flag_set.get[List[String]]("tags").value().copy()
    testing.assert_equal(len(tags), 2)
    testing.assert_equal(tags[1], "b")

    var nums = flag_set.get[List[Int]]("nums").value().copy()
    testing.assert_equal(len(nums), 2)
    testing.assert_equal(nums[1], 2)

    var rates = flag_set.get[List[Float64]]("rates").value().copy()
    testing.assert_equal(rates[0], 1.5)


def test_generic_get_falls_back_to_default() raises:
    var flags: List[Flag] = [Flag.new[Int](name="port", usage="Port.", default=Optional[Int](9000))]
    var args = List[String]()
    var flag_set = _parsed(flags^, args^)

    testing.assert_equal(flag_set.get[Int]("port").value(), 9000)


def test_generic_get_unknown_flag_is_none() raises:
    var flags: List[Flag] = [Flag.new[Int](name="port", usage="Port.")]
    var args = List[String]()
    var flag_set = _parsed(flags^, args^)

    testing.assert_false(Bool(flag_set.get[Int]("nope")), "an undefined flag should read as None")


def test_generic_get_type_mismatch_is_none() raises:
    # `get[T]` matches on the flag's declared OptType as well as its name, so asking for the wrong
    # type reads as None rather than attempting the parse and failing.
    var flags: List[Flag] = [Flag.new[String](name="region", usage="Region.")]
    var args: List[String] = ["--region", "us-east"]
    var flag_set = _parsed(flags^, args^)

    testing.assert_false(Bool(flag_set.get[Int]("region")), "a type mismatch should read as None")
    testing.assert_equal(flag_set.get[String]("region").value(), "us-east")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
