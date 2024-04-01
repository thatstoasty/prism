from math import max, min
from math.limit import max_finite


fn cube(v: Float64) -> Float64:
    return v * v * v


fn sq(v: Float64) -> Float64:
    return v * v


fn clamp01(v: Float64) -> Float64:
    """Clamps from 0 to 1."""
    return max(0.0, min(v, 1.0))


alias pi: Float64 = 3.141592653589793238462643383279502884197169399375105820974944592307816406286
alias max_float64: Float64 = max_finite[DType.float64]()
