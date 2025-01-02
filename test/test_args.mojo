from memory import ArcPointer
import testing
from prism import Command, Context
from prism.args import (
    no_args,
    valid_args,
    arbitrary_args,
    minimum_n_args,
    maximum_n_args,
    exact_args,
    range_args,
    match_all,
    ArgValidatorFn,
)


fn dummy(ctx: Context) -> None:
    return None


def test_no_args():
    ctx = Context(
        args=List[String]("abc"),
        command=Command(name="root", usage="Base command.", run=dummy),
    )
    with testing.assert_raises(contains="does not take any arguments."):
        no_args(ctx)


def test_valid_args():
    ctx = Context(
        args=List[String]("abc"),
        command=Command(name="root", usage="Base command.", run=dummy, valid_args=List[String]("Pineapple")),
    )
    with testing.assert_raises(contains="Invalid argument: `abc`"):
        valid_args(ctx)


def test_arbitrary_args():
    ctx = Context(
        command=Command(name="root", usage="Base command.", run=dummy),
        args=List[String]("abc", "blah", "blah")
    )

    # It should not raise an error, ever.
    arbitrary_args(ctx)


def test_minimum_n_args():
    ctx = Context(
        command=Command(name="root", usage="Base command.", run=dummy),
        args=List[String]("abc", "123")
    )
    with testing.assert_raises(contains="accepts at least 3 argument(s). Received: 2."):
        minimum_n_args[3]()(ctx)


def test_maximum_n_args():
    ctx = Context(
        command=Command(name="root", usage="Base command.", run=dummy),
        args=List[String]("abc", "123")
    )
    with testing.assert_raises(contains="accepts at most 1 argument(s). Received: 2."):
        maximum_n_args[1]()(ctx)


def test_exact_args():
    ctx = Context(
        command=Command(name="root", usage="Base command.", run=dummy),
        args=List[String]("abc", "123")
    )
    with testing.assert_raises(contains="accepts exactly 1 argument(s). Received: 2."):
        exact_args[1]()(ctx)


def test_range_args():
    ctx = Context(
        command=Command(name="root", usage="Base command.", run=dummy),
        args=List[String]("abc", "123")
    )
    with testing.assert_raises(contains="accepts between 0 to 1 argument(s). Received: 2."):
        range_args[0, 1]()(ctx)


def test_match_all():
    ctx = Context(
        command=Command(name="root", usage="Base command.", run=dummy, valid_args=List[String]("Pineapple")),
        args=List[String]("abc", "123")
    )
    with testing.assert_raises(contains="accepts between 0 to 1 argument(s). Received: 2."):
        match_all[range_args[0, 1](), valid_args]()(ctx)
