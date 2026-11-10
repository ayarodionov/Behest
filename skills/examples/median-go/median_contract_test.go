// behest-effects: none
//
// Contract for Median. Approved by the human; do not edit to make a build pass.
package median

import (
	"errors"
	"math"
	"math/rand"
	"reflect"
	"sort"
	"testing"
	"testing/quick"
)

// --- examples -------------------------------------------------------------

func TestExamples(t *testing.T) {
	cases := []struct {
		in   []float64
		want float64
	}{
		{[]float64{3, 1, 2}, 2},       // odd length: the middle value
		{[]float64{1, 2}, 1.5},        // even length: mean of the two middle values
		{[]float64{0, 0}, 0},          // ties
		{[]float64{5}, 5},             // single element
		{[]float64{0, -1}, -0.5},      // negatives
		{[]float64{5, 1, 4, 2, 3}, 3}, // odd length of five: still the middle value
	}
	for _, c := range cases {
		got, err := Median(c.in)
		if err != nil || got != c.want {
			t.Errorf("Median(%v) = %v, %v; want %v, nil", c.in, got, err, c.want)
		}
	}
}

// Answer to an open question: an empty list is an error, not a default.
func TestEmptyIsAnError(t *testing.T) {
	_, err := Median(nil)
	if !errors.Is(err, ErrEmpty) {
		t.Errorf("Median(nil) error = %v; want ErrEmpty", err)
	}
	_, err = Median([]float64{})
	if !errors.Is(err, ErrEmpty) {
		t.Errorf("Median([]) error = %v; want ErrEmpty", err)
	}
}

// --- properties -----------------------------------------------------------

// Finite, non-empty input: quick's raw floats can be huge, which is the point.
func finite(xs []float64) []float64 {
	out := make([]float64, 0, len(xs))
	for _, x := range xs {
		if !math.IsNaN(x) && !math.IsInf(x, 0) {
			out = append(out, x)
		}
	}
	return out
}

func TestOrderDoesNotMatter(t *testing.T) {
	f := func(xs []float64, seed int64) bool {
		xs = finite(xs)
		if len(xs) == 0 {
			return true
		}
		ys := append([]float64(nil), xs...)
		rand.New(rand.NewSource(seed)).Shuffle(len(ys), func(i, j int) { ys[i], ys[j] = ys[j], ys[i] })
		a, _ := Median(xs)
		b, _ := Median(ys)
		return a == b
	}
	if err := quick.Check(f, nil); err != nil {
		t.Error(err)
	}
}

func TestBetweenMinAndMax(t *testing.T) {
	f := func(xs []float64) bool {
		xs = finite(xs)
		if len(xs) == 0 {
			return true
		}
		m, err := Median(xs)
		if err != nil {
			return false
		}
		s := append([]float64(nil), xs...)
		sort.Float64s(s)
		return s[0] <= m && m <= s[len(s)-1]
	}
	if err := quick.Check(f, nil); err != nil {
		t.Error(err)
	}
}

// Pins the position: without this, any fixed position (the first third, say) would
// pass "order does not matter" and "between min and max".
func TestHalfAtOrBelowAndHalfAtOrAbove(t *testing.T) {
	f := func(xs []float64) bool {
		xs = finite(xs)
		if len(xs) == 0 {
			return true
		}
		m, err := Median(xs)
		if err != nil {
			return false
		}
		below, above := 0, 0
		for _, x := range xs {
			if x <= m {
				below++
			}
			if x >= m {
				above++
			}
		}
		return 2*below >= len(xs) && 2*above >= len(xs)
	}
	if err := quick.Check(f, nil); err != nil {
		t.Error(err)
	}
}

func TestDoesNotModifyItsInput(t *testing.T) {
	f := func(xs []float64) bool {
		xs = finite(xs)
		before := make([]float64, len(xs))
		copy(before, xs)
		Median(xs)
		return reflect.DeepEqual(before, xs)
	}
	if err := quick.Check(f, nil); err != nil {
		t.Error(err)
	}
}
