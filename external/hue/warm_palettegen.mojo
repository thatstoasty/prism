from random import randn_float64
from .color import hsv, lab_to_hcl
from .soft_palettegen import soft_palette_ex, SoftPaletteSettings


fn fast_warm_palette(colors_count: Int) -> List[Color]:
    """Uses the hsv color space to generate colors with similar S,V but distributed
    evenly along their Hue. This is fast but not always pretty.
    If you've got time to spare, use Lab (the non-fast below).

    Args:
        colors_count: The number of colors to generate.

    Returns:
        A list of colors.
    """
    var colors = List[Color](capacity=colors_count)
    for _ in range(colors_count):
        colors.append(Color(0, 0, 0))

    var i = 0
    while i < colors_count:
        colors[i] = hsv(
            Float64(i) * (360.0 / Float64(colors_count)), 0.55 + randn_float64() * 0.2, 0.35 + randn_float64() * 0.2
        )
        i += 1

    return colors


fn warm_palette(colors_count: Int) raises -> List[Color]:
    fn warmy(l: Float64, a: Float64, b: Float64) -> Bool:
        var h: Float64
        var c: Float64
        var l_new: Float64
        h, c, l_new = lab_to_hcl(l, a, b)
        return 0.1 <= c and c <= 0.4 and 0.2 <= l and l <= 0.5

    return soft_palette_ex(colors_count, SoftPaletteSettings(warmy, 50, True))
