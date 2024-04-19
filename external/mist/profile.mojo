import os
from .color import (
    NoColor,
    ANSIColor,
    ANSI256Color,
    RGBColor,
    AnyColor,
    hex_to_ansi256,
    ansi256_to_ansi,
    hex_to_rgb,
)


fn contains(vector: List[Int], value: Int) -> Bool:
    for i in range(vector.size):
        if vector[i] == value:
            return True
    return False


alias TRUE_COLOR: Int = 0
alias ANSI256: Int = 1
alias ANSI: Int = 2
alias ASCII: Int = 3


# TODO: UNIX systems only for now. Need to add Windows, POSIX, and SOLARIS support.
fn get_color_profile() -> Profile:
    """Queries the terminal to determine the color profile it supports.
    ASCII, ANSI, ANSI256, or TRUE_COLOR.
    """
    # if not o.isTTY():
    # 	return Ascii
    if os.getenv("GOOGLE_CLOUD_SHELL", "false") == "true":
        return Profile(TRUE_COLOR)

    var term = os.getenv("TERM").lower()
    var color_term = os.getenv("COLORTERM").lower()

    # COLORTERM is used by some terminals to indicate TRUE_COLOR support.
    if color_term == "24bit":
        pass
    elif color_term == TRUE_COLOR:
        if term.startswith("screen"):
            # tmux supports TRUE_COLOR, screen only ANSI256
            if os.getenv("TERM_PROGRAM") != "tmux":
                return Profile(ANSI256)
            return Profile(TRUE_COLOR)
    elif color_term == "yes":
        pass
    elif color_term == "true":
        return Profile(ANSI256)

    # TERM is used by most terminals to indicate color support.
    if term == "xterm-kitty" or term == "wezterm" or term == "xterm-ghostty":
        return Profile(TRUE_COLOR)
    elif term == "linux":
        return Profile(ANSI)

    if "256color" in term:
        return Profile(ANSI256)

    if "color" in term:
        return Profile(ANSI)

    if ANSI in term:
        return Profile(ANSI)

    return Profile(ASCII)


@value
struct Profile:
    var value: Int

    fn __init__(inout self, value: Int) -> None:
        """
        Initialize a new profile with the given profile type.

        Args:
            value: The setting to use for this profile. Valid values: [TRUE_COLOR, ANSI256, ANSI, ASCII].
        """
        var valid = List[Int](TRUE_COLOR, ANSI256, ANSI, ASCII)
        if not contains(valid, value):
            self.value = TRUE_COLOR
            return

        self.value = value

    fn __init__(inout self) -> None:
        """
        Initialize a new profile with the given profile type.
        """
        self = get_color_profile()

    fn convert(self, color: AnyColor) -> AnyColor:
        """Degrades a color based on the terminal profile.

        Args:
            color: The color to convert to the current profile.
        """
        if self.value == ASCII:
            return NoColor()

        if color.isa[NoColor]():
            return color.get[NoColor]()[]
        elif color.isa[ANSIColor]():
            return color.get[ANSIColor]()[]
        elif color.isa[ANSI256Color]():
            if self.value == ANSI:
                return ansi256_to_ansi(color.get[ANSIColor]()[].value)

            return color.get[ANSI256Color]()[]
        elif color.isa[RGBColor]():
            var h = hex_to_rgb(color.get[RGBColor]()[].value)

            if self.value != TRUE_COLOR:
                var ansi256 = hex_to_ansi256(h)
                if self.value == ANSI:
                    return ansi256_to_ansi(ansi256.value)

                return ansi256

            return color.get[RGBColor]()[]

        # If it somehow gets here, just return No Color until I can figure out how to just return whatever color was passed in.
        return color.get[NoColor]()[]

    fn color(self, value: String) -> AnyColor:
        """Color creates a Color from a string. Valid inputs are hex colors, as well as
        ANSI color codes (0-15, 16-255). If an invalid input is passed in, NoColor() is returned which will not apply any coloring.

        Args:
            value: The string to convert to a color.
        """
        if len(value) == 0:
            return NoColor()

        if self.value == ASCII:
            return NoColor()

        if value[0] == "#":
            var c = RGBColor(value)
            return self.convert(c)
        else:
            var i = 0
            try:
                i = atol(value)
            except e:
                return NoColor()

            if i < 16:
                var c = ANSIColor(i)
                return self.convert(c)
            elif i < 256:
                var c = ANSI256Color(i)
                return self.convert(c)

        return NoColor()
