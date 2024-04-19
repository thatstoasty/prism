import math
from .math import cube, clamp01, sq, pi, max_float64
from .hsluv import hSLuvD65, LuvLCh_to_HPLuv, LuvLch_to_HSLuv


# This is the tolerance used when comparing colors using AlmostEqualColor.
alias Delta = 1.0 / 255.0

# This is the default reference white point.
alias D65 = List[Float64](0.95047, 1.00000, 1.08883)

# And another one.
alias D50 = List[Float64](0.96422, 1.00000, 0.82521)


@value
struct Color(Stringable):
    var R: Float64
    var G: Float64
    var B: Float64

    fn __str__(self) -> String:
        return "Color(" + String(self.R) + ", " + String(self.G) + ", " + String(self.B) + ")"

    fn linear_rgb(self) -> (Float64, Float64, Float64):
        """Converts the color into the linear Color space (see http://www.sjbrown.co.uk/2004/05/14/gamma-correct-rendering/).
        """
        var r = linearize(self.R)
        var g = linearize(self.G)
        var b = linearize(self.B)
        return r, g, b

    fn xyz(self) -> (Float64, Float64, Float64):
        var r: Float64
        var g: Float64
        var b: Float64
        r, g, b = self.linear_rgb()

        var x: Float64
        var y: Float64
        var z: Float64
        x, y, z = linear_rgb_to_xyz(r, g, b)
        return x, y, z

    fn Luv_white_ref(self, wref: List[Float64]) -> (Float64, Float64, Float64):
        """Converts the given color to CIE L*u*v* space, taking into account a given reference white. (i.e. the monitor's white)
        L* is in [0..1] and both u* and v* are in about [-1..1]."""
        var x: Float64
        var y: Float64
        var z: Float64
        x, y, z = self.xyz()

        var l: Float64
        var u: Float64
        var v: Float64
        l, u, v = xyz_to_Luv_white_ref(x, y, z, wref)
        return l, u, v

    fn LuvLCh_white_ref(self, wref: List[Float64]) -> (Float64, Float64, Float64):
        var l: Float64
        var u: Float64
        var v: Float64
        l, u, v = self.Luv_white_ref(wref)

        return Luv_To_LuvLCh(l, u, v)

    fn HSLuv(self) -> (Float64, Float64, Float64):
        """Order: sColor -> Linear Color -> CIEXYZ -> CIELUV -> LuvLCh -> HSLuv.
        HSLuv returns the Hue, Saturation and Luminance of the color in the HSLuv
        color space. Hue in [0..360], a Saturation [0..1], and a Luminance
        (lightness) in [0..1].
        """
        var wref: List[Float64] = hSLuvD65
        var l: Float64
        var c: Float64
        var h: Float64
        l, c, h = self.LuvLCh_white_ref(wref)

        return LuvLch_to_HSLuv(l, c, h)

    fn distance_HSLuv(self, c2: Self) -> Float64:
        var h1: Float64
        var s1: Float64
        var l1: Float64
        var h2: Float64
        var s2: Float64
        var l2: Float64

        h1, s1, l1 = self.HSLuv()
        h2, s2, l2 = c2.HSLuv()

        return math.sqrt(sq((h1 - h2) / 100.0) + sq(s1 - s2) + sq(l1 - l2))

    fn is_valid(self) -> Bool:
        """Checks whether the color exists in RGB space, i.e. all values are in [0..1]."""
        return 0.0 <= self.R and self.R <= 1.0 and 0.0 <= self.G and self.G <= 1.0 and 0.0 <= self.B and self.B <= 1.0

    fn clamped(self) -> Self:
        """Clamps the color to the [0..1] range.  If the color is valid already, this is a no-op."""
        return Color(clamp01(self.R), clamp01(self.G), clamp01(self.B))

    fn distance_rgb(self, c2: Self) -> Float64:
        """Computes the distance between two colors in RGB space.
        This is not a good measure! Rather do it in Lab space."""
        return math.sqrt(sq(self.R - c2.R) + sq(self.G - c2.G) + sq(self.B - c2.B))

    fn distance_linear_rgb(self, c2: Self) -> Float64:
        """Computes the distance between two colors in linear RGB space.
        This is not useful for measuring how humans perceive color, but
        might be useful for other things, like dithering."""
        var r1: Float64
        var g1: Float64
        var b1: Float64
        r1, g1, b1 = self.linear_rgb()
        var r2: Float64
        var g2: Float64
        var b2: Float64
        r2, g2, b2 = c2.linear_rgb()
        return math.sqrt(sq(r1 - r2) + sq(g1 - g2) + sq(b1 - b2))

    fn distance_riemersma(self, c2: Self) -> Float64:
        """Color distance algorithm developed by Thiadmer Riemersma.
        It uses RGB coordinates, but he claims it has similar results to CIELUV.
        This makes it both fast and accurate.

        Sources:

        https:#www.compuphase.com/cmetric.htm
        https:#github.com/lucasb-eyer/go-colorful/issues/52."""
        var rAvg = (self.R + c2.R) / 2.0
        # Deltas
        var dR = self.R - c2.R
        var dG = self.G - c2.G
        var dB = self.B - c2.B
        return math.sqrt(((2 + rAvg) * dR * dR) + (4 * dG * dG) + (2 + (1 - rAvg)) * dB * dB)

    fn almost_equal_rgb(self, c2: Self) -> Bool:
        """Check for equality between colors within the tolerance Delta (1/255)."""
        return math.abs(self.R - c2.R) + math.abs(self.G - c2.G) + math.abs(self.B - c2.B) < 3.0 * Delta

    fn hsv(self) -> (Float64, Float64, Float64):
        """Hsv returns the Hue [0..360], Saturation and Value [0..1] of the color."""
        var min = math.min(math.min(self.R, self.G), self.B)
        var v = math.max(math.max(self.R, self.G), self.B)
        var C = v - min

        var s = 0.0
        if v != 0.0:
            s = C / v

        var h = 0.0  # We use 0 instead of undefined as in wp.
        if min != v:
            if v == self.R:
                h = math.mod((self.G - self.B) / C, 6.0)
            if v == self.G:
                h = (self.B - self.R) / C + 2.0
            if v == self.B:
                h = (self.R - self.G) / C + 4.0
            h *= 60.0
            if h < 0.0:
                h += 360.0
        return h, s, v

    fn hsl(self) -> (Float64, Float64, Float64):
        """Hsl returns the Hue [0..360], Saturation [0..1], and Luminance (lightness) [0..1] of the color."""
        var min = math.min(math.min(self.R, self.G), self.B)
        var max = math.max(math.max(self.R, self.G), self.B)

        var l = (max + min) / 2.0

        if min == max:
            return 0.0, 0.0, l

        var s = 0.0
        if l < 0.5:
            s = (max - min) / (max + min)
        else:
            s = (max - min) / (2.0 - max - min)

        var h = 0.0
        if max == self.R:
            h = (self.G - self.B) / (max - min)
        elif max == self.G:
            h = 2.0 + (self.B - self.R) / (max - min)
        else:
            h = 4.0 + (self.R - self.G) / (max - min)

        h *= 60.0

        if h < 0.0:
            h += 360.0

        return h, s, l

    # fn hex(self) -> String:
    #     """Hex returns the hex "html" representation of the color, as in #ff0080."""
    #     # Add 0.5 for rounding
    #     return f"#{uint8(self.R * 255.0 + 0.5):02x}{uint8(self.G * 255.0 + 0.5):02x}{uint8(self.B * 255.0 + 0.5):02x}"

    fn fast_linear_rgb(self) -> (Float64, Float64, Float64):
        """Is much faster than and almost as accurate as LinearRgb.
        BUT it is important to NOTE that they only produce good results for valid colors r,g,b in [0,1]."""
        return delinearize_fast(self.R), delinearize_fast(self.G), delinearize_fast(self.B)

    fn blend_linear_rgb(self, c2: Self, t: Float64) -> Self:
        """Blends two colors in the Linear RGB color-space.
        Unlike BlendRgb, this will not produce dark color around the center.
        t == 0 results in c1, t == 1 results in c2."""
        var r1: Float64
        var g1: Float64
        var b1: Float64
        r1, g1, b1 = self.linear_rgb()

        var r2: Float64
        var g2: Float64
        var b2: Float64
        r2, g2, b2 = c2.linear_rgb()
        return fast_linear_rgb(
            r1 + t * (r2 - r1),
            g1 + t * (g2 - g1),
            b1 + t * (b2 - b1),
        )

    fn xyy(self) -> (Float64, Float64, Float64):
        """Converts the given color to CIE xyY space using D65 as reference white.
        (Note that the reference white is only used for black input.)
        x, y and Y are in [0..1]."""
        var X: Float64
        var Y: Float64
        var Z: Float64
        X, Y, Z = self.xyz()
        return xyz_to_xyY(X, Y, Z)

    fn xyy_white_ref(self, wref: List[Float64]) -> (Float64, Float64, Float64):
        """Converts the given color to CIE xyY space, taking into account
        a given reference white. (i.e. the monitor's white)
        (Note that the reference white is only used for black input.)
        x, y and Y are in [0..1]."""
        var X: Float64
        var Y2: Float64
        var Z: Float64
        X, Y2, Z = self.xyz()
        return xyz_to_xyY_white_ref(X, Y2, Z, wref)

    fn lab(self) -> (Float64, Float64, Float64):
        """Converts the given color to CIE L*a*b* space using D65 as reference white."""
        var x: Float64
        var y: Float64
        var z: Float64
        x, y, z = self.xyz()
        return xyz_to_lab(x, y, z)

    fn lab_white_ref(self, wref: List[Float64]) -> (Float64, Float64, Float64):
        """Converts the given color to CIE L*a*b* space, taking into account
        a given reference white. (i.e. the monitor's white)."""
        var x: Float64
        var y: Float64
        var z: Float64
        x, y, z = self.xyz()
        return xyz_to_lab_white_ref(x, y, z, wref)

    fn distance_lab(self, other: Self) -> Float64:
        """DistanceLab is a good measure of visual similarity between two colors!
        A result of 0 would mean identical colors, while a result of 1 or higher
        means the colors differ a lot."""
        var l1: Float64
        var a1: Float64
        var b1: Float64
        l1, a1, b1 = self.lab()

        var l2: Float64
        var a2: Float64
        var b2: Float64
        l2, a2, b2 = other.lab()

        return math.sqrt(sq(l1 - l2) + sq(a1 - a2) + sq(b1 - b2))

    fn distance_cie76(self, other: Self) -> Float64:
        """DistanceCIE76 is the same as DistanceLab."""
        return self.distance_lab(other)

    fn distance_cie94(self, other: Self) -> Float64:
        """Uses the CIE94 formula to calculate color distance. More accurate than
        DistanceLab, but also more work."""
        var l1: Float64
        var a1: Float64
        var b1: Float64
        l1, a1, b1 = self.lab()

        var l2: Float64
        var a2: Float64
        var b2: Float64
        l2, a2, b2 = other.lab()

        # NOTE: Since all those formulas expect L,a,b values 100x larger than we
        #       have them in this library, we either need to adjust all constants
        #       in the formula, or convert the ranges of L,a,b before, and then
        #       scale the distances down again. The latter is less error-prone.
        l1 *= 100.0
        a1 *= 100.0
        b1 *= 100.0
        l2 *= 100.0
        a2 *= 100.0
        b2 *= 100.0

        var kl = 1.0  # 2.0 for textiles
        var kc = 1.0
        var kh = 1.0
        var k1 = 0.045  # 0.048 for textiles
        var k2 = 0.015  # 0.014 for textiles.

        var deltaL = l1 - l2
        var c1 = math.sqrt(sq(a1) + sq(b1))
        var c2 = math.sqrt(sq(a2) + sq(b2))
        var deltaCab = c1 - c2

        # Not taking Sqrt here for stability, and it's unnecessary.
        var deltaHab2 = sq(a1 - a2) + sq(b1 - b2) - sq(deltaCab)
        var sl = 1.0
        var sc = 1.0 + k1 * c1
        var sh = 1.0 + k2 * c1

        var vL2 = sq(deltaL / (kl * sl))
        var vC2 = sq(deltaCab / (kc * sc))
        var vH2 = deltaHab2 / sq(kh * sh)

        return math.sqrt(vL2 + vC2 + vH2) * 0.01  # See above.

    fn distance_ciede2000(self, other: Self) -> Float64:
        """DistanceCIEDE2000 uses the Delta E 2000 formula to calculate color
        distance. It is more expensive but more accurate than both DistanceLab
        and DistanceCIE94."""
        return self.distance_ciede2000klch(other, 1.0, 1.0, 1.0)

    fn distance_ciede2000klch(self, other: Self, kl: Float64, kc: Float64, kh: Float64) -> Float64:
        """DistanceCIEDE2000klch uses the Delta E 2000 formula with custom values
        for the weighting factors kL, kC, and kH."""
        var l1: Float64
        var a1: Float64
        var b1: Float64
        l1, a1, b1 = self.lab()

        var l2: Float64
        var a2: Float64
        var b2: Float64
        l2, a2, b2 = other.lab()

        # As with CIE94, we scale up the ranges of L,a,b beforehand and scale
        # them down again afterwards.
        l1 *= 100.0
        a1 *= 100.0
        b1 *= 100.0
        l2 *= 100.0
        a2 *= 100.0
        b2 *= 100.0

        var cab1 = math.sqrt(sq(a1) + sq(b1))
        var cab2 = math.sqrt(sq(a2) + sq(b2))
        var cabmean = (cab1 + cab2) / 2
        var p: Float64 = 25.0

        var g = 0.5 * (1 - math.sqrt(math.pow(cabmean, 7) / (math.pow(cabmean, 7) + math.pow(p, 7))))
        var ap1 = (1 + g) * a1
        var ap2 = (1 + g) * a2
        var cp1 = math.sqrt(sq(ap1) + sq(b1))
        var cp2 = math.sqrt(sq(ap2) + sq(b2))

        var hp1 = 0.0
        if b1 != ap1 or ap1 != 0:
            hp1 = math.atan2(b1, ap1)
            if hp1 < 0:
                hp1 += pi * 2
            hp1 *= 180 / pi
        var hp2 = 0.0
        if b2 != ap2 or ap2 != 0:
            hp2 = math.atan2(b2, ap2)
            if hp2 < 0:
                hp2 += pi * 2
            hp2 *= 180 / pi

        var deltaLp = l2 - l1
        var deltaCp = cp2 - cp1
        var dhp = 0.0
        var cpProduct = cp1 * cp2
        if cpProduct != 0:
            dhp = hp2 - hp1
            if dhp > 180:
                dhp -= 360
            elif dhp < -180:
                dhp += 360
        var deltaHp = 2 * math.sqrt(cpProduct) * math.sin(dhp / 2 * pi / 180)

        var lpmean = (l1 + l2) / 2
        var cpmean = (cp1 + cp2) / 2
        var hpmean = hp1 + hp2
        if cpProduct != 0:
            hpmean /= 2
            if math.abs(hp1 - hp2) > 180:
                if hp1 + hp2 < 360:
                    hpmean += 180
                else:
                    hpmean -= 180

        var t = 1 - 0.17 * math.cos((hpmean - 30) * pi / 180) + 0.24 * math.cos(
            2 * hpmean * pi / 180
        ) + 0.32 * math.cos((3 * hpmean + 6) * pi / 180) - 0.2 * math.cos((4 * hpmean - 63) * pi / 180)
        var deltaTheta = 30 * math.exp(-sq((hpmean - 275) / 25))
        var rc = 2 * math.sqrt(math.pow(cpmean, 7) / (math.pow(cpmean, 7) + math.pow(p, 7)))
        var sl = 1 + (0.015 * sq(lpmean - 50)) / math.sqrt(20 + sq(lpmean - 50))
        var sc = 1 + 0.045 * cpmean
        var sh = 1 + 0.015 * cpmean * t
        var rt = -math.sin(2 * deltaTheta * pi / 180) * rc

        return (
            math.sqrt(
                sq(deltaLp / (kl * sl))
                + sq(deltaCp / (kc * sc))
                + sq(deltaHp / (kh * sh))
                + rt * (deltaCp / (kc * sc)) * (deltaHp / (kh * sh))
            )
            * 0.01
        )

    fn blend_lab(self, c2: Self, t: Float64) -> Self:
        """BlendLab blends two colors in the L*a*b* color-space, which should result in a smoother blend.
        t == 0 results in c1, t == 1 results in c2."""
        var l1: Float64
        var a1: Float64
        var b1: Float64
        l1, a1, b1 = self.lab()

        var l2: Float64
        var a2: Float64
        var b2: Float64
        l2, a2, b2 = c2.lab()

        return lab(l1 + t * (l2 - l1), a1 + t * (a2 - a1), b1 + t * (b2 - b1))

    fn luv(self) -> (Float64, Float64, Float64):
        """Converts the given color to CIE L*u*v* space using D65 as reference white.
        L* is in [0..1] and both u* and v* are in about [-1..1]."""
        var x: Float64
        var y: Float64
        var z: Float64
        x, y, z = self.xyz()
        return xyz_to_Luv(x, y, z)

    fn distance_luv(self, c2: Self) -> Float64:
        """DistanceLuv is a good measure of visual similarity between two colors!
        A result of 0 would mean identical colors, while a result of 1 or higher
        means the colors differ a lot."""
        var l1: Float64
        var u1: Float64
        var v1: Float64
        l1, u1, v1 = self.luv()

        var l2: Float64
        var u2: Float64
        var v2: Float64
        l2, u2, v2 = c2.luv()

        return math.sqrt(sq(l1 - l2) + sq(u1 - u2) + sq(v1 - v2))

    fn blend_luv(self, c2: Self, t: Float64) -> Self:
        """BlendLuv blends two colors in the CIE-L*u*v* color-space, which should result in a smoother blend.
        t == 0 results in c1, t == 1 results in c2."""
        var l1: Float64
        var u1: Float64
        var v1: Float64
        l1, u1, v1 = self.luv()

        var l2: Float64
        var u2: Float64
        var v2: Float64
        l2, u2, v2 = c2.luv()

        return Luv(l1 + t * (l2 - l1), u1 + t * (u2 - u1), v1 + t * (v2 - v1))

    fn hcl(self) -> (Float64, Float64, Float64):
        """Converts the given color to HCL space using D65 as reference white.
        H values are in [0..360], C and L values are in [0..1] although C can overshoot 1.0."""
        return self.hcl_white_ref(D65)

    fn hcl_white_ref(self, wref: List[Float64]) -> (Float64, Float64, Float64):
        """Converts the given color to HCL space, taking into account
        a given reference white. (i.e. the monitor's white)
        H values are in [0..360], C and L values are in [0..1]."""
        var L: Float64
        var a: Float64
        var b: Float64
        L, a, b = self.lab_white_ref(wref)
        return lab_to_hcl(L, a, b)

    fn blend_hcl(self, other: Self, t: Float64) -> Self:
        """BlendHcl blends two colors in the CIE-L*C*h° color-space, which should result in a smoother blend.
        t == 0 results in c1, t == 1 results in c2."""
        var h1: Float64
        var c1: Float64
        var l1: Float64
        h1, c1, l1 = self.hcl()

        var h2: Float64
        var c2: Float64
        var l2: Float64
        h2, c2, l2 = other.hcl()

        # https:#github.com/lucasb-eyer/go-colorful/pull/60
        if c1 <= 0.00015 and c2 >= 0.00015:
            h1 = h2
        elif c2 <= 0.00015 and c1 >= 0.00015:
            h2 = h1

        # We know that h are both in [0..360]
        return hcl(interp_angle(h1, h2, t), c1 + t * (c2 - c1), l1 + t * (l2 - l1)).clamped()

    fn LuvLCh(self) -> (Float64, Float64, Float64):
        """Converts the given color to LuvLCh space using D65 as reference white.
        h values are in [0..360], C and L values are in [0..1] although C can overshoot 1.0."""
        return self.Luv_LCh_white_ref(D65)

    fn Luv_LCh_white_ref(self, wref: List[Float64]) -> (Float64, Float64, Float64):
        """Converts the given color to LuvLCh space, taking into account
        a given reference white. (i.e. the monitor's white)
        h values are in [0..360], c and l values are in [0..1]."""
        var l: Float64
        var u: Float64
        var v: Float64
        l, u, v = self.Luv_white_ref(wref)
        return Luv_To_LuvLCh(l, u, v)

    fn blend_Luv_LCh(self, other: Self, t: Float64) -> Self:
        """BlendLuvLCh blends two colors in the cylindrical CIELUV color space.
        t == 0 results in c1, t == 1 results in c2."""
        var l1: Float64
        var c1: Float64
        var h1: Float64
        l1, c1, h1 = self.LuvLCh()

        var l2: Float64
        var c2: Float64
        var h2: Float64
        l2, c2, h2 = other.LuvLCh()

        # We know that h are both in [0..360]
        return LuvLCh(l1 + t * (l2 - l1), c1 + t * (c2 - c1), interp_angle(h1, h2, t))

    fn HPLuv(self) -> (Float64, Float64, Float64):
        """HPLuv returns the Hue, Saturation and Luminance of the color in the HSLuv
        color space. Hue in [0..360], a Saturation [0..1], and a Luminance
        (lightness) in [0..1].

        Note that HPLuv can only represent pastel colors, and so the Saturation
        value could be much larger than 1 for colors it can't represent."""
        var l: Float64
        var c: Float64
        var h: Float64
        l, c, h = self.LuvLCh_white_ref(hSLuvD65)
        return LuvLCh_to_HPLuv(l, c, h)


