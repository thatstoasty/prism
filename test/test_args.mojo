from std import testing
from std.memory import OwnedPointer
from prism.args import (  # match_all,
    arbitrary_args,
    exact_args,
    maximum_n_args,
    minimum_n_args,
    no_args,
    range_args,
    valid_args,
    match_all,
)
from std.testing import TestSuite

from prism import Command, FlagSet


def dummy(args: List[String], flags: FlagSet) -> None:
    return None


def test_no_args() raises:
    var DUMMY_CMD = OwnedPointer(Command(name="root", usage="Base command.", run=dummy))
    with testing.assert_raises(contains="does not take any arguments."):
        no_args(
            args=["abc"],
            valid_args=DUMMY_CMD[].valid_args
        )


def test_valid_args() raises:
    var DUMMY_CMD = OwnedPointer(Command(name="root", usage="Base command.", run=dummy, valid_args=["Pineapple"]))
    with testing.assert_raises(contains="Invalid argument: `abc`"):
        valid_args(
            args=["abc"],
            valid_args=DUMMY_CMD[].valid_args
        )


def test_arbitrary_args() raises:
    # It should not raise an error, ever.
    var DUMMY_CMD = OwnedPointer(Command(name="root", usage="Base command.", run=dummy))
    arbitrary_args(args=["abc", "blah", "blah"], valid_args=DUMMY_CMD[].valid_args)


def test_minimum_n_args() raises:
    var DUMMY_CMD = OwnedPointer(Command(name="root", usage="Base command.", run=dummy))
    with testing.assert_raises(contains="accepts at least 3 argument(s). Received: 2"):
        minimum_n_args[3]()(args=["abc", "123"], valid_args=DUMMY_CMD[].valid_args)


def test_maximum_n_args() raises:
    var DUMMY_CMD = OwnedPointer(Command(name="root", usage="Base command.", run=dummy))
    with testing.assert_raises(contains="accepts at most 1 argument(s). Received: 2"):
        maximum_n_args[1]()(args=["abc", "123"], valid_args=DUMMY_CMD[].valid_args)


def test_exact_args() raises:
    var DUMMY_CMD = OwnedPointer(Command(name="root", usage="Base command.", run=dummy))
    with testing.assert_raises(contains="accepts exactly 1 argument(s). Received: 2"):
        exact_args[1]()(args=["abc", "123"], valid_args=DUMMY_CMD[].valid_args)


def test_range_args() raises:
    var DUMMY_CMD = OwnedPointer(Command(name="root", usage="Base command.", run=dummy))
    with testing.assert_raises(contains="accepts between 0 to 1 argument(s). Received: 2"):
        range_args[0, 1]()(args=["abc", "123"], valid_args=DUMMY_CMD[].valid_args)


# def test_match_all() raises:
#     with testing.assert_raises(contains="accepts between 0 to 1 argument(s). Received: 2"):
#         match_all[range_args[0, 1](), valid_args]()(
#             args=["abc", "123"], valid_args=[]
#         )


fn main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
