// Disagreement check (scratch file: never commit, never approve).
//
// Copy next to the package, change Median to the function under test, and write the second
// implementation in alt_scratch_test.go (same package, deliberately different:
// another algorithm, or the other plausible reading of the request).
// It must first pass the approved contract.
//
//	go test -run XXX -fuzz FuzzDisagree -fuzztime 20s
//
// Go's fuzzer shrinks a failure to a small input and saves it in
// testdata/fuzz/FuzzDisagree/. Show that input and both answers to the human;
// each one is a missing example. Delete testdata/fuzz/FuzzDisagree/ and this
// file when done.
//
// behest-effects: none
package median // <- the package under test

import (
	"fmt"
	"testing"
)

// Bytes -> small integer-valued floats. Small values hit ties, negatives and
// zeros, which is where meaning differs; widen the mapping if you need more.
func decode(b []byte) []float64 {
	xs := make([]float64, len(b))
	for i, v := range b {
		xs[i] = float64(int8(v))
	}
	return xs
}

func FuzzDisagree(f *testing.F) {
	f.Add([]byte{})
	f.Add([]byte{1, 2, 3})
	f.Add([]byte{0, 0})
	f.Add([]byte{0, 255}) // 0 and -1
	f.Fuzz(func(t *testing.T, b []byte) {
		xs := decode(b)
		// Give each implementation its own copy, so mutation cannot leak across.
		got1, err1 := Median(append([]float64(nil), xs...))    // implementation under test
		got2, err2 := altMedian(append([]float64(nil), xs...)) // the alternative
		if (err1 == nil) != (err2 == nil) || got1 != got2 {
			t.Fatalf("disagree on %v:\n  Median    = %v, %v\n  altMedian = %v, %v",
				xs, got1, err1, got2, err2)
		}
		_ = fmt.Sprint // keep fmt if you add logging
	})
}
