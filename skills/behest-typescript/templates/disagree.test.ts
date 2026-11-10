// behest-effects: none
//
// Disagreement check (scratch file: never commit, never approve).
// Save as disagree.scratch.test.ts and run:
//
//     npx vitest run disagree.scratch.test.ts
//
// fast-check shrinks a failure to a minimal input and prints it; show that input
// and both answers to the human. Each one is a missing example. The alternative
// must pass the approved contract first. Delete this file when done.
import { expect, it } from "vitest";
import fc from "fast-check";
import { median } from "./median"; // the function under test

/** The alternative: deliberately different (another algorithm, or the other
 *  plausible reading of the request). */
function altMedian(xs: number[]): number {
  const s = [...xs].sort((a, b) => a - b);
  return s[Math.floor((s.length - 1) / 2)]; // lower middle value
}

// Small integers hit ties, zeros and negatives, where meaning differs.
const small = fc.array(fc.integer({ min: -5, max: 5 }), { minLength: 1, maxLength: 8 });

it("implementations agree", () => {
  fc.assert(
    fc.property(small, (xs) => {
      // Object.is tells 0 from -0; add 0 first if the contract treats them as equal.
      expect(median([...xs]) + 0).toBe(altMedian([...xs]) + 0);
    }),
  );
});
