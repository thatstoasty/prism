from collections import Dict
from prism._flag_group import (
    validate_required_flag_group,
    get_set_flags,
    extract_keys,
    validate_one_required_flag_group,
    validate_mutually_exclusive_flag_group,
)
import testing


fn make_test_data(required: Bool, alternative: Bool) -> Dict[String, Dict[String, Bool]]:
    var data = Dict[String, Dict[String, Bool]]()
    var entry = Dict[String, Bool]()
    entry["required"] = required
    entry["alternative"] = alternative
    data["group1"] = entry
    return data^


fn test_validate_required_flag_group() raises -> None:
    var data = make_test_data(True, True)
    validate_required_flag_group(data)


fn test_validate_required_flag_group_not_all_set() raises -> None:
    var data = make_test_data(True, False)
    with testing.assert_raises(contains="If any flags in the group"):
        validate_required_flag_group(data)


fn test_validate_one_required_flag_group() raises -> None:
    var data = make_test_data(True, False)
    validate_one_required_flag_group(data)


fn test_validate_one_required_flag_group_none_set() raises -> None:
    var data = make_test_data(False, False)
    with testing.assert_raises(contains="At least one of the flags in the group"):
        validate_one_required_flag_group(data)


fn test_validate_mutually_exclusive_flag_group() raises -> None:
    var data = make_test_data(True, False)
    validate_mutually_exclusive_flag_group(data)


fn test_validate_mutually_exclusive_flag_group_multiple_set() raises -> None:
    var data = make_test_data(True, True)
    with testing.assert_raises(contains="If any flags in the group"):
        validate_mutually_exclusive_flag_group(data)


fn test_get_set_flags() raises -> None:
    var data = make_test_data(False, False)
    for pair in data.items():
        testing.assert_equal(get_set_flags(pair[]), List[String](), "Expected no flags to be set.")

    data["group1"]["required"] = True
    for pair in data.items():
        testing.assert_equal(get_set_flags(pair[]), List[String]("required"), "Expected the required flag to be set.")

    data["group1"]["alternative"] = True
    for pair in data.items():
        testing.assert_equal(
            get_set_flags(pair[]),
            List[String]("required", "alternative"),
            "Expected the required and alternative flag to be set.",
        )


fn test_extract_keys() raises -> None:
    var data = make_test_data(False, False)

    for pair in data.items():
        testing.assert_equal(
            extract_keys(pair[]),
            List[String]("alternative", "required"),
            "Expected the alternative and required flag names.",
        )
