from .style import osc, st


fn hyperlink(link: String, name: String) -> String:
    """Creates a hyperlink using OSC8.

    Args:
        link: The URL to link to.
        name: The text to display.

    Returns:
        The hyperlink text.
    """
    return osc + "8;;" + link + st + name + osc + "8;;" + st
