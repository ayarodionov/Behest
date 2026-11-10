---
name: behest-haskell
description: "Haskell specifics for the behest-contract-first workflow: QuickCheck contract files, effect declarations, a QuickCheck disagreement check, and the questions that are usually open in Haskell code. Use together with behest-contract-first in a Haskell project."
---

# Behest for Haskell

Follow `behest-contract-first` for the workflow. This skill covers the Haskell details.

**Status:** the templates were compiled and run with GHC 9.4 and QuickCheck 2.14 (from apt): the contract passes and the disagreement template shrinks to `[0.0,1.0]`.

Haskell already puts effects in types: a function without `IO` in its type cannot print or read the clock. The contract's effects line is therefore short for most modules, and the scan mainly catches `unsafePerformIO`, hidden mutable references and `Debug.Trace`.

## Setup

```sh
cabal install --lib QuickCheck        # or: stack, or apt install libghc-quickcheck2-dev
```

For a cabal project add `QuickCheck` to the `build-depends` of a `test-suite` stanza.

## Contract file

One file per module: `test/ContractTest.hs`, with `main :: IO ()`. Start from `templates/ContractTest.hs`.

- Examples are a list of `(description, Bool)` pairs checked before the properties run.
- Properties are `Property` values built with `forAllShrink gen shrink`. QuickCheck shrinks failures and prints the seed, so a counterexample can become a new example.
- The first line is the effects declaration: `-- behest-effects: io`. The runner prints, so the contract file declares `io`; the module under test is scanned separately and should declare `none`.
- QuickCheck's `Double` generator rarely reaches huge values: the template mixes them in, and the examples pin the boundary.

Run:

```sh
cabal test            # or: runghc -isrc test/ContractTest.hs
scripts/effects.sh src/Median.hs
```

(`scripts/` is in the `behest-contract-first` skill directory.) Scan the implementation files, not the tests; the implementation carries its own `-- behest-effects: none` header, or pass `--declared` with the contract file.

## Disagreement check

Copy `templates/DisagreeScratch.hs` next to the module, write the alternative, and run `runghc DisagreeScratch.hs`. Each shrunk input QuickCheck prints is a missing example. Delete the file when done. The alternative must pass the approved contract first.

## Questions that are usually open in Haskell code

- **Failure convention:** `Maybe`, `Either` (which error type?), an exception, or `error`? Partial functions (`head`, `!!`, `fromJust`) are bottoms: are they allowed?
- **Totality and laziness:** must the function terminate on infinite lists? Is it strict in its argument? What does `undefined` as an element do?
- **Numbers:** `Int` wraps on overflow, `Integer` does not; `Double` has NaN, infinities and `-0.0`; `Rational` and `Scientific` for exactness. Is `==` on `Double` what the contract means?
- **Ordering:** which `Ord` instance? `sort` is stable; `Data.List.sortOn` caches the key.
- **Types:** `String` versus `Text` versus `ByteString`; list versus `Vector` versus `NonEmpty` (the type can make the empty case impossible).
- **Typeclass laws:** if an instance is defined, are its laws (monoid, functor, `Ord` consistency) part of the contract? Test them as properties.
- **Effects at the edge:** which functions may live in `IO`, which must stay pure, and is `unsafePerformIO` forbidden?
- **Concurrency:** STM versus `MVar`; async exceptions.

## Effects in Haskell

Names: `send` (`MVar`, `TVar`, `Chan`, `atomically`), `spawn` (`forkIO`, `async`, `System.Process`), `io` (any `IO` in a signature, `putStrLn`, `readFile`, `Debug.Trace`, `unsafePerformIO`), `time` (`getCurrentTime`, `threadDelay`), `random` (`System.Random`), `state` (`IORef`, mutable arrays and vectors, `unsafe*`). `ets` does not apply. The scan reads source text, so an `IO` that appears only through a type synonym or an imported function is not seen; the type checker already knows. It is a grep heuristic.
