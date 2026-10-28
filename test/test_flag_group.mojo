from std import os, testing
from prism import FlagSet
from prism.flag import Annotation, Flag
from prism._flag_group import (
    extract_keys,
    get_set_flags,
    validate_mutually_exclusive_flag_group,
    validate_one_required_flag_group,
    validate_required_flag_group,
)
from std.testing import TestSuite


def make_test_data(required: Bool, alternative: Bool) -> Dict[String, Dict[String, Bool]]:
    return {"group1": {"required": required, "alternative": alternative}}


def test_validate_required_flag_group() raises -> None:
    var data = make_test_data(True, True)
    validate_required_flag_group(data)


def test_validate_required_flag_group_not_all_set() raises -> None:
    var data = make_test_data(True, False)
    with testing.assert_raises(contains="If any flags in the group"):
        validate_required_flag_group(data)


def test_validate_one_required_flag_group() raises -> None:
    var data = make_test_data(True, False)
    validate_one_required_flag_group(data)


def test_validate_one_required_flag_group_none_set() raises -> None:
    var data = make_test_data(False, False)
    with testing.assert_raises(contains="At least one of the flags in the group"):
        validate_one_required_flag_group(data)


def test_validate_mutually_exclusive_flag_group() raises -> None:
    var data = make_test_data(True, False)
    validate_mutually_exclusive_flag_group(data)


def test_validate_mutually_exclusive_flag_group_multiple_set() raises -> None:
    var data = make_test_data(True, True)
    with testing.assert_raises(contains="If any flags in the group"):
        validate_mutually_exclusive_flag_group(data)


def test_get_set_flags() raises -> None:
    var data = make_test_data(False, False)
    for pair in data.items():
        testing.assert_equal(get_set_flags(pair.value), [], "Expected no flags to be set.")

    data["group1"]["required"] = True
    for pair in data.items():
        testing.assert_equal(get_set_flags(pair.value), ["required"], "Expected the required flag to be set.")

    data["group1"]["alternative"] = True
    for pair in data.items():
        testing.assert_equal(
            get_set_flags(pair.value),
            ["required", "alternative"],
            "Expected the required and alternative flag to be set.",
        )


def test_extract_keys() raises -> None:
    var data = make_test_data(False, False)

    for pair in data.items():
        testing.assert_equal(
            extract_keys(pair.value),
            ["alternative", "required"],
            "Expected the alternative and required flag names.",
        )


def _exclusive_pair() raises -> FlagSet:
    var flags: List[Flag] = [
        Flag.new[String](
            name="token", usage="Token.", environment_variable=String("PRISM_TEST_EXCLUSIVE_TOKEN")
        ),
        Flag.new[String](
            name="password", usage="Password.", environment_variable=String("PRISM_TEST_EXCLUSIVE_PASSWORD")
        ),
    ]
    var flag_set = FlagSet(flags^)
    flag_set.set_annotation[Annotation.mutually_exclusive]("token", "token password")
    flag_set.set_annotation[Annotation.mutually_exclusive]("password", "token password")
    return flag_set^


def test_command_line_overrides_environment_for_exclusive_flags() raises -> None:
    # Regression: a flag filled from its environment variable counted as set, so passing
    # `--password` failed whenever a `TOKEN` variable happened to be set.
    _ = os.setenv("PRISM_TEST_EXCLUSIVE_TOKEN", "from-env")
    var flag_set = _exclusive_pair()
    var args: List[String] = ["--password", "x"]
    _ = flag_set.from_args(Span(args))
    _ = os.unsetenv("PRISM_TEST_EXCLUSIVE_TOKEN")

    flag_set.validate_flag_groups()


def test_exclusive_flags_from_environment_still_conflict() raises -> None:
    _ = os.setenv("PRISM_TEST_EXCLUSIVE_TOKEN", "a")
    _ = os.setenv("PRISM_TEST_EXCLUSIVE_PASSWORD", "b")
    var flag_set = _exclusive_pair()
    _ = flag_set.from_args(Span(List[String]()))
    _ = os.unsetenv("PRISM_TEST_EXCLUSIVE_TOKEN")
    _ = os.unsetenv("PRISM_TEST_EXCLUSIVE_PASSWORD")

    with testing.assert_raises(contains="none of the others can be"):
        flag_set.validate_flag_groups()


def test_exclusive_flags_on_command_line_still_conflict() raises -> None:
    var flag_set = _exclusive_pair()
    var args: List[String] = ["--token", "a", "--password", "b"]
    _ = flag_set.from_args(Span(args))

    with testing.assert_raises(contains="none of the others can be"):
        flag_set.validate_flag_groups()


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
