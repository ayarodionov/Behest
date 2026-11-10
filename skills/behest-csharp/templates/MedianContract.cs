// behest-effects: none
//
// Contract for `Median.Of`. Approved by the human; do not edit to make a build pass.
using System;
using System.Linq;
using FsCheck;
using FsCheck.Xunit;
using Xunit;

public class MedianContract
{
    // --- examples -----------------------------------------------------------

    [Fact]
    public void Examples()
    {
        Assert.Equal(2.0, Median.Of(new[] { 3.0, 1.0, 2.0 })); // odd length: the middle value
        Assert.Equal(1.5, Median.Of(new[] { 1.0, 2.0 }));      // even length: mean of the middle two
        Assert.Equal(0.0, Median.Of(new[] { 0.0, 0.0 }));      // ties
        Assert.Equal(5.0, Median.Of(new[] { 5.0 }));           // single element
        Assert.Equal(-0.5, Median.Of(new[] { 0.0, -1.0 }));    // negatives
        Assert.Equal(3.0, Median.Of(new[] { 5.0, 1.0, 4.0, 2.0, 3.0 })); // odd length of five: still the middle value
    }

    // Answer to an open question: an empty list is an error, not a default.
    [Fact]
    public void EmptyIsAnError() =>
        Assert.Throws<EmptyException>(() => Median.Of(Array.Empty<double>()));

    // Answer to an open question: NaN is rejected, not skipped or propagated.
    [Fact]
    public void NaNIsAnError() =>
        Assert.Throws<ArgumentException>(() => Median.Of(new[] { 1.0, double.NaN }));

    // Boundary: the mean of two huge values must not overflow to Infinity.
    [Fact]
    public void HugeValuesDoNotOverflow()
    {
        Assert.Equal(1.7e308, Median.Of(new[] { 1.7e308, 1.7e308 }));
        Assert.Equal(-1.7e308, Median.Of(new[] { -1.7e308, -1.7e308 }));
    }

    // --- properties ---------------------------------------------------------
    // NormalFloat generates finite values only (no NaN, no infinities).

    private static double[] Values(NonEmptyArray<NormalFloat> xs) =>
        xs.Get.Select(f => f.Get).ToArray();

    [Property]
    public bool OrderDoesNotMatter(NonEmptyArray<NormalFloat> xs)
    {
        var a = Values(xs);
        return Median.Of(a) == Median.Of(a.Reverse().ToArray());
    }

    [Property]
    public bool IsBetweenMinAndMax(NonEmptyArray<NormalFloat> xs)
    {
        var a = Values(xs);
        var m = Median.Of(a);
        return a.Min() <= m && m <= a.Max();
    }

    // Pins the position: without this, any fixed position (the first third, say)
    // would pass the two properties above.
    [Property]
    public bool HalfAtOrBelowAndHalfAtOrAbove(NonEmptyArray<NormalFloat> xs)
    {
        var a = Values(xs);
        var m = Median.Of(a);
        return 2 * a.Count(x => x <= m) >= a.Length && 2 * a.Count(x => x >= m) >= a.Length;
    }

    [Property]
    public bool DoesNotModifyItsInput(NonEmptyArray<NormalFloat> xs)
    {
        var a = Values(xs);
        var before = (double[])a.Clone();
        Median.Of(a);
        return a.SequenceEqual(before);
    }
}
