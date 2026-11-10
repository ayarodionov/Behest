// behest-effects: none
//
// Disagreement check (scratch file: never commit, never approve).
// Save as DisagreeScratch.cs in the test project and run
// `dotnet test --filter DisagreeScratch`.
//
// FsCheck shrinks a failure and prints it; show that input and both answers to the
// human. Each one is a missing example. The alternative must pass the approved
// contract first. Delete this file when done.
using System;
using System.Linq;
using FsCheck;
using FsCheck.Xunit;

public class DisagreeScratch
{
    /// The alternative: deliberately different (another algorithm, or the other
    /// plausible reading of the request).
    private static double AltMedian(double[] xs)
    {
        var s = xs.OrderBy(v => v).ToArray();
        return s[(s.Length - 1) / 2]; // lower middle value
    }

    // Small integers hit ties, zeros and negatives, where meaning differs.
    // The mapping folds any int into -5..5; FsCheck shrinks the underlying ints.
    private static double Small(int v) => ((v % 11) + 11) % 11 - 5;

    [Property(MaxTest = 2000)]
    public bool ImplementationsAgree(NonEmptyArray<int> raw)
    {
        var xs = raw.Get.Select(Small).ToArray();
        var a = Median.Of((double[])xs.Clone());
        var b = AltMedian((double[])xs.Clone());
        // `==` treats 0.0 and -0.0 as equal; use BitConverter if the contract does not.
        return a == b;
    }
}
