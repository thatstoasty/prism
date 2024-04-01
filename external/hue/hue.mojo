from .math import cube, clamp01, sq, pi, max_float64
from .color import RGB
import math


# fn HSLuvToLuvLCh(h: Float64, s: Float64, l: Float64) -> (Float64, Float64, Float64):
#     var tmp_l: Float64 = l * 100.0
#     var tmp_s: Float64 = s * 100.0

#     var c: Float64
#     var max: Float64
#     if (l > 99.9999999 or l < 0.00000001):
#         c = 0.0
#     else:
#         max = maxChromaForLH(l, h)
#         c = max / 100.0 * s

# 	# c is [-100..100], but for LCh it's supposed to be almost [-1..1]
# 	return clamp01(l / 100.0), c / 100.0, h


fn LuvLCh_to_Luv(l: Float64, c: Float64, h: Float64) -> (Float64, Float64, Float64):
    var H: Float64 = 0.01745329251994329576 * h  # Deg2Rad
    var u = c * math.cos(H)
    var v = c * math.sin(H)
    return l, u, v


# Generates a color by using data given in LuvLCh space, taking
# into account a given reference white. (i.e. the monitor's white)
# h values are in [0..360], C and L values are in [0..1]
# fn LuvLChWhiteRef(l: Float64, c: Float64, h: Float64, wref: List[Float64]) -> RGB:
#     var L: Float64
#     var u: Float64
#     var v: Float64

#     L, u, v = LuvLChToLuv(l, c, h)
#     return LuvWhiteRef(L, u, v, wref)


# # HSLuv creates a new RGB from values in the HSLuv color space.
# # Hue in [0..360], a Saturation [0..1], and a Luminance (lightness) in [0..1].
# #
# # The returned color values are clamped (using .Clamped), so this will never output
# # an invalid color.
# fn HSLuv(h: Float64, s: Float64, inout l: Float64) -> RGB:
# 	# HSLuv -> LuvLCh -> CIELUV -> CIEXYZ -> Linear RGB -> sRGB
#     var u: Float64
#     var v: Float64
#     l, u, v = LuvLChToLuv(HSLuvToLuvLCh(h, s, l))
#     return LinearRgb(XyzToLinearRgb(LuvToXyzWhiteRef(l, u, v, hSLuvD65))).Clamped()
