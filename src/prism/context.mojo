from memory import Arc
from .command import Command


struct Context:
    var command: Arc[Command]
    var args: List[String]

    def __init__(inout self, command: Arc[Command], args: List[String]) -> None:
        self.command = command
        self.args = args
