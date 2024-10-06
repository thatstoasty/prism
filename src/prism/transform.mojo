from collections import Optional
from .flag_set import FlagSet
from .util import panic, string_to_bool, string_to_float


fn get_as_string(flag_set: FlagSet, name: String) -> Optional[String]:
    """Returns the value of a flag as a String. If it isn't set, then return the default value.

    Args:
        flag_set: The FlagSet to get the value from.
        name: The name of the flag to return.
    """
    var flag = flag_set.lookup_with_type(name, "String")
    if not flag:
        return None

    fn get(value: String) -> String:
        return value

    # TODO: inferring the return type in the parameter only works for String as of 24.5.
    # Will switch the other transform functions in the future when it works.
    return flag.value()[].get_with_transform[get]()


fn get_as_bool(flag_set: FlagSet, name: String) -> Optional[Bool]:
    """Returns the value of a flag as a Bool. If it isn't set, then return the default value.

    Args:
        flag_set: The FlagSet to get the value from.
        name: The name of the flag to return.
    """
    var result = flag_set.lookup_with_type(name, "Bool")
    if not result:
        return None

    var flag = result.value()
    if not flag[].value:
        return string_to_bool(flag[].default)

    return string_to_bool(flag[].value.value())


fn get_as_int(flag_set: FlagSet, name: String) -> Optional[Int]:
    """Returns the value of a flag as an Int. If it isn't set, then return the default value.

    Args:
        flag_set: The FlagSet to get the value from.
        name: The name of the flag to return.
    """
    var result = flag_set.lookup_with_type(name, "Int")
    if not result:
        return None

    var flag = result.value()

    # TODO: I don't like this swallowing up a failure to convert to int. Maybe return a tuple of optional and error?
    try:
        if not flag[].value:
            return atol(flag[].default)

        return atol(flag[].value.value())
    except:
        return None


fn get_as_int8(flag_set: FlagSet, name: String) -> Optional[Int8]:
    """Returns the value of a flag as a Int8. If it isn't set, then return the default value.

    Args:
        flag_set: The FlagSet to get the value from.
        name: The name of the flag to return.
    """
    var value = flag_set.get_as_int(name)
    if not value:
        return None

    return Int8(value.value())


fn get_as_int16(flag_set: FlagSet, name: String) -> Optional[Int16]:
    """Returns the value of a flag as a Int16. If it isn't set, then return the default value.

    Args:
        flag_set: The FlagSet to get the value from.
        name: The name of the flag to return.
    """
    var value = flag_set.get_as_int(name)
    if not value:
        return None

    return Int16(value.value())


fn get_as_int32(flag_set: FlagSet, name: String) -> Optional[Int32]:
    """Returns the value of a flag as a Int32. If it isn't set, then return the default value.

    Args:
        flag_set: The FlagSet to get the value from.
        name: The name of the flag to return.
    """
    var value = flag_set.get_as_int(name)
    if not value:
        return None

    return Int32(value.value())


fn get_as_int64(flag_set: FlagSet, name: String) -> Optional[Int64]:
    """Returns the value of a flag as a Int64. If it isn't set, then return the default value.

    Args:
        flag_set: The FlagSet to get the value from.
        name: The name of the flag to return.
    """
    var value = flag_set.get_as_int(name)
    if not value:
        return None

    return Int64(value.value())


fn get_as_uint8(flag_set: FlagSet, name: String) -> Optional[UInt8]:
    """Returns the value of a flag as a UInt8. If it isn't set, then return the default value.

    Args:
        flag_set: The FlagSet to get the value from.
        name: The name of the flag to return.
    """
    var value = flag_set.get_as_int(name)
    if not value:
        return None

    return UInt8(value.value())


fn get_as_uint16(flag_set: FlagSet, name: String) -> Optional[UInt16]:
    """Returns the value of a flag as a UInt16. If it isn't set, then return the default value.

    Args:
        flag_set: The FlagSet to get the value from.
        name: The name of the flag to return.
    """
    var value = flag_set.get_as_int(name)
    if not value:
        return None

    return UInt16(value.value())


fn get_as_uint32(flag_set: FlagSet, name: String) -> Optional[UInt32]:
    """Returns the value of a flag as a UInt32. If it isn't set, then return the default value.

    Args:
        flag_set: The FlagSet to get the value from.
        name: The name of the flag to return.
    """
    var value = flag_set.get_as_int(name)
    if not value:
        return None

    return UInt32(value.value())


fn get_as_uint64(flag_set: FlagSet, name: String) -> Optional[UInt64]:
    """Returns the value of a flag as a UInt64. If it isn't set, then return the default value.

    Args:
        flag_set: The FlagSet to get the value from.
        name: The name of the flag to return.
    """
    var value = flag_set.get_as_int(name)
    if not value:
        return None

    return UInt64(value.value())


fn get_as_float16(flag_set: FlagSet, name: String) -> Optional[Float16]:
    """Returns the value of a flag as a Float64. If it isn't set, then return the default value.

    Args:
        flag_set: The FlagSet to get the value from.
        name: The name of the flag to return.
    """
    var value = flag_set.get_as_float64(name)
    if not value:
        return None

    return value.value().cast[DType.float16]()


fn get_as_float32(flag_set: FlagSet, name: String) -> Optional[Float32]:
    """Returns the value of a flag as a Float64. If it isn't set, then return the default value.

    Args:
        flag_set: The FlagSet to get the value from.
        name: The name of the flag to return.
    """
    var value = flag_set.get_as_float64(name)
    if not value:
        return None

    return value.value().cast[DType.float32]()


fn get_as_float64(flag_set: FlagSet, name: String) -> Optional[Float64]:
    """Returns the value of a flag as a Float64. If it isn't set, then return the default value.

    Args:
        flag_set: The FlagSet to get the value from.
        name: The name of the flag to return.
    """
    var result = flag_set.lookup_with_type(name, "Float64")
    if not result:
        return None

    var flag = result.value()

    # TODO: I don't like this swallowing up a failure to convert to int. Maybe return a tuple of optional and error?
    try:
        if not flag[].value:
            return string_to_float(flag[].default)

        return string_to_float(flag[].value.value())
    except e:
        return None
