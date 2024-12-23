from collections import InlineList
from memory import ArcPointerPointer


fn split(text: String, sep: String, max_split: Int = -1) -> List[String]:
    """Splits a string into a list of substrings.

    Args:
        text: The string to split.
        sep: The separator to split the string by.
        max_split: The maximum number of splits to perform.
    
    Returns:
        The list of substrings.
    """
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
    return value in ["true", "True", "1"]


fn to_string[T: StringableCollectionElement](vector: List[ArcPointer[T]]) -> String:
    """Converts a vector to a string.

    Parameters:
        T: The type of the vector elements.

    Args:
        vector: The vector to convert to a string.
    
    Returns:
        The string representation of the vector.
    """
    var result = String("[")
    for i in range(vector.size):
        flag = vector[i]
        result.write(str(flag[]))
        if i < vector.size - 1:
            result.write(", ")
    result.write("]")
    return result


fn to_list(flag_names: VariadicListMem[String, _]) -> List[String]:
    """Converts a variadic list to a list.

    Args:
        flag_names: The variadic list to convert to a list.
    
    Returns:
        The list representation of the variadic list.
    """
    var result = List[String](capacity=len(flag_names))
    for name in flag_names:
        result.append(name[])
    return result
