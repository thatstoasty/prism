import testing
from prism import Command, Context
from prism.flag import Flag, FType


fn dummy(ctx: Context) -> None:
    return None


def test_string():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.string(name="key", usage="usage", default=String("default")),
        ),
    )

    var flag = cmd.flags.lookup[FType.String]("key")
    testing.assert_equal(flag.value()[].type.value, FType.String.value)
    testing.assert_equal(cmd.flags.get_string("key").value(), "default")


def test_bool():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.bool(name="flag", usage="usage", default=False),
        ),
    )

    var flag = cmd.flags.lookup[FType.Bool]("flag")
    testing.assert_equal(flag.value()[].type.value, FType.Bool.value)
    testing.assert_equal(cmd.flags.get_bool("fmlag").value(), False)


def test_int():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.int(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup[FType.Int]("num")
    testing.assert_equal(flag.value()[].type.value, FType.Int.value)
    testing.assert_equal(cmd.flags.get_int("num").value(), 0)


def test_int8():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.int8(name="num", usage="usage", default=Int8(0)),
        ),
    )

    var flag = cmd.flags.lookup[FType.Int8]("num")
    testing.assert_equal(flag.value()[].type.value, FType.Int8.value)
    testing.assert_equal(cmd.flags.get_int8("num").value(), Int8(0))


def test_int16():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.int16(name="num", usage="usage", default=Int16(0)),
        ),
    )

    var flag = cmd.flags.lookup[FType.Int16]("num")
    testing.assert_equal(flag.value()[].type.value, FType.Int16.value)
    testing.assert_equal(cmd.flags.get_int16("num").value(), Int16(0))


def test_int32():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.int32(name="num", usage="usage", default=Int32(0)),
        ),
    )

    var flag = cmd.flags.lookup[FType.Int32]("num")
    testing.assert_equal(flag.value()[].type.value, FType.Int32.value)
    testing.assert_equal(cmd.flags.get_int32("num").value(), Int32(0))


def test_int64():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.int64(name="num", usage="usage", default=Int64(0)),
        ),
    )

    var flag = cmd.flags.lookup[FType.Int64]("num")
    testing.assert_equal(flag.value()[].type.value, FType.Int64.value)
    testing.assert_equal(cmd.flags.get_int64("num").value(), Int64(0))


def test_uint():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.uint(name="num", usage="usage", default=UInt(0)),
        ),
    )

    var flag = cmd.flags.lookup[FType.UInt]("num")
    testing.assert_equal(flag.value()[].type.value, FType.UInt.value)
    testing.assert_equal(cmd.flags.get_uint("num").value(), UInt(0))


def test_uint8():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.uint8(name="num", usage="usage", default=UInt8(0)),
        ),
    )

    var flag = cmd.flags.lookup[FType.UInt8]("num")
    testing.assert_equal(flag.value()[].type.value, FType.UInt8.value)
    testing.assert_equal(cmd.flags.get_uint8("num").value(), UInt8(0))


def test_uint16():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.uint16(name="num", usage="usage", default=UInt16(0)),
        ),
    )

    var flag = cmd.flags.lookup[FType.UInt16]("num")
    testing.assert_equal(flag.value()[].type.value, FType.UInt16.value)
    testing.assert_equal(cmd.flags.get_uint16("num").value(), UInt16(0))


def test_uint32():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.uint32(name="num", usage="usage", default=UInt32(0)),
        ),
    )

    var flag = cmd.flags.lookup[FType.UInt32]("num")
    testing.assert_equal(flag.value()[].type.value, FType.UInt32.value)
    testing.assert_equal(cmd.flags.get_uint32("num").value(), UInt32(0))


def test_uint64():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.uint64(name="num", usage="usage", default=UInt64(0)),
        ),
    )

    var flag = cmd.flags.lookup[FType.UInt64]("num")
    testing.assert_equal(flag.value()[].type.value, FType.UInt64.value)
    testing.assert_equal(cmd.flags.get_uint64("num").value(), UInt64(0))


def test_float16():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.float16(name="num", usage="usage", default=Float16(0)),
        ),
    )

    var flag = cmd.flags.lookup[FType.Float16]("num")
    testing.assert_equal(flag.value()[].type.value, FType.Float16.value)
    testing.assert_equal(cmd.flags.get_float16("num").value(), Float16(0))


def test_float32():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.float32(name="num", usage="usage", default=Float32(0)),
        ),
    )

    var flag = cmd.flags.lookup[FType.Float32]("num")
    testing.assert_equal(flag.value()[].type.value, FType.Float32.value)
    testing.assert_equal(cmd.flags.get_float32("num").value(), Float32(0))


def test_float64():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.float64(name="num", usage="usage", default=Float64(0)),
        ),
    )

    var flag = cmd.flags.lookup[FType.Float64]("num")
    testing.assert_equal(flag.value()[].type.value, FType.Float64.value)
    testing.assert_equal(cmd.flags.get_float64("num").value(), Float64(0))


def test_string_list():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.string_list(name="num", usage="usage", default=List[String]("a", "b")),
        ),
    )

    var flag = cmd.flags.lookup[FType.StringList]("num")
    testing.assert_equal(flag.value()[].type.value, FType.StringList.value)
    testing.assert_equal(cmd.flags.get_string_list("num").value(), List[String]("a", "b"))


def test_int_list():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.int_list(name="num", usage="usage", default=List[Int, True](0, 1)),
        ),
    )

    var flag = cmd.flags.lookup[FType.IntList]("num")
    testing.assert_equal(flag.value()[].type.value, FType.IntList.value)

    var result = cmd.flags.get_int_list("num").value()
    testing.assert_equal(result[0], 0)
    testing.assert_equal(result[1], 1)


def test_float64_list():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.float64_list(name="num", usage="usage", default=List[Float64, True](0, 1)),
        ),
    )

    var flag = cmd.flags.lookup[FType.Float64List]("num")
    testing.assert_equal(flag.value()[].type.value, FType.Float64List.value)

    var result = cmd.flags.get_float64_list("num").value()
    testing.assert_equal(result[0], Float64(0))
    testing.assert_equal(result[1], Float64(1))
