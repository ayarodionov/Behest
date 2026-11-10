// behest-effects: none
//
// Contract for Median.median. Approved by the human; do not edit to make a build pass.
package example;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Random;
import org.junit.jupiter.api.Test;

class MedianContractTest {

    // --- examples -----------------------------------------------------------

    @Test
    void examples() {
        assertEquals(2.0, Median.median(List.of(3.0, 1.0, 2.0))); // odd length: the middle value
        assertEquals(1.5, Median.median(List.of(1.0, 2.0)));      // even length: mean of the middle two
        assertEquals(0.0, Median.median(List.of(0.0, 0.0)));      // ties
        assertEquals(5.0, Median.median(List.of(5.0)));           // single element
        assertEquals(-0.5, Median.median(List.of(0.0, -1.0)));    // negatives
        assertEquals(3.0, Median.median(List.of(5.0, 1.0, 4.0, 2.0, 3.0))); // odd length of five: still the middle value
    }

    // Answer to an open question: an empty list is an error, not a default.
    @Test
    void emptyIsAnError() {
        assertThrows(IllegalArgumentException.class, () -> Median.median(List.of()));
    }

    // Answer to an open question: NaN is rejected, not skipped or propagated.
    @Test
    void nanIsAnError() {
        assertThrows(IllegalArgumentException.class,
                () -> Median.median(List.of(1.0, Double.NaN)));
    }

    // Boundary: the mean of two huge values must not overflow to infinity.
    // (The random properties below rarely reach this, so it is an explicit example.)
    @Test
    void hugeValuesDoNotOverflow() {
        assertEquals(Double.MAX_VALUE, Median.median(List.of(Double.MAX_VALUE, Double.MAX_VALUE)));
        assertEquals(-Double.MAX_VALUE, Median.median(List.of(-Double.MAX_VALUE, -Double.MAX_VALUE)));
    }

    // --- properties -----------------------------------------------------------
    // Random inputs from a seeded generator, so a failure can be replayed. No
    // library needed; jqwik is an optional upgrade that adds automatic shrinking.

    private static final int RUNS = 2000;

    private static List<Double> randomNumbers(Random rnd) {
        int n = 1 + rnd.nextInt(12);
        List<Double> xs = new ArrayList<>();
        while (xs.size() < n) {
            // Random bit patterns cover every exponent; keep only finite values.
            double d = Double.longBitsToDouble(rnd.nextLong());
            if (!Double.isNaN(d) && !Double.isInfinite(d)) {
                xs.add(d);
            }
        }
        return xs;
    }

    @Test
    void orderDoesNotMatter() {
        Random rnd = new Random(20260101L);
        for (int i = 0; i < RUNS; i++) {
            List<Double> xs = randomNumbers(rnd);
            List<Double> ys = new ArrayList<>(xs);
            Collections.shuffle(ys, rnd);
            assertEquals(Median.median(xs), Median.median(ys), "input " + xs);
        }
    }

    @Test
    void betweenMinAndMax() {
        Random rnd = new Random(20260102L);
        for (int i = 0; i < RUNS; i++) {
            List<Double> xs = randomNumbers(rnd);
            double m = Median.median(xs);
            assertTrue(Collections.min(xs) <= m && m <= Collections.max(xs),
                    "median " + m + " outside range of " + xs);
        }
    }

    // Pins the position: without this, any fixed position (the first third, say)
    // would pass "order does not matter" and "between min and max".
    @Test
    void halfAtOrBelowAndHalfAtOrAbove() {
        Random rnd = new Random(20260104L);
        for (int i = 0; i < RUNS; i++) {
            List<Double> xs = randomNumbers(rnd);
            double m = Median.median(xs);
            long below = xs.stream().filter(x -> x <= m).count();
            long above = xs.stream().filter(x -> x >= m).count();
            assertTrue(2 * below >= xs.size() && 2 * above >= xs.size(),
                    "median " + m + " of " + xs);
        }
    }

    @Test
    void doesNotModifyItsInput() {
        Random rnd = new Random(20260103L);
        for (int i = 0; i < RUNS; i++) {
            List<Double> xs = randomNumbers(rnd);
            List<Double> copy = new ArrayList<>(xs);
            Median.median(copy);
            assertEquals(xs, copy);
        }
    }
}
