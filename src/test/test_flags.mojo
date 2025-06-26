import testing
from prism import Command, FlagSet
from prism.flag import Flag


fn dummy(args: List[String], flags: FlagSet) -> None:
    return None


def test_gets():
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


def test_parse():
    var cmd = Command(
        name="root",
        usage="Base command.",
        run=dummy,
        flags=[
            Flag.string(name="key", usage="usage"),
            Flag.bool(name="flag", usage="usage"),
        ],
    )

    remaining_args = cmd.flags.from_args(List[String]("--key=value"))
    testing.assert_equal(len(remaining_args), 0)
