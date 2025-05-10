from sys import stderr


alias WriterFn = fn (String) -> None
"""The function to call when writing output or errors."""


fn default_output_writer(arg: String) -> None:
    """Writes an output message to stdout.

    Args:
        arg: The output message to write.
    """
    print(arg)


fn default_error_writer(arg: String) -> None:
    """Writes an error message to stderr.

    Args:
        arg: The error message to write.
    """
    print(arg, file=stderr)
