# behest-effects: none
#
# Disagreement check (scratch file: never commit, never approve).
# Save as tests/test_disagree_scratch.py and run:
#
#     python -m pytest tests/test_disagree_scratch.py
#
# Hypothesis shrinks a failure to a minimal input and prints it; show that input
# and both answers to the human. Each one is a missing example. The alternative
# must pass the approved contract first. Delete this file and .hypothesis/ when done.
from hypothesis import given, strategies as st

from median import median  # the function under test


def alt_median(xs):
    """The alternative: deliberately different (another algorithm, or the other
    plausible reading of the request)."""
    s = sorted(xs)
    return float(s[(len(s) - 1) // 2])  # lower middle value


# Small integers hit ties, zeros and negatives, where meaning differs.
small_lists = st.lists(st.integers(-5, 5), min_size=1, max_size=8)


@given(small_lists)
def test_implementations_agree(xs):
    a, b = median(list(xs)), alt_median(list(xs))  # each gets its own copy
    # Compare type as well as value: 0 == 0.0 hides a result-type gap.
    assert (type(a), a) == (type(b), b), f"median={a!r} alt={b!r}"
