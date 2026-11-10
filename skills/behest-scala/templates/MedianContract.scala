// behest-effects: none
//
// Contract for `median`. Approved by the human; do not edit to make a build pass.
import org.scalacheck.Prop.forAll
import org.scalacheck.{Arbitrary, Gen, Prop, Properties}

object MedianContract extends Properties("median") {

  // --- examples -------------------------------------------------------------

  property("examples") = Prop(
    median(List(3.0, 1.0, 2.0)) == Right(2.0) && // odd length: the middle value
      median(List(1.0, 2.0)) == Right(1.5) && // even length: mean of the middle two
      median(List(0.0, 0.0)) == Right(0.0) && // ties
      median(List(5.0)) == Right(5.0) && // single element
      median(List(5.0, 1.0, 4.0, 2.0, 3.0)) == Right(3.0) && // odd length of five: still the middle value
      median(List(0.0, -1.0)) == Right(-0.5) // negatives
  )

  // Answer to an open question: an empty list is an error, not a default.
  property("empty is an error") = Prop(median(Nil) == Left(MedianError.Empty))

  // Answer to an open question: NaN is rejected, not skipped or propagated.
  property("NaN is an error") = Prop(median(List(1.0, Double.NaN)) == Left(MedianError.NotANumber))

  // Boundary: the mean of two huge values must not overflow to Infinity.
  property("no overflow") = Prop(
    median(List(1.7e308, 1.7e308)) == Right(1.7e308) &&
      median(List(-1.7e308, -1.7e308)) == Right(-1.7e308)
  )

  // --- properties -----------------------------------------------------------
  // Plain arbitrary doubles rarely reach huge values; the examples above cover them.

  private val number: Gen[Double] = Arbitrary.arbitrary[Double].suchThat(d => !d.isNaN && !d.isInfinity)
  private val numbers: Gen[List[Double]] = Gen.nonEmptyListOf(number)

  property("order does not matter") = forAll(numbers) { xs =>
    median(xs) == median(xs.reverse)
  }

  property("is between min and max") = forAll(numbers) { xs =>
    median(xs).exists(m => xs.min <= m && m <= xs.max)
  }

  // Pins the position: without this, any fixed position (the first third, say)
  // would pass the two properties above.
  property("half at or below, half at or above") = forAll(numbers) { xs =>
    median(xs).exists(m => 2 * xs.count(_ <= m) >= xs.length && 2 * xs.count(_ >= m) >= xs.length)
  }
}
