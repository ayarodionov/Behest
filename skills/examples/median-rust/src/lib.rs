#[derive(Debug, PartialEq, Eq)]
pub enum MedianError {
    Empty,
    NotANumber,
}

/// Median of `xs`; the input is not modified.
pub fn median(xs: &[f64]) -> Result<f64, MedianError> {
    if xs.is_empty() {
        return Err(MedianError::Empty);
    }
    if xs.iter().any(|x| x.is_nan()) {
        return Err(MedianError::NotANumber);
    }
    let mut s = xs.to_vec();
    s.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let n = s.len();
    if n % 2 == 1 {
        Ok(s[n / 2])
    } else {
        Ok(mean(s[n / 2 - 1], s[n / 2]))
    }
}

/// Mean of `a <= b` that cannot overflow to infinity.
fn mean(a: f64, b: f64) -> f64 {
    if (a < 0.0) != (b < 0.0) {
        (a + b) / 2.0 // opposite signs: the sum cannot overflow
    } else {
        a + (b - a) / 2.0 // same sign: the difference cannot overflow
    }
}
