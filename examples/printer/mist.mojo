from time import sleep


fn sgr_format(n: String) -> String:
    """SGR formatting: https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters.
    """
    return chr(27) + String("[") + n + String("m")


@value
struct Properties:
    # Text colors
    var escape: String
    var BLUE: String
    var CYAN: String
    var GREEN: String
    var YELLOW: String
    var RED: String

    # Text formatting
    var BOLD: String
    var FAINT: String
    var UNDERLINE: String
    var BLINK: String
    var REVERSE: String
    var CROSSOUT: String
    var OVERLINE: String
    var ITALIC: String
    var INVERT: String

    # Background colors
    var BACKGROUND_BLACK: String
    var BACKGROUND_RED: String
    var BACKGROUND_GREEN: String
    var BACKGROUND_YELLOW: String
    var BACKGROUND_BLUE: String
    var BACKGROUND_PURPLE: String
    var BACKGROUND_CYAN: String
    var BACKGROUND_WHITE: String

    # Foreground colors
    var FOREGROUND_BLACK: String
    var FOREGROUND_RED: String
    var FOREGROUND_GREEN: String
    var FOREGROUND_YELLOW: String
    var FOREGROUND_BLUE: String
    var FOREGROUND_PURPLE: String
    var FOREGROUND_CYAN: String
    var FOREGROUND_WHITE: String

    # Other
    var RESET: String
    var CLEAR: String

    fn __init__(inout self):
        self.escape = chr(27)

        # Text colors
        self.BLUE = "94"
        self.CYAN = "96"
        self.GREEN = "92"
        self.YELLOW = "93"
        self.RED = "91"

        # Text formatting
        self.BOLD = "1"
        self.FAINT = "2"
        self.ITALIC = "3"
        self.UNDERLINE = "4"
        self.BLINK = "5"
        self.REVERSE = "7"
        self.CROSSOUT = "9"
        self.OVERLINE = "53"
        self.INVERT = "27"

        # Background colors
        self.BACKGROUND_BLACK = "40"
        self.BACKGROUND_RED = "41"
        self.BACKGROUND_GREEN = "42"
        self.BACKGROUND_YELLOW = "43"
        self.BACKGROUND_BLUE = "44"
        self.BACKGROUND_PURPLE = "45"
        self.BACKGROUND_CYAN = "46"
        self.BACKGROUND_WHITE = "47"

        # Foreground colors
        self.FOREGROUND_BLACK = self.escape + "[0;30m"
        self.FOREGROUND_RED = self.escape + "[0;31m"
        self.FOREGROUND_GREEN = self.escape + "[0;32m"
        self.FOREGROUND_YELLOW = self.escape + "[0;33m"
        self.FOREGROUND_BLUE = self.escape + "[0;34m"
        self.FOREGROUND_PURPLE = self.escape + "[0;35m"
        self.FOREGROUND_CYAN = self.escape + "[0;36m"
        self.FOREGROUND_WHITE = self.escape + "[0;37m"

        # Other
        # Reset terminal settings
        self.RESET = "0"

        # Clear terminal and return cursor to top left
        self.CLEAR = self.escape + "[2J" + self.escape + "[H"

    fn get_color(self, type: String) -> String:
        var code: String = ""
        if type == "blue":
            code = self.BLUE
        elif type == "cyan":
            code = self.CYAN
        elif type == "green":
            code = self.GREEN
        elif type == "yellow":
            code = self.YELLOW
        elif type == "red":
            code = self.RED
        else:
            code = self.RESET

        return sgr_format(code)

    fn get_formatting(self, type: StringLiteral) -> String:
        var code: String = ""
        if type == "bold":
            code = self.BOLD
        elif type == "italic":
            code = self.ITALIC
        elif type == "underline":
            code = self.UNDERLINE
        elif type == "blink":
            code = self.BLINK
        elif type == "reverse":
            code = self.REVERSE
        elif type == "crossout":
            code = self.CROSSOUT
        elif type == "overline":
            code = self.OVERLINE
        elif type == "invert":
            code = self.INVERT
        else:
            code = self.RESET

        return sgr_format(code)

    fn get_background_color(self, type: StringLiteral) -> String:
        var code: String = ""
        if type == "black":
            code = self.BACKGROUND_BLACK
        elif type == "red":
            code = self.BACKGROUND_RED
        elif type == "green":
            code = self.BACKGROUND_GREEN
        elif type == "yellow":
            code = self.BACKGROUND_YELLOW
        elif type == "blue":
            code = self.BACKGROUND_BLUE
        elif type == "purple":
            code = self.BACKGROUND_PURPLE
        elif type == "cyan":
            code = self.BACKGROUND_CYAN
        elif type == "white":
            code = self.BACKGROUND_WHITE
        else:
            code = self.RESET

        return code

    fn get_foreground_color(self, type: StringLiteral) -> String:
        var code: String = ""
        if type == "black":
            code = self.FOREGROUND_BLACK
        elif type == "red":
            code = self.FOREGROUND_RED
        elif type == "green":
            code = self.FOREGROUND_GREEN
        elif type == "yellow":
            code = self.FOREGROUND_YELLOW
        elif type == "blue":
            code = self.FOREGROUND_BLUE
        elif type == "purple":
            code = self.FOREGROUND_PURPLE
        elif type == "cyan":
            code = self.FOREGROUND_CYAN
        elif type == "white":
            code = self.FOREGROUND_WHITE
        else:
            code = self.RESET

        return code

    fn get_other(self, type: StringLiteral) -> String:
        var code: String = ""
        if type == "reset":
            code = self.RESET
        elif type == "clear":
            code = self.CLEAR
        else:
            code = self.RESET

        return code


@value
struct TerminalStyle:
    var styles: DynamicVector[String]
    var properties: Properties

    fn __init__(inout self):
        self.properties = Properties()
        self.styles = DynamicVector[String]()

    fn color(inout self, color: String) -> None:
        self.styles.push_back(self.properties.get_color(color))

    fn bold(inout self) -> None:
        self.styles.push_back(self.properties.BOLD)

    fn italic(inout self) -> None:
        self.styles.push_back(self.properties.ITALIC)

    fn underline(inout self) -> None:
        self.styles.push_back(self.properties.UNDERLINE)

    fn blink(inout self) -> None:
        self.styles.push_back(self.properties.BLINK)

    fn reverse(inout self) -> None:
        self.styles.push_back(self.properties.REVERSE)

    fn crossout(inout self) -> None:
        self.styles.push_back(self.properties.CROSSOUT)

    fn overline(inout self) -> None:
        self.styles.push_back(self.properties.OVERLINE)

    fn invert(inout self) -> None:
        self.styles.push_back(self.properties.INVERT)

    fn background(inout self, color: StringLiteral) -> None:
        self.styles.push_back(self.properties.get_background_color(color))

    fn foreground(inout self, color: StringLiteral) -> None:
        self.styles.push_back(self.properties.get_foreground_color(color))

    fn render(self, input: String) -> String:
        var styling = String("")
        for i in range(len(self.styles)):
            styling = styling + sgr_format(self.styles[i])

        # TODO: Still kind of buggy, a trailing m gets appended to the beginning of the input string. Haven't been able to fix.
        return styling + input + sgr_format(self.properties.get_other("reset"))
