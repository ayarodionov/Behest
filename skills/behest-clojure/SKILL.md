---
name: behest-clojure
description: "Clojure specifics for the behest-contract-first workflow: clojure.test and test.check contract files, effect declarations, a test.check disagreement check, and the questions that are usually open in Clojure code. Use together with behest-contract-first in a Clojure project."
---

# Behest for Clojure

Follow `behest-contract-first` for the workflow. This skill covers the Clojure details.

## Setup (`deps.edn`)

```clojure
{:paths ["src"]
 :aliases {:test {:extra-paths ["test"]
                  :extra-deps {org.clojure/test.check {:mvn/version "1.1.1"}}}}}
```

Leiningen works too: add `[org.clojure/test.check "1.1.1"]` to the `:dev` profile.

## Contract file

One file per namespace: `test/<name>_contract_test.clj`. Start from `templates/median_contract_test.clj`.

- Examples are `deftest` with `is`; `(is (thrown? ExceptionClass ...))` for invalid input.
- Properties use `defspec` with `prop/for-all`. test.check shrinks failures and prints the seed, so a counterexample can become a new example.
- The first line is the effects declaration: `;; behest-effects: none`.
- `(= 1 1.0)` is false and `(== 1 1.0)` is true. Use `=` and check the type (`double?`) where the result type is part of the contract.

Run:

```sh
clojure -M:test -e "(require 'median-contract-test) (clojure.test/run-tests 'median-contract-test)"
scripts/effects.sh --declared test/<name>_contract_test.clj src/<name>.clj
```

(`scripts/` is in the `behest-contract-first` skill directory.) Scan the implementation files, not the tests.

## Disagreement check

Copy `templates/disagree_scratch_test.clj` to `test/`, write the alternative, and run its namespace as above. Each shrunk input test.check prints is a missing example. Delete the file when done. The alternative must pass the approved contract first.

## Questions that are usually open in Clojure code

- **Failure convention:** throw (`ex-info` with which `:type` data, or a Java exception class?), return `nil`, or a map with `:error`?
- **`nil` punning:** `(first [])`, `(get m k)`, `(seq [])` all give `nil`. Is `nil` input accepted and what does it mean (empty, missing, error)?
- **Numbers:** `long` overflow throws (`+`) but `+'` promotes to BigInt; ratios (`(/ 1 3)`); `BigDecimal`; NaN (`(= ##NaN ##NaN)` is false); `=` versus `==`; `-0.0`.
- **Laziness:** lazy sequences realize late and cache; exceptions and side effects inside `map` or `for` surface at the wrong time. Must the result be realized (`vec`, `doall`)?
- **Collections:** vector, list, set or any seqable? Is the result type stable whatever the input type? Ordering of maps and sets.
- **Validation:** are `clojure.spec` or Malli specs part of the contract or advisory?
- **Concurrency:** atoms, refs, agents, `core.async` channels: what protocol, what happens on failure and shutdown?
- **Java interop:** reflection, `null` from Java calls, checked exceptions.

## Effects in Clojure

Names: `send` (`send`, `send-off`, `core.async` channels, promises), `spawn` (`future`, `pmap`, `go`, `thread`, agents, executors), `io` (`println`, `slurp`, `spit`, `with-open`, `clojure.java.io`, HTTP clients), `time` (`System/currentTimeMillis`, `Thread/sleep`, `(time ...)`), `random` (`rand`, `rand-int`, `shuffle`, `random-uuid`), `state` (`atom`, `ref`, `swap!`, `reset!`, `defonce`, dynamic vars, `alter-var-root`, arrays). `ets` does not apply. The scan matches the call syntax `(name ...)`, so it misses functions passed as values (`(map println xs)`) and anything behind a macro. It is a grep heuristic.
