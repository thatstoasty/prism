from std import testing
from prism.flag import Flag
from prism.opt_type import OptType
from std.testing import TestSuite, assert_raises

from prism import ArgSet, Command, FlagSet


def dummy(args: ArgSet, flags: FlagSet) -> None:
    return None


def test_string() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.new[String](name="key", usage="usage", default=String("default")),
        ],
    )

    var flag = cmd.flags.lookup[OptType.String]("key")
    testing.assert_equal(flag.value()[].type.value, OptType.String.value)
    testing.assert_equal(cmd.flags.get[String]("key").value(), "default")


def test_bool() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.new[Bool](name="flag", usage="usage", default=False),
        ],
    )

    var flag = cmd.flags.lookup[OptType.Bool]("flag")
    testing.assert_equal(flag.value()[].type.value, OptType.Bool.value)
    testing.assert_equal(cmd.flags.get[Bool]("flag").value(), False)


def test_int() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.new[Int](name="num", usage="usage", default=0),
        ],
    )

    var flag = cmd.flags.lookup[OptType.Int]("num")
    testing.assert_equal(flag.value()[].type.value, OptType.Int.value)
    testing.assert_equal(cmd.flags.get[Int]("num").value(), 0)


def test_int8() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.int8(name="num", usage="usage", default=Int8(0)),
        ],
    )

    var flag = cmd.flags.lookup[OptType.Int8]("num")
    testing.assert_equal(flag.value()[].type.value, OptType.Int8.value)
    testing.assert_equal(cmd.flags.get_int8("num").value(), Int8(0))


def test_int16() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.int16(name="num", usage="usage", default=Int16(0)),
        ],
    )

    var flag = cmd.flags.lookup[OptType.Int16]("num")
    testing.assert_equal(flag.value()[].type.value, OptType.Int16.value)
    testing.assert_equal(cmd.flags.get_int16("num").value(), Int16(0))


def test_int32() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.int32(name="num", usage="usage", default=Int32(0)),
        ],
    )

    var flag = cmd.flags.lookup[OptType.Int32]("num")
    testing.assert_equal(flag.value()[].type.value, OptType.Int32.value)
    testing.assert_equal(cmd.flags.get_int32("num").value(), Int32(0))


def test_int64() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.int64(name="num", usage="usage", default=Int64(0)),
        ],
    )

    var flag = cmd.flags.lookup[OptType.Int64]("num")
    testing.assert_equal(flag.value()[].type.value, OptType.Int64.value)
    testing.assert_equal(cmd.flags.get_int64("num").value(), Int64(0))


def test_uint() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.uint(name="num", usage="usage", default=UInt(0)),
        ],
    )

    var flag = cmd.flags.lookup[OptType.UInt]("num")
    testing.assert_equal(flag.value()[].type.value, OptType.UInt.value)
    testing.assert_equal(cmd.flags.get_uint("num").value(), UInt(0))


def test_uint8() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.uint8(name="num", usage="usage", default=UInt8(0)),
        ],
    )

    var flag = cmd.flags.lookup[OptType.UInt8]("num")
    testing.assert_equal(flag.value()[].type.value, OptType.UInt8.value)
    testing.assert_equal(cmd.flags.get_uint8("num").value(), UInt8(0))


def test_uint16() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.uint16(name="num", usage="usage", default=UInt16(0)),
        ],
    )

    var flag = cmd.flags.lookup[OptType.UInt16]("num")
    testing.assert_equal(flag.value()[].type.value, OptType.UInt16.value)
    testing.assert_equal(cmd.flags.get_uint16("num").value(), UInt16(0))


def test_uint32() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.new[UInt32](name="num", usage="usage", default=UInt32(0)),
        ],
    )

    var flag = cmd.flags.lookup[OptType.UInt32]("num")
    testing.assert_equal(flag.value()[].type.value, OptType.UInt32.value)
    testing.assert_equal(cmd.flags.get[UInt32]("num").value(), UInt32(0))


def test_uint64() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.uint64(name="num", usage="usage", default=UInt64(0)),
        ],
    )

    var flag = cmd.flags.lookup[OptType.UInt64]("num")
    testing.assert_equal(flag.value()[].type.value, OptType.UInt64.value)
    testing.assert_equal(cmd.flags.get_uint64("num").value(), UInt64(0))


def test_float16() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.float16(name="num", usage="usage", default=Float16(0)),
        ],
    )

    var flag = cmd.flags.lookup[OptType.Float16]("num")
    testing.assert_equal(flag.value()[].type.value, OptType.Float16.value)
    testing.assert_equal(cmd.flags.get_float16("num").value(), Float16(0))


