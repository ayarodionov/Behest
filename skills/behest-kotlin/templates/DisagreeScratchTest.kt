// behest-effects: none
//
// Disagreement check (scratch file: never commit, never approve).
// Save as DisagreeScratchTest.kt and run `./gradlew test --tests DisagreeScratchTest`.
//
// Kotest shrinks a failure to a minimal input and prints it; show that input and
// both answers to the human. Each one is a missing example. The alternative must
// pass the approved contract first. Delete this file when done.
import io.kotest.core.spec.style.StringSpec
import io.kotest.matchers.shouldBe
import io.kotest.property.Arb
import io.kotest.property.arbitrary.int
import io.kotest.property.arbitrary.list
import io.kotest.property.arbitrary.map
import io.kotest.property.checkAll

/** The alternative: deliberately different (another algorithm, or the other
 *  plausible reading of the request). */
fun altMedian(xs: List<Double>): Double = xs.sorted()[(xs.size - 1) / 2] // lower middle value

class DisagreeScratchTest : StringSpec({
    // Small integers hit ties, zeros and negatives, where meaning differs.
    val small = Arb.list(Arb.int(-5..5).map { it.toDouble() }, 1..8)

    "implementations agree" {
        checkAll(1000, small) { xs ->
            // `shouldBe` on Double compares with equals(): 0.0 and -0.0 differ.
            // Add 0.0 first if the contract treats them as equal.
            (median(xs.toList()) + 0.0) shouldBe (altMedian(xs.toList()) + 0.0)
        }
    }
})
