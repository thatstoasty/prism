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
