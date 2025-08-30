import testing
from memory import OwnedPointer
from prism.args import (  # match_all,
    arbitrary_args,
    exact_args,
    maximum_n_args,
    minimum_n_args,
    no_args,
    range_args,
    valid_args,
)

from prism import Command, FlagSet


fn dummy(args: List[String], flags: FlagSet) -> None:
    return None


def test_no_args():
    alias DUMMY_CMD = OwnedPointer(Command(name="root", usage="Base command.", run=dummy))
    with testing.assert_raises(contains="does not take any arguments."):
        no_args(
            cmd=DUMMY_CMD,
            args=["abc"],
        )


def test_valid_args():
    alias DUMMY_CMD = OwnedPointer(Command(name="root", usage="Base command.", run=dummy, valid_args=["Pineapple"]))
    with testing.assert_raises(contains="Invalid argument: `abc`"):
        valid_args(
            cmd=DUMMY_CMD,
            args=["abc"],
        )


def test_arbitrary_args():
    # It should not raise an error, ever.
    alias DUMMY_CMD = OwnedPointer(Command(name="root", usage="Base command.", run=dummy))
    arbitrary_args(cmd=DUMMY_CMD, args=["abc", "blah", "blah"])


def test_minimum_n_args():
    alias DUMMY_CMD = OwnedPointer(Command(name="root", usage="Base command.", run=dummy))
    with testing.assert_raises(contains="accepts at least 3 argument(s). Received: 2"):
        minimum_n_args[3]()(cmd=DUMMY_CMD, args=["abc", "123"])


def test_maximum_n_args():
    alias DUMMY_CMD = OwnedPointer(Command(name="root", usage="Base command.", run=dummy))
    with testing.assert_raises(contains="accepts at most 1 argument(s). Received: 2"):
        maximum_n_args[1]()(cmd=DUMMY_CMD, args=["abc", "123"])


def test_exact_args():
    alias DUMMY_CMD = OwnedPointer(Command(name="root", usage="Base command.", run=dummy))
    with testing.assert_raises(contains="accepts exactly 1 argument(s). Received: 2"):
        exact_args[1]()(cmd=DUMMY_CMD, args=["abc", "123"])


def test_range_args():
    alias DUMMY_CMD = OwnedPointer(Command(name="root", usage="Base command.", run=dummy))
    with testing.assert_raises(contains="accepts between 0 to 1 argument(s). Received: 2"):
        range_args[0, 1]()(cmd=DUMMY_CMD, args=["abc", "123"])


# def test_match_all():
#     with testing.assert_raises(contains="accepts between 0 to 1 argument(s). Received: 2"):
#         match_all[range_args[0, 1](), valid_args]()(
#             cmd=Command(name="root", usage="Base command.", run=dummy), args=["abc", "123"]
#         )
