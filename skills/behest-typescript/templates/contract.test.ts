// behest-effects: none
//
// Contract for `median`. Approved by the human; do not edit to make a build pass.
import { describe, expect, it } from "vitest";
import fc from "fast-check";
import { EmptyError, median } from "./median";

describe("examples", () => {
  it("matches the approved examples", () => {
    expect(median([3, 1, 2])).toBe(2); // odd length: the middle value
    expect(median([1, 2])).toBe(1.5); // even length: mean of the middle two
    expect(median([0, 0])).toBe(0); // ties
    expect(median([5])).toBe(5); // single element
    expect(median([0, -1])).toBe(-0.5); // negatives
    expect(median([5, 1, 4, 2, 3])).toBe(3); // odd length of five: still the middle value
  });

  // Answer to an open question: an empty array is an error, not a default.
  it("rejects an empty array", () => {
    expect(() => median([])).toThrow(EmptyError);
  });

  // Answer to an open question: NaN is rejected, not skipped or propagated.
  it("rejects NaN", () => {
    expect(() => median([1, NaN])).toThrow(RangeError);
  });

  // Boundary: the mean of two huge values must not overflow to Infinity.
  it("does not overflow", () => {
    expect(median([1.7e308, 1.7e308])).toBe(1.7e308);
    expect(median([-1.7e308, -1.7e308])).toBe(-1.7e308);
  });
});

// --- properties ---------------------------------------------------------------

const numbers = fc.array(fc.double({ noNaN: true }), { minLength: 1, maxLength: 12 });

describe("properties", () => {
  it("order does not matter", () => {
    fc.assert(
      fc.property(numbers, fc.nat(), (xs, k) => {
        const ys = [...xs.slice(k % xs.length), ...xs.slice(0, k % xs.length)];
        return Object.is(median(xs) + 0, median(ys) + 0); // +0 folds -0 into 0
      }),
    );
  });

  it("is between min and max", () => {
    fc.assert(
      fc.property(numbers, (xs) => {
        const m = median(xs);
        return Math.min(...xs) <= m && m <= Math.max(...xs);
      }),
    );
  });

  // Pins the position: without this, any fixed position (the first third, say)
  // would pass the two properties above.
  it("has half the values at or below it and half at or above", () => {
    fc.assert(
      fc.property(numbers, (xs) => {
        const m = median(xs);
        return (
          2 * xs.filter((x) => x <= m).length >= xs.length &&
          2 * xs.filter((x) => x >= m).length >= xs.length
        );
      }),
    );
  });

  it("does not modify its input", () => {
    fc.assert(
      fc.property(numbers, (xs) => {
        const before = [...xs];
        median(xs);
        return xs.every((x, i) => Object.is(x, before[i]));
      }),
    );
  });
});
