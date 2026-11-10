---
name: behest-scala
description: "Scala specifics for the behest-contract-first workflow: ScalaCheck contract files, effect declarations, a ScalaCheck disagreement check, and the questions that are usually open in Scala code. Use together with behest-contract-first in a Scala project. Templates have not been run."
---

# Behest for Scala

Follow `behest-contract-first` for the workflow. This skill covers the Scala details. The templates use braces so they compile on Scala 2.13 and 3.

**Status:** the templates were written from the ScalaCheck documentation and were not compiled or run (Maven Central was not reachable where they were written). If a name has changed, fix the template and tell the human.

## Setup (sbt)

```scala
libraryDependencies += "org.scalacheck" %% "scalacheck" % "1.18.1" % Test
```

## Contract file

One file per module: `src/test/scala/<Name>Contract.scala`. Start from `templates/MedianContract.scala`.

- Examples are `property("...") = Prop(boolean)`.
- Properties use `forAll(generator) { ... }`. ScalaCheck shrinks failures and prints the seed, so a counterexample can become a new example.
- The first line is the effects declaration: `// behest-effects: none`.
- Failure convention in the template is `Either[MedianError, Double]`; change the examples if the contract chooses exceptions or `Option`.

Run:

```sh
sbt test
scripts/effects.sh --declared src/test/scala/<Name>Contract.scala src/main/scala/<Name>.scala
```

(`scripts/` is in the `behest-contract-first` skill directory.) Scan the implementation files, not the tests.

## Disagreement check

Copy `templates/DisagreeScratch.scala` into `src/test/scala`, write the alternative, and run `sbt "testOnly DisagreeScratch"`. Each shrunk input ScalaCheck prints is a missing example. Delete the file when done. The alternative must pass the approved contract first.

## Questions that are usually open in Scala code

- **Failure convention:** throw, `Option`, `Either` (which error type?), `Try`, or a failed `Future`?
- **Numbers:** `Int` overflow wraps silently. `Double`: NaN, infinities, `==` (IEEE: `NaN != NaN`) versus `equals` on boxed values. `BigDecimal` and `BigInt` when exactness matters.
- **Collections:** immutable by default; `mutable.` ones are state. Strict or lazy (`LazyList`, `view`, iterators are one-shot)? Does the result type depend on the input type?
- **Ordering:** `sorted` is stable; is that relied on? Which `Ordering` for doubles (`Ordering.Double.TotalOrdering` versus IEEE)?
- **Null and Java interop:** `null` from Java APIs is unchecked.
- **Concurrency:** `Future` versus effect types (cats-effect, ZIO), execution context, cancellation, what an exception inside a `Future` does.
- **Implicits and givens:** which instances does the contract depend on?

## Effects in Scala

Names: `send` (actors, queues, `Promise`), `spawn` (`Future`, `Thread`, executors, `Await`), `io` (`println`, `scala.io`, `java.io`, `Files`, HTTP clients, `sys.env`), `time` (`System.currentTimeMillis`, `Instant.now`, `Thread.sleep`), `random` (`scala.util.Random`, `UUID.randomUUID`), `state` (`var`, `mutable.` collections, `Atomic*`, `@volatile`, `synchronized`). `ets` does not apply. Local `var` and `ArrayBuffer` are reported as `state` too: declare it or restructure. Pass the clock and rng in as arguments to keep the core pure. The scan is a grep heuristic: wildcard imports and library calls that do I/O internally are not seen.
