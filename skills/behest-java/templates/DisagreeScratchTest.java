// behest-effects: none
//
// Disagreement check (scratch file: never commit, never approve).
// Save as src/test/java/<pkg>/DisagreeScratchTest.java, write the alternative below
// (deliberately different: another algorithm, or the other plausible reading of the
// request; it must pass the approved contract first), and run it with the rest of
// the tests. On a disagreement the test fails with the smallest input found and both
// answers: show them to the human, each one is a missing example.
// Delete this file when done.
package example;

import static org.junit.jupiter.api.Assertions.fail;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Random;
import java.util.function.Function;
import org.junit.jupiter.api.Test;

class DisagreeScratchTest {

    // The alternative: lower middle value for even lengths.
    static double altMedian(List<Double> xs) {
        List<Double> s = new ArrayList<>(xs);
        s.sort(null);
        return s.get((s.size() - 1) / 2);
    }

    // Small integer-valued doubles hit ties, zeros and negatives, where meaning differs.
    static List<Double> randomInput(Random rnd) {
        int n = 1 + rnd.nextInt(8);
        List<Double> xs = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            xs.add((double) (rnd.nextInt(11) - 5));
        }
        return xs;
    }

    // An exception counts as an answer, so "throws" vs "returns" is a disagreement too.
    static String answer(Function<List<Double>, Double> f, List<Double> xs) {
        try {
            return String.valueOf(f.apply(new ArrayList<>(xs))); // each gets its own copy
        } catch (RuntimeException e) {
            return e.getClass().getSimpleName();
        }
    }

    static boolean disagree(List<Double> xs) {
        return !answer(Median::median, xs).equals(answer(DisagreeScratchTest::altMedian, xs));
    }

    // Simplest failing input: drop one or two elements, then replace values with 0, while it still disagrees.
    static List<Double> shrink(List<Double> xs) {
        boolean changed = true;
        while (changed) {
            changed = false;
            // Remove one element, or two (removing one can flip odd/even length and hide a gap).
            for (int i = 0; i < xs.size() && !changed; i++) {
                for (int j = i; j < xs.size() && !changed; j++) {
                    List<Double> ys = new ArrayList<>(xs);
                    ys.remove(j);
                    if (j != i) {
                        ys.remove(i);
                    }
                    if (!ys.isEmpty() && disagree(ys)) {
                        xs = ys;
                        changed = true;
                    }
                }
            }
            for (int i = 0; i < xs.size() && !changed; i++) {
                if (xs.get(i) != 0.0) {
                    List<Double> ys = new ArrayList<>(xs);
                    ys.set(i, 0.0);
                    if (disagree(ys)) {
                        xs = ys;
                        changed = true;
                    }
                }
            }
        }
        return xs;
    }

    @Test
    void implementationsAgree() {
        Random rnd = new Random(1);
        for (int i = 0; i < 2000; i++) {
            List<Double> xs = randomInput(rnd);
            if (disagree(xs)) {
                List<Double> s = shrink(xs);
                fail("DISAGREE on " + s
                        + "\n  median    = " + answer(Median::median, s)
                        + "\n  altMedian = " + answer(DisagreeScratchTest::altMedian, s));
            }
        }
    }
}
