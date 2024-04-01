from collections.dict import Dict, KeyElement, DictEntry


alias FATAL = 0
alias ERROR = 1
alias WARN = 2
alias INFO = 3
alias DEBUG = 4

alias LEVEL_MAPPING = List[String](
    "FATAL",
    "ERROR",
    "WARN",
    "INFO",
    "DEBUG",
)


@value
struct StringKey(KeyElement):
    var s: String

    fn __init__(inout self, owned s: String):
        self.s = s ^

    fn __init__(inout self, s: StringLiteral):
        self.s = String(s)

    fn __hash__(self) -> Int:
        return hash(self.s)

    fn __eq__(self, other: Self) -> Bool:
        return self.s == other.s

    fn __ne__(self, other: Self) -> Bool:
        return self.s != other.s

    fn __str__(self) -> String:
        return self.s


alias Context = Dict[StringKey, String]
alias ContextPair = DictEntry[StringKey, String]
