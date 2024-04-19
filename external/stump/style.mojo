from collections.dict import Dict, KeyElement, DictEntry
from external.mist import TerminalStyle, Profile, TRUE_COLOR
from .base import StringKey, FATAL, INFO, DEBUG, WARN, ERROR


alias Sections = Dict[StringKey, TerminalStyle]


# TODO: For now setting profile each time, it doesn't seem like os.getenv works at comp time?
@value
struct Styles:
    var timestamp: TerminalStyle
    var message: TerminalStyle
    var key: TerminalStyle
    var value: TerminalStyle
    var separator: TerminalStyle
    var levels: Dict[StringKey, TerminalStyle]
    var keys: Dict[StringKey, TerminalStyle]
    var values: Dict[StringKey, TerminalStyle]

    fn __init__(
        inout self,
        *,
        timestamp: TerminalStyle = TerminalStyle.new(Profile(TRUE_COLOR)),
        message: TerminalStyle = TerminalStyle.new(Profile(TRUE_COLOR)),
        key: TerminalStyle = TerminalStyle.new(Profile(TRUE_COLOR)),
        value: TerminalStyle = TerminalStyle.new(Profile(TRUE_COLOR)),
        separator: TerminalStyle = TerminalStyle.new(Profile(TRUE_COLOR)),
        levels: Dict[StringKey, TerminalStyle] = Dict[StringKey, TerminalStyle](),
        keys: Dict[StringKey, TerminalStyle] = Dict[StringKey, TerminalStyle](),
        values: Dict[StringKey, TerminalStyle] = Dict[StringKey, TerminalStyle](),
    ):
        self.timestamp = timestamp
        self.message = message
        self.key = key
        self.value = value
        self.separator = separator
        self.levels = levels
        self.keys = keys
        self.values = values


fn get_default_styles() -> Styles:
    # Log level styles, by default just set colors
    var levels = Sections()
    levels["FATAL"] = TerminalStyle.new().foreground("#d4317d")
    levels["ERROR"] = TerminalStyle.new().foreground("#d48244")
    levels["INFO"] = TerminalStyle.new().foreground("#13ed84")
    levels["WARN"] = TerminalStyle.new().foreground("#decf2f")
    levels["DEBUG"] = TerminalStyle.new().foreground("#bd37db")

    return Styles(
        timestamp=TerminalStyle.new(),
        message=TerminalStyle.new(),
        key=TerminalStyle.new().faint(),
        value=TerminalStyle.new(),
        separator=TerminalStyle.new().faint(),
        levels=levels,
        keys=Dict[StringKey, TerminalStyle](),
        values=Dict[StringKey, TerminalStyle](),
    )


alias DEFAULT_STYLES = get_default_styles()
