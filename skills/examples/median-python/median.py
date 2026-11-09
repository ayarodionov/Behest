import math


class EmptyError(ValueError):
    """Raised for an empty input."""


def median(xs: list[float]) -> float:
    """Median of `xs` as a float; the input is not modified."""
    if not xs:
        raise EmptyError("median of an empty list")
    if any(math.isnan(x) for x in xs):
        raise ValueError("median of a list containing NaN")
    s = sorted(float(x) for x in xs)
    n = len(s)
    if n % 2 == 1:
        return s[n // 2]
    return _mean(s[n // 2 - 1], s[n // 2])


def _mean(a: float, b: float) -> float:
    """Mean of a <= b that cannot overflow to infinity."""
    if (a < 0) != (b < 0):
        return (a + b) / 2  # opposite signs: the sum cannot overflow
    return a + (b - a) / 2  # same sign: the difference cannot overflow
