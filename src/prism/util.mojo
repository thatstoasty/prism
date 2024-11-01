from collections import InlineList
from memory import Arc


fn split(text: String, sep: String, max_split: Int = -1) -> List[String]:
    try:
        return text.split(sep, max_split)
    except:
        return List[String](text)


fn string_to_bool(value: String) -> Bool:
    """Converts a string to a boolean.

    Args:
        value: The string to convert to a boolean.

    Returns:
        The boolean equivalent of the string.
    """
    alias truthy = InlineList[String, 3]("true", "True", "1")
    for i in range(len(truthy)):
        if value == truthy[i]:
            return True
    return False


fn string_to_float(s: String) raises -> Float64:
    try:
        # locate decimal point
        dot_pos = s.find(".")
        # grab the integer part of the number
        int_str = s[0:dot_pos]
        # grab the decimal part of the number
        num_str = s[dot_pos + 1 : len(s)]
        # set the numerator to be the integer equivalent
        numerator = atol(num_str)
        # construct denom_str to be "1" + "0"s for the length of the fraction
        denom_str = String()
        for _ in range(len(num_str)):
            denom_str += "0"
        denominator = atol("1" + denom_str)
        # school-level maths here :)
        frac = numerator / denominator

        # return the number as a Float64
        result = atol(int_str) + frac
        return result
    except:
        raise Error("string_to_float: Failed to convert " + s + " to a float.")


fn to_string[T: StringableCollectionElement](vector: List[Arc[T]]) -> String:
    result = String("[")
    for i in range(vector.size):
        flag = vector[i]
        result += str(flag[])
        if i < vector.size - 1:
            result += String(", ")
    result += String("]")
    return result


fn to_list(flag_names: VariadicListMem[String, _]) -> List[String]:
    result = List[String](capacity=len(flag_names))
    for name in flag_names:
        result.append(name[])

    return result
