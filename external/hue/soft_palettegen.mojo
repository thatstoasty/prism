from collections.optional import Optional
from random import random_si64
from utils.numerics import inf
import math
from .math import sq
from .color import lab


# The algorithm works in L*a*b* color space and converts to RGB in the end.
# L* in [0..1], a* and b* in [-1..1]
@register_passable("trivial")
struct lab_t(EqualityComparable):
    var L: Float64
    var A: Float64
    var B: Float64

    fn __init__(inout self, L: Float64, A: Float64, B: Float64):
        self.L = L
        self.A = A
        self.B = B

    fn __eq__(self, other: lab_t) -> Bool:
        return self.L == other.L and self.A == other.A and self.B == other.B

    fn __ne__(self, other: lab_t) -> Bool:
        return self.L != other.L or self.A != other.A or self.B != other.B


fn in_stack(haystack: List[lab_t], upto: Int, needle: lab_t) -> Bool:
    var i = 0
    while i < upto and i < len(haystack):
        if haystack[i] == needle:
            return True
        i += 1

    return False


fn labs_2_cols(labs: List[lab_t]) -> List[Color]:
    var lab_count = len(labs)
    var cols = List[Color](capacity=lab_count)
    for _ in range(lab_count):
        cols.append(Color(0.0, 0.0, 0.0))

    for i in range(lab_count):
        cols[i] = lab(labs[i].L, labs[i].A, labs[i].B)

    return cols


alias CheckColorFn = fn (l: Float64, a: Float64, b: Float64) -> Bool


@value
struct SoftPaletteSettings:
    # A fntion which can be used to restrict the allowed color-space.
    var check_color: Optional[CheckColorFn]

    # The higher, the better quality but the slower. Usually two figures.
    var iterations: Int

    # Use up to 160000 or 8000 samples of the L*a*b* space (and thus calls to CheckColor).
    # Set this to true only if your CheckColor shapes the Lab space weirdly.
    var many_samples: Bool


# That's faster than using colorful's DistanceLab since we would have to
# convert back and forth for that. Here is no conversion.
fn lab_dist(lab1: lab_t, lab2: lab_t) -> Float64:
    return math.sqrt(sq(lab1.L - lab2.L) + sq(lab1.A - lab2.A) + sq(lab1.B - lab2.B))


# A wrapper which uses common parameters.
fn soft_palette(colors_count: Int) raises -> List[Color]:
    return soft_palette_ex(colors_count, SoftPaletteSettings(None, 50, False))


alias LAB_DELTA = 1e-6


fn lab_eq(lab1: lab_t, lab2: lab_t) -> Bool:
    return abs(lab1.L - lab2.L) < LAB_DELTA and abs(lab1.A - lab2.A) < LAB_DELTA and abs(lab1.B - lab2.B) < LAB_DELTA


fn soft_palette_ex(colors_count: Int, settings: SoftPaletteSettings) raises -> List[Color]:
    """Yeah, windows-stype Foo, FooEx, screw you golang...
    Uses K-means to cluster the color-space and return the means of the clusters
    as a new palette of distinctive colors. Falls back to K-medoid if the mean
    happens to fall outside of the color-space, which can only happen if you
    specify a CheckColor fntion."""

    # Checks whether it's a valid RGB and also fulfills the potentially provided constraint.
    @always_inline
    fn check(col: lab_t) -> Bool:
        var c = lab(col.L, col.A, col.B)
        return c.is_valid() and settings.check_color.value()[](col.L, col.A, col.B)

    # Sample the color space. These will be the points k-means is run on.
    var dl = 0.05
    var dab = 0.1
    if settings.many_samples:
        dl = 0.01
        dab = 0.05

    var samples = List[lab_t](capacity=int(1.0 / dl * 2.0 / dab * 2.0 / dab))
    var l = 0.0
    while l <= 1.0:
        var a = -1.0
        while a <= 1.0:
            var b = -1.0
            while b <= 1.0:
                var labt = lab_t(l, a, b)
                if check(labt):
                    samples.append(labt)
                b += dab
            a += dab
        l += dl

    # That would cause some infinite loops down there...
    if len(samples) < colors_count:
        raise Error(
            String("palettegen: more colors requested ")
            + str(colors_count)
            + " than samples available "
            + str(len(samples))
            + " Your requested color count may be wrong, you might want to use many samples or your constraint fntion"
            " makes the valid color space too small"
        )
    elif len(samples) == colors_count:
        return labs_2_cols(samples)  # Oops?

    # We take the initial means out of the samples, so they are in fact medoids.
    # This helps us avoid infinite loops or arbitrary cutoffs with too restrictive constraints.
    var means = List[lab_t](capacity=colors_count)
    for _ in range(colors_count):
        means.append(lab_t(0.0, 0.0, 0.0))

    var i = 0
    while i < colors_count:
        i += 1
        means[i] = samples[int(random_si64(0, len(samples)))]
        while in_stack(means, i, means[i]):
            means[i] = samples[int(random_si64(0, len(samples)))]

    var clusters = List[Int](capacity=len(samples))
    for _ in range(len(samples)):
        clusters.append(0)
    var samples_used = List[Bool](capacity=len(samples))
    for _ in range(len(samples)):
        samples_used.append(False)

    # The actual k-means/medoid iterations
    i = 0
    while i < settings.iterations:
        # Reassing the samples to clusters, i.e. to their closest mean.
        # By the way, also check if any sample is used as a medoid and if so, mark that.
        for j in range(len(samples)):
            samples_used[j] = False
            var mindist = inf[DType.float64]()
            for k in range(len(means)):
                var dist = lab_dist(samples[j], means[k])
                if dist < mindist:
                    mindist = dist
                    clusters[j] = k

                # Mark samples which are used as a medoid.
                if lab_eq(samples[j], means[k]):
                    samples_used[i] = True

        # Compute new means according to the samples.
        for k in range(len(means)):
            # The new mean is the average of all samples belonging to it..
            var nsamples = 0
            var newmean = lab_t(0.0, 0.0, 0.0)

            for j in range(len(samples)):
                if clusters[j] == k:
                    nsamples += 1
                    newmean.L += samples[j].L
                    newmean.A += samples[j].A
                    newmean.B += samples[j].B

            if nsamples > 0:
                newmean.L /= Float64(nsamples)
                newmean.A /= Float64(nsamples)
                newmean.B /= Float64(nsamples)
            else:
                # That mean doesn't have any samples? Get a new mean from the sample list!
                var inewmean = int(random_si64(0, len(samples_used)))
                while samples_used[inewmean]:
                    inewmean = int(random_si64(0, len(samples_used)))

                newmean = samples[inewmean]
                samples_used[inewmean] = True

            # But now we still need to check whether the new mean is an allowed color.
            if nsamples > 0 and check(newmean):
                # It does, life's good (TM)
                means[k] = newmean
            else:
                # New mean isn't an allowed color or doesn't have any samples!
                # Switch to medoid mode and pick the closest (unused) sample.
                # This should always find something thanks to len(samples) >= colors_count
                var mindist = inf[DType.float64]()
                for l in range(len(samples)):
                    if not samples_used[l]:
                        var dist = lab_dist(samples[l], newmean)
                        if dist < mindist:
                            mindist = dist
                            newmean = samples[l]
        i += 1

    return labs_2_cols(means)
