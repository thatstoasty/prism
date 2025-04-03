from sys import exit
from collections import InlineArray


fn panic[W: Writable, //](message: W, code: Int = 1) -> None:
    """Panics with the given message.

    Args:
        message: The message to panic with.
        code: The exit code to use.
    """
    print(message, file=2)
    exit(code)


fn string_to_bool(value: String) -> Bool:
    """Converts a string to a boolean.

    Args:
        value: The string to convert to a boolean.

    Returns:
        The boolean equivalent of the string.
    """
    return value in InlineArray[String, 3]("true", "True", "1")
