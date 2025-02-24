from memory import ArcPointer
from collections.string import StaticString
import testing
import prism
from prism import Command, Context
from prism.flag import Flag, string_flag, bool_flag, int_flag, int8_flag, int16_flag, int32_flag, int64_flag, uint_flag, uint8_flag, uint16_flag, uint32_flag, uint64_flag, float16_flag, float32_flag, float64_flag, string_list_flag, int_list_flag, float64_list_flag
from prism._flag_set import string_to_bool
from prism._flag_parser import FlagParser


def test_string_to_bool():
    alias truthy = List[String]("true", "True", "1")
    for t in truthy:
        testing.assert_true(string_to_bool(t[]))


fn dummy(ctx: Context) -> None:
    return None

def test_get_flags():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.string_flag(name="key", usage="usage", default="default"),
            prism.bool_flag(name="flag", usage="usage", default=False),
        ),
    )

    var args = List[StaticString]("--key=value", "positional", "--flag")
    _ = cmd.flags.from_args(args)
    testing.assert_equal(cmd.get_string("key"), "value")
    testing.assert_equal(cmd.get_bool("flag"), True)


def test_parse_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.string_flag(name="key", usage="usage", default="default"),
            prism.bool_flag(name="flag", usage="usage", default=False),
        ),
    )

    parser = FlagParser()
    name, value, increment_by = parser.parse_flag("--key", List[StaticString]("--key", "value"), cmd.flags)
    testing.assert_equal(name, "key")
    testing.assert_equal(value, "value")
    testing.assert_equal(increment_by, 2)

    name, value, increment_by = parser.parse_flag("--key=value", List[StaticString]("--key=value"), cmd.flags)
    testing.assert_equal(name, "key")
    testing.assert_equal(value, "value")
    testing.assert_equal(increment_by, 1)


def test_parse_shorthand_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.string_flag(name="key", usage="usage", default="default", shorthand="k"),
            prism.bool_flag(name="flag", usage="usage", default=False, shorthand="f"),
        ),
    )

    parser = FlagParser()
    name, value, increment_by = parser.parse_shorthand_flag("-k", List[StaticString]("-k", "value"), cmd.flags)
    testing.assert_equal(name, "key")
    testing.assert_equal(value, "value")
    testing.assert_equal(increment_by, 2)

    name, value, increment_by = parser.parse_shorthand_flag("-k=value", List[StaticString]("-k=value"), cmd.flags)
    testing.assert_equal(name, "key")
    testing.assert_equal(value, "value")
    testing.assert_equal(increment_by, 1)


def test_string_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.string_flag(name="key", usage="usage", default="default"),
        ),
    )

    var flag = cmd.flags.lookup["String"]("key")
    testing.assert_equal(flag[].type, "String")
    testing.assert_equal(cmd.get_string("key"), "default")


def test_bool_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.bool_flag(name="flag", usage="usage", default=False),
        ),
    )

    var flag = cmd.flags.lookup["Bool"]("flag")
    testing.assert_equal(flag[].type, "Bool")
    testing.assert_equal(cmd.get_bool("flag"), False)


def test_int_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.int_flag(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup["Int"]("num")
    testing.assert_equal(flag[].type, "Int")
    testing.assert_equal(cmd.get_int("num"), 0)


def test_int8_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.int8_flag(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup["Int8"]("num")
    testing.assert_equal(flag[].type, "Int8")
    testing.assert_equal(cmd.get_int8("num"), Int8(0))


def test_int16_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.int16_flag(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup["Int16"]("num")
    testing.assert_equal(flag[].type, "Int16")
    testing.assert_equal(cmd.get_int16("num"), Int16(0))


def test_int32_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.int32_flag(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup["Int32"]("num")
    testing.assert_equal(flag[].type, "Int32")
    testing.assert_equal(cmd.get_int32("num"), Int32(0))


def test_int64_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.int64_flag(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup["Int64"]("num")
    testing.assert_equal(flag[].type, "Int64")
    testing.assert_equal(cmd.get_int64("num"), Int64(0))


def test_uint_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.uint_flag(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup["UInt"]("num")
    testing.assert_equal(flag[].type, "UInt")
    testing.assert_equal(cmd.get_uint("num"), UInt(0))


def test_uint8_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.uint8_flag(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup["UInt8"]("num")
    testing.assert_equal(flag[].type, "UInt8")
    testing.assert_equal(cmd.get_uint8("num"), UInt8(0))


def test_uint16_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.uint16_flag(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup["UInt16"]("num")
    testing.assert_equal(flag[].type, "UInt16")
    testing.assert_equal(cmd.get_uint16("num"), UInt16(0))


def test_uint32_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.uint32_flag(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup["UInt32"]("num")
    testing.assert_equal(flag[].type, "UInt32")
    testing.assert_equal(cmd.get_uint32("num"), UInt32(0))


def test_uint64_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.uint64_flag(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup["UInt64"]("num")
    testing.assert_equal(flag[].type, "UInt64")
    testing.assert_equal(cmd.get_uint64("num"), UInt64(0))


def test_float16_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.float16_flag(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup["Float16"]("num")
    testing.assert_equal(flag[].type, "Float16")
    testing.assert_equal(cmd.get_float16("num"), Float16(0))


def test_float32_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.float32_flag(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup["Float32"]("num")
    testing.assert_equal(flag[].type, "Float32")
    testing.assert_equal(cmd.get_float32("num"), Float32(0))


def test_float64_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.float64_flag(name="num", usage="usage", default=0),
        ),
    )

    var flag = cmd.flags.lookup["Float64"]("num")
    testing.assert_equal(flag[].type, "Float64")
    testing.assert_equal(cmd.get_float64("num"), Float64(0))


def test_string_list_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.string_list_flag(name="num", usage="usage", default=List[String]("a", "b")),
        ),
    )

    var flag = cmd.flags.lookup["StringList"]("num")
    testing.assert_equal(flag[].type, "StringList")
    testing.assert_equal(cmd.get_string_list("num"), List[String]("a", "b"))


def test_int_list_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.int_list_flag(name="num", usage="usage", default=List[Int, True](0, 1)),
        ),
    )

    var flag = cmd.flags.lookup["IntList"]("num")
    testing.assert_equal(flag[].type, "IntList")

    var result = cmd.get_int_list("num")
    testing.assert_equal(result[0], 0)
    testing.assert_equal(result[1], 1)


def test_float64_list_flag():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=List[Flag](
            prism.float64_list_flag(name="num", usage="usage", default=List[Float64, True](0, 1)),
        ),
    )

    var flag = cmd.flags.lookup["Float64List"]("num")
    testing.assert_equal(flag[].type, "Float64List")

    var result = cmd.get_float64_list("num")
    testing.assert_equal(result[0], Float64(0))
    testing.assert_equal(result[1], Float64(1))