fn interp_angle(a0: Float64, a1: Float64, t: Float64) -> Float64:
    """Utility used by Hxx color-spaces for interpolating between two angles in [0,360]."""
    # Based on the answer here: http://stackoverflow.com/a/14498790/2366315
    # With potential proof that it works here: http://math.stackexchange.com/a/2144499
    var delta = math.mod(math.mod(a1 - a0, 360.0) + 540.0, 360.0) - 180.0
    return math.mod(a0 + t * delta + 360.0, 360.0)


### HSV ###
###########
# From http://en.wikipedia.org/wiki/HSL_and_HSV
# Note that h is in [0..360] and s,v in [0..1]


fn hsv(h: Float64, s: Float64, v: Float64) -> Color:
    """Hsv creates a new Color given a Hue in [0..360], a Saturation and a Value in [0..1]."""
    var hp = h / 60.0
    var C = v * s
    var X = C * (1.0 - math.abs(math.mod(hp, 2.0) - 1.0))
    var m = v - C
    var r = 0.0
    var g = 0.0
    var b = 0.0

    if 0.0 <= hp and hp < 1.0:
        r = C
        g = X
    elif 1.0 <= hp and hp < 2.0:
        r = X
        g = C
    elif 2.0 <= hp and hp < 3.0:
        g = C
        b = X
    elif 3.0 <= hp and hp < 4.0:
        g = X
        b = C
    elif 4.0 <= hp and hp < 5.0:
        r = X
        b = C
    elif 5.0 <= hp and hp < 6.0:
        r = C
        b = X

    return Color(m + r, m + g, m + b)


