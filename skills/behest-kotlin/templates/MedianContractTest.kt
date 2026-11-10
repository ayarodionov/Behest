// behest-effects: none
//
// Contract for `median`. Approved by the human; do not edit to make a build pass.
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.StringSpec
import io.kotest.matchers.doubles.shouldBeBetween
import io.kotest.matchers.shouldBe
import io.kotest.property.Arb
import io.kotest.property.arbitrary.double
import io.kotest.property.arbitrary.filter
import io.kotest.property.arbitrary.list
import io.kotest.property.checkAll

class MedianContractTest : StringSpec({

    // --- examples -------------------------------------------------------------

    "matches the approved examples" {
        median(listOf(3.0, 1.0, 2.0)) shouldBe 2.0 // odd length: the middle value
        median(listOf(1.0, 2.0)) shouldBe 1.5 // even length: mean of the middle two
        median(listOf(0.0, 0.0)) shouldBe 0.0 // ties
        median(listOf(5.0)) shouldBe 5.0 // single element
        median(listOf(0.0, -1.0)) shouldBe -0.5 // negatives
        median(listOf(5.0, 1.0, 4.0, 2.0, 3.0)) shouldBe 3.0 // odd length of five: still the middle value
    }

    // Answer to an open question: an empty list is an error, not a default.
    "an empty list is an error" {
        shouldThrow<EmptyException> { median(emptyList()) }
    }

    // Answer to an open question: NaN is rejected, not skipped or propagated.
    "NaN is an error" {
        shouldThrow<IllegalArgumentException> { median(listOf(1.0, Double.NaN)) }
    }

    // Boundary: the mean of two huge values must not overflow to Infinity.
    "huge values do not overflow" {
        median(listOf(1.7e308, 1.7e308)) shouldBe 1.7e308
        median(listOf(-1.7e308, -1.7e308)) shouldBe -1.7e308
    }

    // --- properties -----------------------------------------------------------
    // Arb.double() includes NaN and infinities as edge cases; the contract rejects
    // NaN and leaves infinities undecided, so only finite values are generated here.

    val numbers = Arb.list(Arb.double().filter { it.isFinite() }, 1..12)

    "order does not matter" {
        checkAll(numbers) { xs -> median(xs) shouldBe median(xs.reversed()) }
    }

    "is between min and max" {
        checkAll(numbers) { xs -> median(xs).shouldBeBetween(xs.min(), xs.max(), 0.0) }
    }

    // Pins the position: without this, any fixed position (the first third, say)
    // would pass the two properties above.
    "half the values are at or below it and half at or above" {
        checkAll(numbers) { xs ->
            val m = median(xs)
            (2 * xs.count { it <= m } >= xs.size) shouldBe true
            (2 * xs.count { it >= m } >= xs.size) shouldBe true
        }
    }

    "does not modify its input" {
        checkAll(numbers) { xs ->
            val before = xs.toList()
            median(xs)
            xs shouldBe before
        }
    }
})
