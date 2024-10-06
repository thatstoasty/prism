from memory import Arc
from .command import Command


@value
struct Context:
    var command: Arc[Command]
    var args: List[String]