def test_float32() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.float32(name="num", usage="usage", default=Float32(0)),
        ],
    )

    var flag = cmd.flags.lookup[OptType.Float32]("num")
    testing.assert_equal(flag.value()[].type.value, OptType.Float32.value)
    testing.assert_equal(cmd.flags.get_float32("num").value(), Float32(0))


def test_float64() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.float64(name="num", usage="usage", default=Float64(0)),
        ],
    )

    var flag = cmd.flags.lookup[OptType.Float64]("num")
    testing.assert_equal(flag.value()[].type.value, OptType.Float64.value)
    testing.assert_equal(cmd.flags.get_float64("num").value(), Float64(0))


def test_string_list() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.string_list(name="num", usage="usage", default=["a", "b"]),
        ],
    )

    var flag = cmd.flags.lookup[OptType.StringList]("num")
    testing.assert_equal(flag.value()[].type.value, OptType.StringList.value)
    testing.assert_equal(cmd.flags.get_string_list("num").value(), ["a", "b"])


def test_int_list() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.int_list(name="num", usage="usage", default=[0, 1]),
        ],
    )

    var flag = cmd.flags.lookup[OptType.IntList]("num")
    testing.assert_equal(flag.value()[].type.value, OptType.IntList.value)

    ref result = cmd.flags.get_int_list("num").value()
    testing.assert_equal(result[0], 0)
    testing.assert_equal(result[1], 1)


def test_float64_list() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.float64_list(name="num", usage="usage", default=[0.0, 1.0]),
        ],
    )

    var flag = cmd.flags.lookup[OptType.Float64List]("num")
    testing.assert_equal(flag.value()[].type.value, OptType.Float64List.value)

    ref result = cmd.flags.get_float64_list("num").value()
    testing.assert_equal(result[0], Float64(0))
    testing.assert_equal(result[1], Float64(1))


def test_unicode_flag_name() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.new[String](name="cléf", usage="usage", default="valeur"),
        ],
    )

    var flag = cmd.flags.lookup[OptType.String]("cléf")
    testing.assert_equal(flag.value()[].name, "cléf")
    testing.assert_equal(cmd.flags.get[String]("cléf").value(), "valeur")


def test_double_dash_terminates_flag_parsing() raises:
    # Regression: `--` was parsed as a flag with an empty name and rejected as unknown.
    var flags: List[Flag] = [
        Flag.new[String](name="output", shorthand="o", usage="Output path."),
        Flag.new[Bool](name="verbose", shorthand="V", usage="Verbose."),
    ]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["--output", "x", "--", "-V", "positional"]
    var remaining = flag_set.from_args(Span(args))

    testing.assert_equal(flag_set.get_string("output").value(), "x")
    # Everything after `--` is positional, even though `-V` names a real flag.
    testing.assert_equal(len(remaining), 2)
    testing.assert_equal(remaining[0], "-V")
    testing.assert_equal(remaining[1], "positional")
    testing.assert_false(flag_set.get_bool("verbose").or_else(False))


def test_repeated_scalar_flag_last_wins() raises:
    # Regression: repeats were concatenated for every type, so this produced the value "a b".
    var flags: List[Flag] = [Flag.new[String](name="name", usage="A name.")]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["--name", "a", "--name", "b"]
    _ = flag_set.from_args(Span(args))

    testing.assert_equal(flag_set.get_string("name").value(), "b")


def test_repeated_list_flag_accumulates() raises:
    var flags: List[Flag] = [Flag.string_list(name="tags", usage="Tags.")]
    var flag_set = FlagSet(flags^)
    var args: List[String] = ["--tags", "x", "--tags", "y"]
    _ = flag_set.from_args(Span(args))

    var tags = flag_set.get_string_list("tags").value().copy()
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
        Flag.uint8(name="small", usage="Small."),
        Flag.float64(name="ratio", usage="Ratio."),
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
        Flag.string_list(name="tags", usage="Tags."),
        Flag.int_list(name="nums", usage="Nums."),
        Flag.float64_list(name="rates", usage="Rates."),
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


def test_generic_get_reports_a_parse_failure() raises:
    # Unlike the typed accessors, which return None when the declared OptType does not match, the
    # generic accessor matches by name and reports that the value is not readable as a `T`.
    var flags: List[Flag] = [Flag.new[String](name="region", usage="Region.")]
    var args: List[String] = ["--region", "us-east"]
    var flag_set = _parsed(flags^, args^)

    with assert_raises():
        _ = flag_set.get[Int]("region")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
