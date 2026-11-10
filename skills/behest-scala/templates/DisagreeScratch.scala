// behest-effects: none
//
// Disagreement check (scratch file: never commit, never approve).
// Save under src/test/scala and run `sbt "testOnly DisagreeScratch"`.
//
// ScalaCheck shrinks a failure to a minimal input and prints it; show that input
// and both answers to the human. Each one is a missing example. The alternative
// must pass the approved contract first. Delete this file when done.
import org.scalacheck.Prop.forAll
import org.scalacheck.{Gen, Properties}

object DisagreeScratch extends Properties("disagree") {

  /** The alternative: deliberately different (another algorithm, or the other
   *  plausible reading of the request). */
  def altMedian(xs: List[Double]): Double = xs.sorted.apply((xs.length - 1) / 2) // lower middle value

  // Small integers hit ties, zeros and negatives, where meaning differs.
  private val small: Gen[List[Double]] = Gen.nonEmptyListOf(Gen.choose(-5, 5).map(_.toDouble))

  property("implementations agree") = forAll(small) { xs =>
    // `==` treats 0.0 and -0.0 as equal; use java.lang.Double.compare if the contract does not.
    median(xs) == Right(altMedian(xs))
  }
}