## HSL ##
#########


fn hsl(h: Float64, s: Float64, l: Float64) -> Color:
    """Hsl creates a new Color given a Hue in [0..360], a Saturation [0..1], and a Luminance (lightness) in [0..1]."""
    if s == 0:
        return Color(l, l, l)

    var r: Float64
    var g: Float64
    var b: Float64
    var t1: Float64
    var t2: Float64
    var tr: Float64
    var tg: Float64
    var tb: Float64

    if l < 0.5:
        t1 = l * (1.0 + s)
    else:
        t1 = l + s - l * s

    t2 = 2 * l - t1
    var h_copy = h
    h_copy /= 360
    tr = h_copy + 1.0 / 3.0
    tg = h_copy
    tb = h_copy - 1.0 / 3.0

    if tr < 0:
        tr += 1
    if tr > 1:
        tr -= 1
    if tg < 0:
        tg += 1
    if tg > 1:
        tg -= 1
    if tb < 0:
        tb += 1
    if tb > 1:
        tb -= 1

    # Red
    if 6 * tr < 1:
        r = t2 + (t1 - t2) * 6 * tr
    elif 2 * tr < 1:
        r = t1
    elif 3 * tr < 2:
        r = t2 + (t1 - t2) * (2.0 / 3.0 - tr) * 6
    else:
        r = t2

    # Green
    if 6 * tg < 1:
        g = t2 + (t1 - t2) * 6 * tg
    elif 2 * tg < 1:
        g = t1
    elif 3 * tg < 2:
        g = t2 + (t1 - t2) * (2.0 / 3.0 - tg) * 6
    else:
        g = t2

    # Blue
    if 6 * tb < 1:
        b = t2 + (t1 - t2) * 6 * tb
    elif 2 * tb < 1:
        b = t1
    elif 3 * tb < 2:
        b = t2 + (t1 - t2) * (2.0 / 3.0 - tb) * 6
    else:
        b = t2

    return Color(r, g, b)


