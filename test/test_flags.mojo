from std import testing
from prism.flag import Flag
from std.testing import TestSuite

from prism import Command, FlagSet


def dummy(args: List[String], flags: FlagSet) -> None:
    return None


def test_gets() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.string(name="key", usage="usage"),
            Flag.bool(name="flag", usage="usage"),
        ],
    )

    var args: List[String] = ["--key=value", "positional", "--flag"]
    _ = cmd.flags.from_args(args)
    testing.assert_equal(cmd.flags.get_string("key").value(), "value")
    testing.assert_equal(cmd.flags.get_bool("flag").value(), True)


def test_parse() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.string(name="key", usage="usage"),
            Flag.bool(name="flag", usage="usage"),
        ],
    )
    var args: List[String] = ["--key=value"]
    remaining_args = cmd.flags.from_args(args)
    testing.assert_equal(len(remaining_args), 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
