from .style import osc, st


fn notify(title: String, body: String):
    """Sends a notification to the terminal.
    
    Args:
        title: The title of the notification.
        body: The body of the notification.
    """
    print(osc + "777;notify;" + title + ";" + body + st, end="")