## Hex ##
#########
# # Hex parses a "html" hex color-string, either in the 3 "#f0c" or 6 "#ff1034" digits form.
# func Hex(scol string) (Color, error) {
# 	format := "#%02x%02x%02x"
# 	factor := 1.0 / 255.0
# 	if len(scol) == 4 {
# 		format = "#%1x%1x%1x"
# 		factor = 1.0 / 15.0
# 	}

# 	var r, g, b uint8
# 	n, err := fmt.Sscanf(scol, format, &r, &g, &b)
# 	if err != nil {
# 		return Color{}, err
# 	}
# 	if n != 3 {
# 		return Color{}, fmt.Errorf("color: %v is not a hex-color", scol)
# 	}

# 	return Color{float64(r) * factor, float64(g) * factor, float64(b) * factor}, nil
# }


## Linear ##
#######
# A much faster and still quite precise linearization using a 6th-order Taylor approximation.
# See the accompanying Jupyter notebook for derivation of the constants.
fn linearize_fast(v: Float64) -> Float64:
    var v1 = v - 0.5
    var v2 = v1 * v1
    var v3 = v2 * v1
    var v4 = v2 * v2
    return (
        -0.248750514614486
        + 0.925583310193438 * v
        + 1.16740237321695 * v2
        + 0.280457026598666 * v3
        - 0.0757991963780179 * v4
    )


