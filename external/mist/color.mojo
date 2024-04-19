from collections.dict import Dict, KeyElement
from utils.variant import Variant
import external.hue
from external.hue.math import max_float64
from .ansi_colors import ANSI_HEX_CODES


@value
struct StringKey(KeyElement):
    var s: String

    fn __init__(inout self, owned s: String):
        self.s = s^

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


alias foreground = "38"
alias background = "48"
alias AnyColor = Variant[NoColor, ANSIColor, ANSI256Color, RGBColor]


trait Equalable:
    fn __eq__(self: Self, other: Self) -> Bool:
        ...


trait NotEqualable:
    fn __ne__(self: Self, other: Self) -> Bool:
        ...


trait Color(Movable, Copyable, Equalable, NotEqualable, CollectionElement):
    fn sequence(self, is_background: Bool) -> String:
        """Sequence returns the ANSI Sequence for the color."""
        ...


@value
struct NoColor(Color, Stringable):
    fn __eq__(self, other: NoColor) -> Bool:
        return True

    fn __ne__(self, other: NoColor) -> Bool:
        return False

    fn sequence(self, is_background: Bool) -> String:
        return ""

    fn __str__(self) -> String:
        """String returns the ANSI Sequence for the color and the text."""
        return ""


@value
struct ANSIColor(Color, Stringable):
    """ANSIColor is a color (0-15) as defined by the ANSI Standard."""

    var value: Int

    fn __eq__(self, other: ANSIColor) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: ANSIColor) -> Bool:
        return self.value != other.value

    fn sequence(self, is_background: Bool) -> String:
        """Returns the ANSI Sequence for the color and the text.

        Args:
            is_background: Whether the color is a background color.
        """
        var modifier: Int = 0
        if is_background:
            modifier += 10

        if self.value < 8:
            return String(modifier + self.value + 30)
        else:
            return String(modifier + self.value - 8 + 90)

    fn __str__(self) -> String:
        """String returns the ANSI Sequence for the color and the text."""
        return ANSI_HEX_CODES[self.value]

    fn convert_to_rgb(self) -> hue.Color:
        """Converts an ANSI color to hue.Color by looking up the hex value and converting it."""
        var hex: String = ANSI_HEX_CODES[self.value]

        return hex_to_rgb(hex)


@value
struct ANSI256Color(Color, Stringable):
    """ANSI256Color is a color (16-255) as defined by the ANSI Standard."""

    var value: Int

    fn __eq__(self, other: ANSI256Color) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: ANSI256Color) -> Bool:
        return self.value != other.value

    fn sequence(self, is_background: Bool) -> String:
        """Returns the ANSI Sequence for the color and the text.

        Args:
            is_background: Whether the color is a background color.
        """
        var prefix: String = foreground
        if is_background:
            prefix = background

        return prefix + ";5;" + String(self.value)

    fn __str__(self) -> String:
        """String returns the ANSI Sequence for the color and the text."""
        return ANSI_HEX_CODES[self.value]

    fn convert_to_rgb(self) -> hue.Color:
        """Converts an ANSI color to hue.Color by looking up the hex value and converting it."""
        var hex: String = ANSI_HEX_CODES[self.value]

        return hex_to_rgb(hex)


# fn convert_base10_to_base16(value: Int) -> String:
#     """Converts a base 10 number to base 16."""
#     var sum: Int = value
#     while value > 1:
#         var remainder = sum % 16
#         sum = sum / 16
#         print(remainder, sum)

#         print(remainder * 16)


fn convert_base16_to_base10(value: String) -> Int:
    """Converts a base 16 number to base 10.
    https://www.catalyst2.com/knowledgebase/dictionary/hexadecimal-base-16-numbers/#:~:text=To%20convert%20the%20hex%20number,16%20%2B%200%20%3D%2016).

    Args:
        value: Hexadecimal number.

    Returns:
        Base 10 number.
    """
    var mapping = Dict[StringKey, Int]()
    mapping["0"] = 0
    mapping["1"] = 1
    mapping["2"] = 2
    mapping["3"] = 3
    mapping["4"] = 4
    mapping["5"] = 5
    mapping["6"] = 6
    mapping["7"] = 7
    mapping["8"] = 8
    mapping["9"] = 9
    mapping["a"] = 10
    mapping["b"] = 11
    mapping["c"] = 12
    mapping["d"] = 13
    mapping["e"] = 14
    mapping["f"] = 15

    # We assume mapping.find always returns a value considering the value passed in is a valid hex value
    # and the mapping has all the values.
    var length = len(value)
    var total: Int = 0
    for i in range(length - 1, -1, -1):
        var exponent = length - 1 - i
        total += mapping.find(value[i]).value() * (16**exponent)

    return total


