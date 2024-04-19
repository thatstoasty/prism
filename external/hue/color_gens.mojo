from random import randn_float64
from .color import Color, hsv, hcl

# Various ways to generate single random colors


fn fast_warm_color() -> Color:
    """Creates a random dark, "warm" color through a restricted HSV space."""
    return hsv(randn_float64() * 360.0, 0.5 + randn_float64() * 0.3, 0.3 + randn_float64() * 0.3)


fn warm_color() -> Color:
    """Creates a random dark, "warm" color through restricted HCL space.
    This is slower than FastWarmColor but will likely give you colors which have
    the same "warmness" if you run it many times."""
    var c = random_warm()
    while not c.is_valid():
        c = random_warm()

    return c


fn random_warm() -> Color:
    return hcl(randn_float64() * 360.0, 0.1 + randn_float64() * 0.3, 0.2 + randn_float64() * 0.3)


fn fast_happy_color() -> Color:
    """Creates a random bright, "pimpy" color through a restricted HSV space."""
    return hsv(randn_float64() * 360.0, 0.7 + randn_float64() * 0.3, 0.6 + randn_float64() * 0.3)


fn happy_color() -> Color:
    """Creates a random bright, "pimpy" color through restricted HCL space.
    This is slower than FastHappyColor but will likely give you colors which
    have the same "brightness" if you run it many times."""
    var c = random_pimp()
    while not c.is_valid():
        c = random_pimp()

    return c


fn random_pimp() -> Color:
    return hcl(randn_float64() * 360.0, 0.5 + randn_float64() * 0.3, 0.5 + randn_float64() * 0.3)