fn delinearize_fast(v: Float64) -> Float64:
    if v > 0.2:
        var v1 = v - 0.6
        var v2 = v1 * v1
        var v3 = v2 * v1
        var v4 = v2 * v2
        var v5 = v3 * v2
        return (
            0.442430344268235
            + 0.592178981271708 * v
            - 0.287864782562636 * v2
            + 0.253214392068985 * v3
            - 0.272557158129811 * v4
            + 0.325554383321718 * v5
        )
    elif v > 0.03:
        var v1 = v - 0.115
        var v2 = v1 * v1
        var v3 = v2 * v1
        var v4 = v2 * v2
        var v5 = v3 * v2
        return (
            0.194915592891669
            + 1.55227076330229 * v
            - 3.93691860257828 * v2
            + 18.0679839248761 * v3
            - 101.468750302746 * v4
            + 632.341487393927 * v5
        )
    else:
        var v1 = v - 0.015
        var v2 = v1 * v1
        var v3 = v2 * v1
        var v4 = v2 * v2
        var v5 = v3 * v2
        return (
            0.0519565234928877
            + 5.09316778537561 * v
            - 99.0338180489702 * v2
            + 3484.52322764895 * v3
            - 150028.083412663 * v4
            + 7168008.42971613 * v5
        )


# FastLinearRgb is much faster than and almost as accurate as LinearRgb.
# BUT it is important to NOTE that they only produce good results for valid inputs r,g,b in [0,1].
fn fast_linear_rgb(r: Float64, g: Float64, b: Float64) -> Color:
    return Color(delinearize_fast(r), delinearize_fast(g), delinearize_fast(b))


