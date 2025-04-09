from prism._util import panic


alias ExitFn = fn (Error) -> None
"""The function to call when an error occurs."""


fn default_exit(e: Error) -> None:
    """The default function to call when an error occurs.

    Args:
        e: The error that occurred.
    """
    panic(e)