fn hex_to_rgb(value: String) -> hue.Color:
    """Converts a hex color to hue.Color.

    Args:
        value: Hex color value.

    Returns:
        hue.Color color.
    """
    var hex = value[1:]
    var indices = List[Int](0, 2, 4)
    var results = List[Int]()
    for i in indices:
        results.append(convert_base16_to_base10(hex[i[] : i[] + 2]))

    return hue.Color(results[0], results[1], results[2])


@value
struct RGBColor(Color):
    """RGBColor is a hex-encoded color, e.g. '#abcdef'."""

    var value: String

    fn __init__(inout self, value: String):
        self.value = value.lower()

    fn __eq__(self, other: RGBColor) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: RGBColor) -> Bool:
        return self.value != other.value

    fn sequence(self, is_background: Bool) -> String:
        """Returns the ANSI Sequence for the color and the text.

        Args:
            is_background: Whether the color is a background color.
        """
        var rgb = hex_to_rgb(self.value)

        var prefix = foreground
        if is_background:
            prefix = background

        return prefix + String(";2;") + String(int(rgb.R)) + ";" + String(int(rgb.G)) + ";" + String(int(rgb.B))

    fn convert_to_rgb(self) -> hue.Color:
        """Converts the Hex code value to hue.Color."""
        return hex_to_rgb(self.value)


fn ansi256_to_ansi(value: Int) -> ANSIColor:
    """Converts an ANSI256 color to an ANSI color.

    Args:
        value: ANSI256 color value.
    """
    var r: Int = 0
    var md = max_float64

    var h = hex_to_rgb(ANSI_HEX_CODES[value])

    var i: Int = 0
    while i <= 15:
        var hb = hex_to_rgb(ANSI_HEX_CODES[i])
        var d = h.distance_HSLuv(hb)

        if d < md:
            md = d
            r = i

        i += 1

    return ANSIColor(r)


fn v2ci(value: Float64) -> Int:
    if value < 48:
        return 0
    elif value < 115:
        return 1
    else:
        return int((value - 35) / 40)


fn hex_to_ansi256(color: hue.Color) -> ANSI256Color:
    """Converts a hex code to a ANSI256 color.

    Args:
        color: hue.Color hex code.
    """
    # Calculate the nearest 0-based color index at 16..231
    # Originally had * 255 in each of these
    var r: Float64 = v2ci(color.R)  # 0..5 each
    var g: Float64 = v2ci(color.G)
    var b: Float64 = v2ci(color.B)
    var ci: Int = int((36 * r) + (6 * g) + b)  # 0..215

    # Calculate the represented colors back from the index
    var i2cv = List[Int](0, 0x5F, 0x87, 0xAF, 0xD7, 0xFF)
    var cr = i2cv[int(r)]  # r/g/b, 0..255 each
    var cg = i2cv[int(g)]
    var cb = i2cv[int(b)]

    # Calculate the nearest 0-based gray index at 232..255
    var grayIdx: Int
    var average = (r + g + b) / 3
    if average > 238:
        grayIdx = 23
    else:
        grayIdx = int((average - 3) / 10)  # 0..23
    var gv = 8 + 10 * grayIdx  # same value for r/g/b, 0..255

    # Return the one which is nearer to the original input rgb value
    # Originall had / 255.0 for r, g, and b in each of these
    var c2 = hue.Color(cr, cg, cb)
    var g2 = hue.Color(gv, gv, gv)
    var color_dist = color.distance_HSLuv(c2)
    var gray_dist = color.distance_HSLuv(g2)

    if color_dist <= gray_dist:
        return ANSI256Color(16 + ci)
    return ANSI256Color(232 + grayIdx)