fn xyz_to_xyY(X: Float64, Y: Float64, Z: Float64) -> (Float64, Float64, Float64):
    return xyz_to_xyY_white_ref(X, Y, Z, D65)


fn xyz_to_xyY_white_ref(X: Float64, Y: Float64, Z: Float64, wref: List[Float64]) -> (Float64, Float64, Float64):
    var Yout = Y
    var N = X + Y + Z
    var x = X
    var y = Y
    if math.abs(N) < 1e-14:
        x = wref[0] / (wref[0] + wref[1] + wref[2])
        y = wref[1] / (wref[0] + wref[1] + wref[2])
    else:
        x = x / N
        y = y / N

    return x, y, Yout


fn xyy_to_xyz(x: Float64, y: Float64, Y: Float64) -> (Float64, Float64, Float64):
    var Yout = y
    var X = x
    var Z = 0.0

    if -1e-14 < y and y < 1e-14:
        X = 0.0
        Z = 0.0
    else:
        X = Y / y * x
        Z = Y / y * (1.0 - x - y)

    return x, y, Yout


fn xyy(x: Float64, y: Float64, Y: Float64) -> Color:
    var X: Float64
    var new_Y: Float64
    var Z: Float64
    X, new_Y, Z = xyy_to_xyz(x, y, Y)
    return xyz(X, new_Y, Z)


# / L*a*b* #/
#######
# http://en.wikipedia.org/wiki/Lab_color_space#CIELAB-CIEXYZ_conversions
# For L*a*b*, we need to L*a*b*<->XYZ->RGB and the first one is device dependent.


fn lab_f(t: Float64) -> Float64:
    if t > 6.0 / 29.0 * 6.0 / 29.0 * 6.0 / 29.0:
        return math.cbrt(t)
    return t / 3.0 * 29.0 / 6.0 * 29.0 / 6.0 + 4.0 / 29.0


fn xyz_to_lab(x: Float64, y: Float64, z: Float64) -> (Float64, Float64, Float64):
    """Use D65 white as reference point by default.
    http://www.fredmiranda.com/forum/topic/1035332
    http://en.wikipedia.org/wiki/Standard_illuminant."""
    return xyz_to_lab_white_ref(x, y, z, D65)


fn xyz_to_lab_white_ref(x: Float64, y: Float64, z: Float64, wref: List[Float64]) -> (Float64, Float64, Float64):
    var fy = lab_f(y / wref[1])
    var l = 1.16 * fy - 0.16
    var a = 5.0 * (lab_f(x / wref[0]) - fy)
    var b = 2.0 * (fy - lab_f(z / wref[2]))
    return l, a, b


fn lab_finv(t: Float64) -> Float64:
    if t > 6.0 / 29.0:
        return t * t * t
    return 3.0 * 6.0 / 29.0 * 6.0 / 29.0 * (t - 4.0 / 29.0)


fn lab_to_xyz(l: Float64, a: Float64, b: Float64) -> (Float64, Float64, Float64):
    """D65 white (see above)."""
    return lab_to_xyz_white_ref(l, a, b, D65)


fn lab_to_xyz_white_ref(l: Float64, a: Float64, b: Float64, wref: List[Float64]) -> (Float64, Float64, Float64):
    var l2 = (l + 0.16) / 1.16
    var x = wref[0] * lab_finv(l2 + a / 5.0)
    var y = wref[1] * lab_finv(l2)
    var z = wref[2] * lab_finv(l2 - b / 2.0)
    return x, y, z


