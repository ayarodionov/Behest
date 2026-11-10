---
name: behest-kotlin
description: "Kotlin specifics for the behest-contract-first workflow: Kotest property contract files, effect declarations, a Kotest disagreement check, and the questions that are usually open in Kotlin code. Use together with behest-contract-first in a Kotlin project. Templates have not been run."
---

# Behest for Kotlin

Follow `behest-contract-first` for the workflow. This skill covers the Kotlin details.

**Status:** the templates were written from the Kotest documentation and were not compiled or run (Maven Central was not reachable where they were written). If an import or function name has changed, fix the template and tell the human.

## Setup (Gradle, Kotlin DSL)

```kotlin
dependencies {
    testImplementation("io.kotest:kotest-runner-junit5:5.9.1")
    testImplementation("io.kotest:kotest-assertions-core:5.9.1")
    testImplementation("io.kotest:kotest-property:5.9.1")
}
tasks.test { useJUnitPlatform() }
```

## Contract file

One file per module: `src/test/kotlin/<Name>ContractTest.kt`. Start from `templates/MedianContractTest.kt`.

- Examples are plain `shouldBe` assertions; `shouldThrow<E> { ... }` for invalid input.
- Properties use `checkAll(Arb...) { ... }`. Kotest shrinks failures and prints the seed, so a counterexample can become a new example.
- The first line is the effects declaration: `// behest-effects: none`.
- `shouldBe` on `Double` uses `equals`, so `0.0` and `-0.0` differ, and `NaN` equals `NaN`. Decide what the contract means.

Run:

```sh
./gradlew test
scripts/effects.sh --declared src/test/kotlin/<Name>ContractTest.kt src/main/kotlin/<Name>.kt
```

(`scripts/` is in the `behest-contract-first` skill directory.) Scan the implementation files, not the tests.

## Disagreement check

Copy `templates/DisagreeScratchTest.kt` into the test directory, write the alternative, and run `./gradlew test --tests DisagreeScratchTest`. Each shrunk input Kotest prints is a missing example. Delete the file when done. The alternative must pass the approved contract first.

## Questions that are usually open in Kotlin code

- **Failure convention:** throw (which class?), return `null`, `Result<T>`, or a sealed class?
- **Nullability:** is `null` accepted? Platform types from Java calls are unchecked.
- **Numbers:** `Int` overflow wraps silently. `Double`: NaN, infinities, `==` (IEEE) versus `equals` (so `0.0 == -0.0` but `0.0.equals(-0.0)` is false for boxed values).
- **Collections:** `List` is a read-only view, not an immutable one: the caller may still mutate the backing list. May the function mutate its argument (`sort()` versus `sorted()`)?
- **Laziness:** `Sequence` versus `List`; one-shot sequences.
- **Coroutines:** `suspend` or plain? Cancellation, dispatcher, structured concurrency, what happens to children on failure.
- **Equality:** data class `equals`, arrays compare by reference.

## Effects in Kotlin

Names: `send` (`Channel`, `trySend`, `SharedFlow`), `spawn` (`launch`, `async`, `GlobalScope`, `thread`, executors), `io` (`println`, `java.io`, `File`, HTTP clients), `time` (`System.currentTimeMillis`, `Instant.now`, `delay`, `Thread.sleep`), `random` (`Random`, `shuffled`, `UUID.randomUUID`), `state` (`var`, `object` singletons, `mutableListOf`, atomics, `@Volatile`). `ets` does not apply. Local `var` and `mutableListOf` inside a function are reported as `state` too: either declare it or restructure. Pass the clock and rng in as arguments to keep the core pure. The scan is a grep heuristic.
