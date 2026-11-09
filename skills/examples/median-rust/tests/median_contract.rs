// behest-effects: none
//
// Contract for `median`. Approved by the human; do not edit to make a build pass.
use median::{median, MedianError};
use proptest::prelude::*;

// --- examples ---------------------------------------------------------------

#[test]
fn examples() {
    assert_eq!(median(&[3.0, 1.0, 2.0]), Ok(2.0)); // odd length: the middle value
    assert_eq!(median(&[1.0, 2.0]), Ok(1.5)); // even length: mean of the middle two
    assert_eq!(median(&[0.0, 0.0]), Ok(0.0)); // ties
    assert_eq!(median(&[5.0]), Ok(5.0)); // single element
    assert_eq!(median(&[0.0, -1.0]), Ok(-0.5)); // negatives
}

// Boundary: the mean of two huge values must not overflow to infinity.
// (The random properties below rarely reach this, so it is an explicit example.)
#[test]
fn huge_values_do_not_overflow() {
    assert_eq!(median(&[f64::MAX, f64::MAX]), Ok(f64::MAX));
    assert_eq!(median(&[f64::MIN, f64::MIN]), Ok(f64::MIN));
}

// Answer to an open question: an empty slice is an error, not a default.
#[test]
fn empty_is_an_error() {
    assert_eq!(median(&[]), Err(MedianError::Empty));
}

// Answer to an open question: NaN is rejected, not skipped or propagated.
#[test]
fn nan_is_an_error() {
    assert_eq!(median(&[1.0, f64::NAN]), Err(MedianError::NotANumber));
}

// --- properties ---------------------------------------------------------------

// Finite floats over the whole range, huge values included (that is the point).
fn finite_vec() -> impl Strategy<Value = Vec<f64>> {
    prop::collection::vec(
        prop::num::f64::NORMAL | prop::num::f64::SUBNORMAL | prop::num::f64::ZERO,
        1..12,
    )
}

proptest! {
    #[test]
    fn order_does_not_matter(xs in finite_vec()) {
        let mut ys = xs.clone();
        ys.reverse();
        prop_assert_eq!(median(&xs), median(&ys));
    }

    #[test]
    fn between_min_and_max(xs in finite_vec()) {
        let m = median(&xs).unwrap();
        let lo = xs.iter().cloned().fold(f64::INFINITY, f64::min);
        let hi = xs.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
        prop_assert!(lo <= m && m <= hi, "median {} outside [{}, {}]", m, lo, hi);
    }
}
// Not modifying the input is guaranteed by the signature (`&[f64]`), so it is
// not a property here.