fn lab(l: Float64, a: Float64, b: Float64) -> Color:
    """Generates a color by using data given in CIE L*a*b* space using D65 as reference white.
    WARNING: many combinations of `l`, `a`, and `b` values do not have corresponding
    valid RGB values, check the FAQ in the README if you're unsure."""
    var x: Float64
    var y: Float64
    var z: Float64
    x, y, z = lab_to_xyz(l, a, b)
    return xyz(x, y, z)


fn lab_white_ref(l: Float64, a: Float64, b: Float64, wref: List[Float64]) -> Color:
    """Generates a color by using data given in CIE L*a*b* space, taking
    into account a given reference white. (i.e. the monitor's white)."""
    var x: Float64
    var y: Float64
    var z: Float64
    x, y, z = lab_to_xyz_white_ref(l, a, b, wref)
    return xyz(x, y, z)


# / L*u*v* #/
#######
# http://en.wikipedia.org/wiki/CIELUV#XYZ_.E2.86.92_CIELUV_and_CIELUV_.E2.86.92_XYZ_conversions
# For L*u*v*, we need to L*u*v*<->XYZ<->RGB and the first one is device dependent.


fn xyz_to_Luv(x: Float64, y: Float64, z: Float64) -> (Float64, Float64, Float64):
    """Use D65 white as reference point by default."""
    return xyz_to_Luv_white_ref(x, y, z, D65)


fn luv_to_xyz(l: Float64, u: Float64, v: Float64) -> (Float64, Float64, Float64):
    """Use D65 white as reference point by default."""
    return luv_to_xyz_white_ref(l, u, v, D65)


fn Luv(l: Float64, u: Float64, v: Float64) -> Color:
    """Generates a color by using data given in CIE L*u*v* space using D65 as reference white.
    L* is in [0..1] and both u* and v* are in about [-1..1]
    WARNING: many combinations of `l`, `u`, and `v` values do not have corresponding
    valid RGB values, check the FAQ in the README if you're unsure."""
    var x: Float64
    var y: Float64
    var z: Float64
    x, y, z = luv_to_xyz(l, u, v)
    return xyz(x, y, z)


fn Luv_white_ref(l: Float64, u: Float64, v: Float64, wref: List[Float64]) -> Color:
    """Generates a color by using data given in CIE L*u*v* space, taking
    into account a given reference white. (i.e. the monitor's white)
    L* is in [0..1] and both u* and v* are in about [-1..1]."""
    var x: Float64
    var y: Float64
    var z: Float64
    x, y, z = luv_to_xyz_white_ref(l, u, v, wref)
    return xyz(x, y, z)


## HCL ##
#########
# HCL is nothing else than L*a*b* in cylindrical coordinates!
# (this was wrong on English wikipedia, I fixed it, let's hope the fix stays.)
# But it is widely popular since it is a "correct HSV"
# http://www.hunterlab.com/appnotes/an09_96a.pdf


fn lab_to_hcl(L: Float64, a: Float64, b: Float64) -> (Float64, Float64, Float64):
    var h = 0.0
    if math.abs(b - a) > 1e-4 and math.abs(a) > 1e-4:
        var h = math.mod(57.29577951308232087721 * math.atan2(b, a) + 360.0, 360.0)  # Rad2Deg

    var c = math.sqrt(sq(a) + sq(b))
    var l = L
    return h, c, l


fn hcl(h: Float64, c: Float64, l: Float64) -> Color:
    """Generates a color by using data given in HCL space using D65 as reference white.
    H values are in [0..360], C and L values are in [0..1]
    WARNING: many combinations of `h`, `c`, and `l` values do not have corresponding
    valid RGB values, check the FAQ in the README if you're unsure."""
    return hcl_white_ref(h, c, l, D65)


fn hcl_to_Lab(h: Float64, c: Float64, l: Float64) -> (Float64, Float64, Float64):
    var H = 0.01745329251994329576 * h  # Deg2Rad
    var a = c * math.cos(H)
    var b = c * math.sin(H)
    var L = l
    return L, a, b


fn hcl_white_ref(h: Float64, c: Float64, l: Float64, wref: List[Float64]) -> Color:
    """Generates a color by using data given in HCL space, taking
    into account a given reference white. (i.e. the monitor's white)
    H values are in [0..360], C and L values are in [0..1]."""
    var L: Float64
    var a: Float64
    var b: Float64
    L, a, b = hcl_to_Lab(h, c, l)
    return lab_white_ref(L, a, b, wref)


fn LuvLCh(l: Float64, c: Float64, h: Float64) -> Color:
    """Generates a color by using data given in LuvLCh space using D65 as reference white.
    h values are in [0..360], C and L values are in [0..1]
    WARNING: many combinations of `l`, `c`, and `h` values do not have corresponding
    valid RGB values, check the FAQ in the README if you're unsure."""
    return LuvLCh_white_ref(l, c, h, D65)


fn LuvLChToLuv(l: Float64, c: Float64, h: Float64) -> (Float64, Float64, Float64):
    var H = 0.01745329251994329576 * h  # Deg2Rad
    var u = c * math.cos(H)
    var v = c * math.sin(H)
    var L = l
    return L, u, v


