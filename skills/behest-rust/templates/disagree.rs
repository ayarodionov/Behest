// Disagreement check (scratch file: never commit, never approve).
// Save as tests/disagree_scratch.rs and run:
//
//     cargo test --test disagree_scratch
//
// proptest shrinks a failure to a minimal input and prints both answers.
// Each one is a missing example: show it to the human. The alternative must pass
// the approved contract first (copy the contract's examples to run against it).
// Delete this file and tests/disagree_scratch.proptest-regressions when done.
//
// behest-effects: none
use median::median; // the function under test
use proptest::prelude::*;

// The alternative: deliberately different (another algorithm, or the other
// plausible reading of the request).
fn alt_median(xs: &[f64]) -> Result<f64, String> {
    if xs.is_empty() {
        return Err("empty".into());
    }
    let mut s = xs.to_vec();
    s.sort_by(|a, b| a.partial_cmp(b).unwrap());
    Ok(s[(s.len() - 1) / 2]) // lower middle value
}

// Small integer-valued floats hit ties, zeros and negatives, where meaning differs.
fn small_vec() -> impl Strategy<Value = Vec<f64>> {
    prop::collection::vec((-5i32..=5).prop_map(|i| i as f64), 0..8)
}

proptest! {
    #[test]
    fn implementations_agree(xs in small_vec()) {
        let a = median(&xs).map_err(|_| ());   // compare success vs failure, not error types
        let b = alt_median(&xs).map_err(|_| ());
        prop_assert_eq!(a, b);
    }
}
