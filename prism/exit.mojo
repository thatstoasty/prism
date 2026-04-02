from prism._util import panic


comptime ExitFn = def (Error) -> None
"""The function to call when an error occurs."""


def default_exit(e: Error) -> None:
    """The default function to call when an error occurs.

    Args:
        e: The error that occurred.
    """
    panic(e)
