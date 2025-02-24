from sys import exit
from collections import InlineArray
from collections.string import StaticString
from memory import ArcPointer


fn panic[W: Writable, //](message: W, code: Int = 1) -> None:
    """Panics with the given message.

    Args:
        message: The message to panic with.
        code: The exit code to use.
    """
    print(message, file=2)
    exit(code)


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


fn split(text: StaticString, sep: StaticString, max_split: Int = -1) -> List[String]:
    """Splits a string into a list of substrings.

    Args:
        text: The string to split.
        sep: The separator to split the string by.
        max_split: The maximum number of splits to perform.

    Returns:
        The list of substrings.
    """
    # TODO: StringSlice will support split in the next release (25.2), switch then.
    try:
        return String(text).split(sep, max_split)
    except:
        return List[String](String(text))


fn string_to_bool(value: String) -> Bool:
    """Converts a string to a boolean.

    Args:
        value: The string to convert to a boolean.

    Returns:
        The boolean equivalent of the string.
    """
    return value in InlineArray[String, 3]("true", "True", "1")


fn to_string[T: WritableCollectionElement](vector: List[ArcPointer[T]]) -> String:
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
        result.write(vector[i][])
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
