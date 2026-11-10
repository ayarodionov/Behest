// behest-effects: none
//
// Disagreement check (scratch file: never commit, never approve).
// Save as test/disagree_scratch_test.gleam and run `gleam test`.
//
// qcheck shrinks a failing input and prints it; show that input and both answers
// to the human. Each one is a missing example. The alternative must pass the
// approved contract first. Delete this file when done.
import gleam/float
import gleam/int
import gleam/list
import median.{median}
import qcheck

/// The alternative: deliberately different (another algorithm, or the other
/// plausible reading of the request).
fn alt_median(xs: List(Float)) -> Result(Float, Nil) {
  let sorted = list.sort(xs, float.compare)
  let index = { list.length(sorted) - 1 } / 2
  // lower middle value
  sorted |> list.drop(index) |> list.first
}

// Small integers hit ties, zeros and negatives, where meaning differs.
fn small_lists() {
  qcheck.generic_list(
    elements_from: qcheck.map(qcheck.bounded_int(from: -5, to: 5), int.to_float),
    length_from: qcheck.bounded_int(from: 1, to: 8),
  )
}

pub fn implementations_agree_test() {
  use xs <- qcheck.given(small_lists())
  let a = median(xs) |> result_to_nil
  let b = alt_median(xs)
  assert a == b
}

fn result_to_nil(r: Result(Float, e)) -> Result(Float, Nil) {
  case r {
    Ok(v) -> Ok(v)
    Error(_) -> Error(Nil)
  }
}
