from .math import cube, clamp01, sq, pi, max_float64
from .color import Color, linear_rgb, xyz_to_linear_rgb, luv_to_xyz_white_ref
import math

alias hSLuvD65 = List[Float64](0.95045592705167, 1.0, 1.089057750759878)


fn LuvLCh_to_HSLuv(l: Float64, c: Float64, h: Float64) -> (Float64, Float64, Float64):
    """[-1..1] but the code expects it to be [-100..100]."""
    var c_new = c * 100.0
    var l_new = l * 100.0

    var s: Float64
    var max_val: Float64
    if l_new > 99.9999999 or l_new < 0.00000001:
        s = 0.0
    else:
        max_val = max_chroma_for_lh(l_new, h)
        s = c_new / max_val * 100.0

    return h, clamp01(s / 100.0), clamp01(l_new / 100.0)


fn HSLuvToLuvLCh(h: Float64, s: Float64, l: Float64) -> (Float64, Float64, Float64):
    var tmp_l = l * 100.0
    var tmp_s = s * 100.0

    var c: Float64
    var max: Float64
    if tmp_l > 99.9999999 or tmp_l < 0.00000001:
        c = 0.0
    else:
        max = max_chroma_for_lh(l, h)
        c = max / 100.0 * tmp_s

    # c is [-100..100], but for LCh it's supposed to be almost [-1..1]
    return clamp01(l / 100.0), c / 100.0, h


fn LuvLCh_to_Luv(l: Float64, c: Float64, h: Float64) -> (Float64, Float64, Float64):
    var H: Float64 = 0.01745329251994329576 * h  # Deg2Rad
    var u = c * math.cos(H)
    var v = c * math.sin(H)
    return l, u, v


fn LuvLCh_to_HPLuv(l: Float64, c: Float64, h: Float64) -> (Float64, Float64, Float64):
    """[-1..1] but the code expects it to be [-100..100]."""
    var c_new = c * 100.0
    var l_new = l * 100.0

    var s: Float64
    var max_val: Float64
    if l_new > 99.9999999 or l_new < 0.00000001:
        s = 0.0
    else:
        max_val = max_safe_chroma_for_l(l_new)
        s = c_new / max_val * 100.0

    return h, s / 100.0, l_new / 100.0


fn HPLuv_to_LuvLCh(h: Float64, s: Float64, l: Float64) -> (Float64, Float64, Float64):
    var l_new = l * 100.0
    var s_new = s * 100.0

    var c: Float64
    var max_val: Float64
    if l_new > 99.9999999 or l_new < 0.00000001:
        c = 0.0
    else:
        max_val = max_safe_chroma_for_l(l_new)
        c = max_val / 100.0 * s_new

    return l_new / 100.0, c / 100.0, h


fn HSLuv(h: Float64, s: Float64, l: Float64) -> Color:
    """Creates a new Color from values in the HSLuv color space.
    Hue in [0..360], a Saturation [0..1], and a Luminance (lightness) in [0..1].

    The returned color values are clamped (using .Clamped), so this will never output
    an invalid color."""
    # HSLuv -> LuvLCh -> CIELUV -> CIEXYZ -> Linear RGB -> sRGB
    var l_new: Float64
    var c: Float64
    var h_new: Float64
    l_new, c, h_new = HSLuvToLuvLCh(h, s, l)

    var L: Float64
    var u: Float64
    var v: Float64
    L, u, v = LuvLCh_to_Luv(l_new, c, h_new)

    var x: Float64
    var y: Float64
    var z: Float64
    x, y, z = luv_to_xyz_white_ref(l, u, v, hSLuvD65)

    var R: Float64
    var G: Float64
    var B: Float64
    R, G, B = xyz_to_linear_rgb(x, y, z)
    return linear_rgb(R, G, B).clamped()


fn LuvLch_to_HSLuv(l: Float64, c: Float64, h: Float64) -> (Float64, Float64, Float64):
    # [-1..1] but the code expects it to be [-100..100]
    var tmp_l: Float64 = l * 100.0
    var tmp_c: Float64 = c * 100.0

    var s: Float64
    var max_val: Float64
    if tmp_l > 99.9999999 or tmp_l < 0.00000001:
        s = 0.0
    else:
        max_val = max_chroma_for_lh(tmp_l, h)
        s = tmp_c / max_val * 100.0

    return h, clamp01(s / 100.0), clamp01(tmp_l / 100.0)


fn HPLuv(h: Float64, s: Float64, l: Float64) -> Color:
    """HPLuv creates a new Color from values in the HPLuv color space.
    Hue in [0..360], a Saturation [0..1], and a Luminance (lightness) in [0..1].

    The returned color values are clamped (using .Clamped), so this will never output
    an invalid color."""
    # HPLuv -> LuvLCh -> CIELUV -> CIEXYZ -> Linear RGB -> sRGB
    var l_new: Float64
    var c: Float64
    var h_new: Float64
    l_new, c, h_new = HPLuv_to_LuvLCh(h, s, l)

    var L: Float64
    var u: Float64
    var v: Float64
    L, u, v = LuvLCh_to_Luv(l_new, c, h_new)

    var x: Float64
    var y: Float64
    var z: Float64
    x, y, z = luv_to_xyz_white_ref(l, u, v, hSLuvD65)

    var R: Float64
    var G: Float64
    var B: Float64
    R, G, B = xyz_to_linear_rgb(x, y, z)
    return linear_rgb(R, G, B).clamped()


