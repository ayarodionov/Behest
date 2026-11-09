# behest-effects: none
#
# Contract for `median`. Approved by the human; do not edit to make a build pass.
import math

import pytest
from hypothesis import given, strategies as st

from median import EmptyError, median

# --- examples ---------------------------------------------------------------


def test_examples():
    assert median([3.0, 1.0, 2.0]) == 2.0  # odd length: the middle value
    assert median([1.0, 2.0]) == 1.5  # even length: mean of the middle two
    assert median([0.0, 0.0]) == 0.0  # ties
    assert median([5.0]) == 5.0  # single element
    assert median([0.0, -1.0]) == -0.5  # negatives


# Answer to an open question: the result is always a float, even for int input.
def test_result_is_always_a_float():
    assert type(median([1, 2, 3])) is float
    assert type(median([4, 4])) is float
    assert type(median([7])) is float


# Answer to an open question: an empty list is an error, not a default.
def test_empty_is_an_error():
    with pytest.raises(EmptyError):
        median([])


# Answer to an open question: NaN is rejected, not skipped or propagated.
def test_nan_is_an_error():
    with pytest.raises(ValueError):
        median([1.0, math.nan])


# Boundary: the mean of two huge values must not overflow to infinity.
def test_huge_values_do_not_overflow():
    assert median([1.7e308, 1.7e308]) == 1.7e308
    assert median([-1.7e308, -1.7e308]) == -1.7e308


# --- properties ---------------------------------------------------------------

finite = st.floats(allow_nan=False, allow_infinity=False)
numbers = st.lists(finite, min_size=1, max_size=12)


@given(numbers, st.randoms(use_true_random=False))
def test_order_does_not_matter(xs, rnd):
    ys = list(xs)
    rnd.shuffle(ys)
    assert median(xs) == median(ys)


@given(numbers)
def test_between_min_and_max(xs):
    assert min(xs) <= median(xs) <= max(xs)


@given(numbers)
def test_does_not_modify_its_input(xs):
    before = list(xs)
    median(xs)
    assert xs == before
