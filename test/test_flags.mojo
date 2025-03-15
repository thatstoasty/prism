from memory import ArcPointer
from collections.string import StaticString
import testing
import prism
from prism import Command, Context
from prism.flag import Flag, FType
from prism._flag_set import string_to_bool
from prism._flag_parser import FlagParser


def test_string_to_bool():
    alias truthy = List[String]("true", "True", "1")
    for t in truthy:
        testing.assert_true(string_to_bool(t[]))


fn dummy(ctx: Context) -> None:
    return None

def test_gets():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.string(name="key", usage="usage", default="default"),
            Flag.bool(name="flag", usage="usage", default=False),
        ),
    )

    var args = List[StaticString]("--key=value", "positional", "--flag")
    _ = cmd.flags.from_args(args)
    testing.assert_equal(cmd.get_string("key"), "value")
    testing.assert_equal(cmd.get_bool("flag"), True)


def test_parse():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.string(name="key", usage="usage", default="default"),
            Flag.bool(name="flag", usage="usage", default=False),
        ),
    )

    remaining_args = cmd.flags.from_args(List[StaticString]("--key=value"))
    testing.assert_equal(len(remaining_args), 0)


# def test_parse_shorthand():
#     var cmd = Command(
#         name="root",
#         usage="Base command.",
#         run=dummy,
#         flags=List[Flag](
#             Flag.string(name="key", usage="usage", default="default", shorthand="k"),
#             Flag.bool(name="flag", usage="usage", default=False, shorthand="f"),
#         ),
#     )

#     parser = FlagParser()
#     name, value, increment_by = parser.parse_shorthand("-k", List[StaticString]("-k", "value"), cmd.flags)
#     testing.assert_equal(name, "key")
#     testing.assert_equal(value, "value")
#     testing.assert_equal(increment_by, 2)

#     name, value, increment_by = parser.parse_shorthand("-k=value", List[StaticString]("-k=value"), cmd.flags)
#     testing.assert_equal(name, "key")
#     testing.assert_equal(value, "value")
#     testing.assert_equal(increment_by, 1)


def test_string():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.string(name="key", usage="usage", default="default"),
        ),
    )

    var flag = cmd.flags.lookup[FType.String]("key")
    testing.assert_equal(flag[].type.value, FType.String.value)
    testing.assert_equal(cmd.get_string("key"), "default")


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
    testing.assert_equal(flag[].type.value, FType.Bool.value)
    testing.assert_equal(cmd.get_bool("flag"), False)


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
    testing.assert_equal(flag[].type.value, FType.Int.value)
    testing.assert_equal(cmd.get_int("num"), 0)


def test_int8():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.int8(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup[FType.Int8]("num")
    testing.assert_equal(flag[].type.value, FType.Int8.value)
    testing.assert_equal(cmd.get_int8("num"), Int8(0))


def test_int16():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.int16(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup[FType.Int16]("num")
    testing.assert_equal(flag[].type.value, FType.Int16.value)
    testing.assert_equal(cmd.get_int16("num"), Int16(0))


def test_int32():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.int32(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup[FType.Int32]("num")
    testing.assert_equal(flag[].type.value, FType.Int32.value)
    testing.assert_equal(cmd.get_int32("num"), Int32(0))


def test_int64():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.int64(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup[FType.Int64]("num")
    testing.assert_equal(flag[].type.value, FType.Int64.value)
    testing.assert_equal(cmd.get_int64("num"), Int64(0))


def test_uint():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.uint(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup[FType.UInt]("num")
    testing.assert_equal(flag[].type.value, FType.UInt.value)
    testing.assert_equal(cmd.get_uint("num"), UInt(0))


def test_uint8():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.uint8(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup[FType.UInt8]("num")
    testing.assert_equal(flag[].type.value, FType.UInt8.value)
    testing.assert_equal(cmd.get_uint8("num"), UInt8(0))


def test_uint16():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.uint16(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup[FType.UInt16]("num")
    testing.assert_equal(flag[].type.value, FType.UInt16.value)
    testing.assert_equal(cmd.get_uint16("num"), UInt16(0))


def test_uint32():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.uint32(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup[FType.UInt32]("num")
    testing.assert_equal(flag[].type.value, FType.UInt32.value)
    testing.assert_equal(cmd.get_uint32("num"), UInt32(0))


def test_uint64():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.uint64(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup[FType.UInt64]("num")
    testing.assert_equal(flag[].type.value, FType.UInt64.value)
    testing.assert_equal(cmd.get_uint64("num"), UInt64(0))


def test_float16():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.float16(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup[FType.Float16]("num")
    testing.assert_equal(flag[].type.value, FType.Float16.value)
    testing.assert_equal(cmd.get_float16("num"), Float16(0))


def test_float32():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.float32(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup[FType.Float32]("num")
    testing.assert_equal(flag[].type.value, FType.Float32.value)
    testing.assert_equal(cmd.get_float32("num"), Float32(0))


def test_float64():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            Flag.float64(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup[FType.Float64]("num")
    testing.assert_equal(flag[].type.value, FType.Float64.value)
    testing.assert_equal(cmd.get_float64("num"), Float64(0))


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
    testing.assert_equal(flag[].type.value, FType.StringList.value)
    testing.assert_equal(cmd.get_string_list("num"), List[String]("a", "b"))


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
    testing.assert_equal(flag[].type.value, FType.IntList.value)

    var result = cmd.get_int_list("num")
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
    testing.assert_equal(flag[].type.value, FType.Float64List.value)

    var result = cmd.get_float64_list("num")
    testing.assert_equal(result[0], Float64(0))
    testing.assert_equal(result[1], Float64(1))