fn HSLuv(self: Color) -> (Float64, Float64, Float64):
    """HSLuv returns the Hue, Saturation and Luminance of the color in the HSLuv
    color space. Hue in [0..360], a Saturation [0..1], and a Luminance
    (lightness) in [0..1]."""
    # sRGB -> Linear RGB -> CIEXYZ -> CIELUV -> LuvLCh -> HSLuv
    var l: Float64
    var c: Float64
    var h: Float64
    l, c, h = self.LuvLCh_white_ref(hSLuvD65)

    return LuvLCh_to_HSLuv(l, c, h)


fn HPLuv(self: Color) -> (Float64, Float64, Float64):
    """HPLuv returns the Hue, Saturation and Luminance of the color in the HSLuv
    color space. Hue in [0..360], a Saturation [0..1], and a Luminance
    (lightness) in [0..1].

    Note that HPLuv can only represent pastel colors, and so the Saturation
    value could be much larger than 1 for colors it can't represent."""
    # sRGB -> Linear RGB -> CIEXYZ -> CIELUV -> LuvLCh -> HSLuv
    var l: Float64
    var c: Float64
    var h: Float64
    l, c, h = self.LuvLCh_white_ref(hSLuvD65)

    return LuvLCh_to_HPLuv(l, c, h)


fn DistanceHPLuv(self: Color, other: Color) -> Float64:
    """DistanceHPLuv calculates Euclidean distance in the HPLuv colorspace. No idea
    how useful this is.

    The Hue value is divided by 100 before the calculation, so that H, S, and L
    have the same relative ranges."""
    var h1: Float64
    var s1: Float64
    var l1: Float64
    h1, s1, l1 = self.HPLuv()

    var h2: Float64
    var s2: Float64
    var l2: Float64
    h2, s2, l2 = other.HPLuv()

    return math.sqrt(sq((h1 - h2) / 100.0) + sq(s1 - s2) + sq(l1 - l2))


alias m = List[List[Float64]](
    List[Float64](3.2409699419045214, -1.5373831775700935, -0.49861076029300328),
    List[Float64](-0.96924363628087983, 1.8759675015077207, 0.041555057407175613),
    List[Float64](0.055630079696993609, -0.20397695888897657, 1.0569715142428786),
)

alias kappa = 903.2962962962963
alias epsilon = 0.0088564516790356308


fn get_bounds(l: Float64) -> List[List[Float64]]:
    var sub2: Float64
    var sub1 = (l + 16.0**3.0) / 1560896.0

    var ret = List[List[Float64]](
        List[Float64](0, 0),
        List[Float64](0, 0),
        List[Float64](0, 0),
        List[Float64](0, 0),
        List[Float64](0, 0),
        List[Float64](0, 0),
    )

    if sub1 > epsilon:
        sub2 = sub1
    else:
        sub2 = l / kappa

    for i in range(len(m)):
        var k = 0
        while k < 2:
            var top1 = (284517.0 * m[i][0] - 94839.0 * m[i][2]) * sub2
            var top2 = (838422.0 * m[i][2] + 769860.0 * m[i][1] + 731718.0 * m[i][0]) * l * sub2 - 769860.0 * Float64(
                k
            ) * l
            var bottom = (632260.0 * m[i][2] - 126452.0 * m[i][1]) * sub2 + 126452.0 * Float64(k)
            ret[i * 2 + k][0] = top1 / bottom
            ret[i * 2 + k][1] = top2 / bottom
            k += 1

    return ret


fn length_of_ray_until_intersect(theta: Float64, x: Float64, y: Float64) -> Float64:
    return y / (math.sin(theta) - x * math.cos(theta))


fn max_chroma_for_lh(l: Float64, h: Float64) -> Float64:
    var hRad = h / 360.0 * pi * 2.0
    var minLength = max_float64
    var bounds = get_bounds(l)

    for i in range(len(bounds)):
        var line = bounds[i]
        var length = length_of_ray_until_intersect(hRad, line[0], line[1])
        if length > 0.0 and length < minLength:
            minLength = length

    return minLength


fn max_safe_chroma_for_l(l: Float64) -> Float64:
    var min_length = max_float64
    for line in get_bounds(l):
        var m1 = line[][0]
        var b1 = line[][1]
        var x = intersect_line_line(m1, b1, -1.0 / m1, 0.0)
        var dist = distance_from_pole(x, b1 + x * m1)
        if dist < min_length:
            min_length = dist
    return min_length


fn intersect_line_line(x1: Float64, y1: Float64, x2: Float64, y2: Float64) -> Float64:
    return (y1 - y2) / (x2 - x1)


fn distance_from_pole(x: Float64, y: Float64) -> Float64:
    return math.sqrt(sq(x) + sq(y))
