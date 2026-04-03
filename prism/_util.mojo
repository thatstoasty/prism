from std.sys import exit, stderr


def panic(message: Some[Writable], code: Int = 1) -> None:
    """Panics with the given message.

    Args:
        message: The message to panic with.
        code: The exit code to use.
    """
    print(message, file=stderr)
    exit(code)


def string_to_bool(value: String) -> Bool:
    """Converts a string to a boolean.

    Args:
        value: The string to convert to a boolean.

    Returns:
        The boolean equivalent of the string.
    """
    return value == "true" or value == "True" or value == "1"
