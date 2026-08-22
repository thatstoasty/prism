from std import testing
from prism.flag import Flag
from std.testing import TestSuite

from prism import ArgSet, Command, FlagSet


def dummy(args: ArgSet, flags: FlagSet) -> None:
    return None


def test_gets() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.new[String](name="key", usage="usage"),
            Flag.new[Bool](name="flag", usage="usage"),
        ],
    )

    var args: List[String] = ["--key=value", "positional", "--flag"]
    _ = cmd.flags.from_args(args)
    testing.assert_equal(cmd.flags.get[String]("key").value(), "value")
    testing.assert_equal(cmd.flags.get[Bool]("flag").value(), True)


def test_parse() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.new[String](name="key", usage="usage"),
            Flag.new[Bool](name="flag", usage="usage"),
        ],
    )
    var args: List[String] = ["--key=value"]
    remaining_args = cmd.flags.from_args(args)
    testing.assert_equal(len(remaining_args), 0)


def test_unicode_flag_name() raises:
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.new[String](name="cléf", usage="usage"),
        ],
    )

    var args: List[String] = ["--cléf=valeur", "positional"]
    _ = cmd.flags.from_args(args)
    testing.assert_equal(cmd.flags.get[String]("cléf").value(), "valeur")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
