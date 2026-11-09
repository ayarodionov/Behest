package median

import (
	"errors"
	"sort"
)

// ErrEmpty is returned for an empty input.
var ErrEmpty = errors.New("median: empty input")

// Median returns the median of xs without modifying it.
func Median(xs []float64) (float64, error) {
	if len(xs) == 0 {
		return 0, ErrEmpty
	}
	s := append([]float64(nil), xs...)
	sort.Float64s(s)
	n := len(s)
	if n%2 == 1 {
		return s[n/2], nil
	}
	return mean(s[n/2-1], s[n/2]), nil
}

// mean of a <= b without overflowing to Inf for huge finite values.
func mean(a, b float64) float64 {
	if (a < 0) != (b < 0) {
		return (a + b) / 2 // opposite signs: the sum cannot overflow
	}
	return a + (b-a)/2 // same sign: the difference cannot overflow
}