fn LuvLCh_white_ref(l: Float64, c: Float64, h: Float64, wref: List[Float64]) -> Color:
    """Generates a color by using data given in LuvLCh space, taking
    into account a given reference white. (i.e. the monitor's white)
    h values are in [0..360], C and L values are in [0..1]."""
    var L: Float64
    var u: Float64
    var v: Float64
    L, u, v = LuvLChToLuv(l, c, h)
    return Luv_white_ref(L, u, v, wref)


fn clamped(color: Color) -> Color:
    return Color(clamp01(color.R), clamp01(color.G), clamp01(color.B))


fn linearize(v: Float64) -> Float64:
    if v <= 0.04045:
        return v / 12.92

    var lhs: Float64 = (v + 0.055) / 1.055
    var rhs: Float64 = 2.4
    return lhs**rhs


fn linear_rgb_to_xyz(r: Float64, g: Float64, b: Float64) -> (Float64, Float64, Float64):
    var x: Float64 = 0.41239079926595948 * r + 0.35758433938387796 * g + 0.18048078840183429 * b
    var y: Float64 = 0.21263900587151036 * r + 0.71516867876775593 * g + 0.072192315360733715 * b
    var z: Float64 = 0.019330818715591851 * r + 0.11919477979462599 * g + 0.95053215224966058 * b

    return x, y, z


fn luv_to_xyz_white_ref(l: Float64, u: Float64, v: Float64, wref: List[Float64]) -> (Float64, Float64, Float64):
    var y: Float64
    if l <= 0.08:
        y = wref[1] * l * 100.0 * 3.0 / 29.0 * 3.0 / 29.0 * 3.0 / 29.0
    else:
        y = wref[1] * cube((l + 0.16) / 1.16)

    var un: Float64 = 0
    var vn: Float64 = 0
    un, vn = xyz_to_uv(wref[0], wref[1], wref[2])

    var x: Float64 = 0
    var z: Float64 = 0
    if l != 0.0:
        var ubis = (u / (13.0 * l)) + un
        var vbis = (v / (13.0 * l)) + vn
        x = y * 9.0 * ubis / (4.0 * vbis)
        z = y * (12.0 - (3.0 * ubis) - (20.0 * vbis)) / (4.0 * vbis)
    else:
        x = 0.0
        y = 0.0

    return x, y, z


fn xyz_to_uv(x: Float64, y: Float64, z: Float64) -> (Float64, Float64):
    """For this part, we do as R's graphics.hcl does, not as wikipedia does.
    Or is it the same."""
    var denom = x + (15.0 * y) + (3.0 * z)
    var u: Float64
    var v: Float64

    if denom == 0.0:
        u = 0.0
        v = 0.0

        return u, v

    u = 4.0 * x / denom
    v = 9.0 * y / denom

    return u, v


fn xyz_to_Luv_white_ref(x: Float64, y: Float64, z: Float64, wref: List[Float64]) -> (Float64, Float64, Float64):
    var l: Float64
    if y / wref[1] <= 6.0 / 29.0 * 6.0 / 29.0 * 6.0 / 29.0:
        l = y / wref[1] * (29.0 / 3.0 * 29.0 / 3.0 * 29.0 / 3.0) / 100.0
    else:
        l = 1.16 * math.cbrt(y / wref[1]) - 0.16

    var ubis: Float64
    var vbis: Float64
    ubis, vbis = xyz_to_uv(x, y, z)

    var un: Float64
    var vn: Float64
    un, vn = xyz_to_uv(wref[0], wref[1], wref[2])

    var u: Float64
    var v: Float64
    u = 13.0 * l * (ubis - un)
    v = 13.0 * l * (vbis - vn)

    return l, u, v


fn Luv_To_LuvLCh(L: Float64, u: Float64, v: Float64) -> (Float64, Float64, Float64):
    # Oops, floating point workaround necessary if u ~= v and both are very small (i.e. almost zero).
    var h: Float64
    if math.abs(v - u) > 1e-4 and math.abs(u) > 1e-4:
        h = math.mod(57.29577951308232087721 * math.atan2(v, u) + 360.0, 360.0)  # Rad2Deg
    else:
        h = 0.0

    var l = L
    var c = math.sqrt(sq(u) + sq(v))

    return l, c, h


fn xyz_to_linear_rgb(x: Float64, y: Float64, z: Float64) -> (Float64, Float64, Float64):
    """Converts from CIE XYZ-space to Linear Color space."""
    var r = (3.2409699419045214 * x) - (1.5373831775700935 * y) - (0.49861076029300328 * z)
    var g = (-0.96924363628087983 * x) + (1.8759675015077207 * y) + (0.041555057407175613 * z)
    var b = (0.055630079696993609 * x) - (0.20397695888897657 * y) + (1.0569715142428786 * z)

    return r, g, b


fn delinearize(v: Float64) -> Float64:
    if v <= 0.0031308:
        return 12.92 * v

    return 1.055 * (v ** (1.0 / 2.4)) - 0.055


fn linear_rgb(r: Float64, g: Float64, b: Float64) -> Color:
    return Color(delinearize(r), delinearize(g), delinearize(b))


fn xyz(x: Float64, y: Float64, z: Float64) -> Color:
    var r: Float64
    var g: Float64
    var b: Float64

    r, g, b = xyz_to_linear_rgb(x, y, z)
    return linear_rgb(r, g, b)
