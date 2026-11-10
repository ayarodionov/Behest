// behest-effects: none
//
// Contract for `median`. Approved by the human; do not edit to make a build pass.
// Save as test/median_contract_test.gleam. The module under test is src/median.gleam.
import gleeunit
import median.{Empty, median}
import qcheck

pub fn main() {
  gleeunit.main()
}

// --- examples ---------------------------------------------------------------

pub fn examples_test() {
  assert median([3.0, 1.0, 2.0]) == Ok(2.0)
  // odd length: the middle value
  assert median([1.0, 2.0]) == Ok(1.5)
  // even length: mean of the middle two
  assert median([0.0, 0.0]) == Ok(0.0)
  // ties
  assert median([5.0]) == Ok(5.0)
  // single element
  assert median([0.0, -1.0]) == Ok(-0.5)
  // negatives
  assert median([5.0, 1.0, 4.0, 2.0, 3.0]) == Ok(3.0)
  // odd length of five: still the middle value
}

// Answer to an open question: an empty list is an error, not a default.
pub fn empty_is_an_error_test() {
  assert median([]) == Error(Empty)
}

// Boundary: the mean of two huge values must not overflow (Gleam floats raise
// on overflow instead of becoming infinity).
pub fn huge_values_test() {
  assert median([1.7e308, 1.7e308]) == Ok(1.7e308)
  assert median([-1.7e308, -1.7e308]) == Ok(-1.7e308)
}

// --- properties ---------------------------------------------------------------

fn numbers() {
  qcheck.generic_list(
    elements_from: qcheck.float(),
    length_from: qcheck.bounded_int(from: 1, to: 12),
  )
}

pub fn between_min_and_max_test() {
  use xs <- qcheck.given(numbers())
  let assert Ok(m) = median(xs)
  let assert Ok(lo) = list_min(xs)
  let assert Ok(hi) = list_max(xs)
  assert lo <=. m
  assert m <=. hi
}

pub fn order_does_not_matter_test() {
  use xs <- qcheck.given(numbers())
  // Reversal is the cheapest permutation; add a rotation if you want more.
  assert median(xs) == median(reverse(xs))
}

// Pins the position: without this, any fixed position (the first third, say)
// would pass the two properties above.
pub fn half_below_half_above_test() {
  use xs <- qcheck.given(numbers())
  let assert Ok(m) = median(xs)
  let n = count(xs, fn(_) { True })
  assert 2 * count(xs, fn(x) { x <=. m }) >= n
  assert 2 * count(xs, fn(x) { x >=. m }) >= n
}

// --- small helpers so the contract needs only the standard library -------------

fn reverse(xs: List(Float)) -> List(Float) {
  do_reverse(xs, [])
}

fn do_reverse(xs: List(Float), acc: List(Float)) -> List(Float) {
  case xs {
    [] -> acc
    [x, ..rest] -> do_reverse(rest, [x, ..acc])
  }
}

fn list_min(xs: List(Float)) -> Result(Float, Nil) {
  case xs {
    [] -> Error(Nil)
    [x, ..rest] -> Ok(fold(rest, x, fn(a, b) { case b <. a { True -> b False -> a } }))
  }
}

fn list_max(xs: List(Float)) -> Result(Float, Nil) {
  case xs {
    [] -> Error(Nil)
    [x, ..rest] -> Ok(fold(rest, x, fn(a, b) { case b >. a { True -> b False -> a } }))
  }
}

fn count(xs: List(Float), keep: fn(Float) -> Bool) -> Int {
  case xs {
    [] -> 0
    [x, ..rest] ->
      case keep(x) {
        True -> 1 + count(rest, keep)
        False -> count(rest, keep)
      }
  }
}

fn fold(xs: List(Float), acc: Float, f: fn(Float, Float) -> Float) -> Float {
  case xs {
    [] -> acc
    [x, ..rest] -> fold(rest, f(acc, x), f)
  }
}
