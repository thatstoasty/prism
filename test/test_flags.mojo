from memory import ArcPointer
import testing
import prism
from prism import Command, Context
from prism.flag import Flag
from prism.flag_set import string_to_bool, from_args
from prism.flag_parser import FlagParser


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

    var args = List[String]("--key=value", "positional", "--flag")
    _ = from_args(cmd.flags, args)
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
    name, value, increment_by = parser.parse_flag("--key", List[String]("--key", "value"), cmd.flags)
    testing.assert_equal(name, "key")
    testing.assert_equal(value, "value")
    testing.assert_equal(increment_by, 2)

    name, value, increment_by = parser.parse_flag(String("--key=value"), List[String]("--key=value"), cmd.flags)
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
    name, value, increment_by = parser.parse_shorthand_flag("-k", List[String]("-k", "value"), cmd.flags)
    testing.assert_equal(name, "key")
    testing.assert_equal(value, "value")
    testing.assert_equal(increment_by, 2)

    name, value, increment_by = parser.parse_shorthand_flag("-k=value", List[String]("-k=value"), cmd.flags)
    testing.assert_equal(name, "key")
    testing.assert_equal(value, "value")
    testing.assert_equal(increment_by, 1)
