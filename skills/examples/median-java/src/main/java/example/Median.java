package example;

import java.util.Arrays;
import java.util.List;

public final class Median {
    private Median() {}

    /** Median of {@code xs}; the input list is not modified. */
    public static double median(List<Double> xs) {
        if (xs.isEmpty()) {
            throw new IllegalArgumentException("median of an empty list");
        }
        double[] s = new double[xs.size()];
        for (int i = 0; i < s.length; i++) {
            double x = xs.get(i);
            if (Double.isNaN(x)) {
                throw new IllegalArgumentException("median of a list containing NaN");
            }
            s[i] = x;
        }
        Arrays.sort(s);
        int n = s.length;
        if (n % 2 == 1) {
            return s[n / 2];
        }
        return mean(s[n / 2 - 1], s[n / 2]);
    }

    /** Mean of a <= b that cannot overflow to infinity. */
    private static double mean(double a, double b) {
        if ((a < 0) != (b < 0)) {
            return (a + b) / 2; // opposite signs: the sum cannot overflow
        }
        return a + (b - a) / 2; // same sign: the difference cannot overflow
    }
}
