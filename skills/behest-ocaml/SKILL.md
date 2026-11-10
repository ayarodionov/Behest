---
name: behest-ocaml
description: "OCaml specifics for the behest-contract-first workflow: QCheck and dune contract files, effect declarations, a QCheck disagreement check, and the questions that are usually open in OCaml code. Use together with behest-contract-first in an OCaml project."
---

# Behest for OCaml

Follow `behest-contract-first` for the workflow. This skill covers the OCaml details.

**Status:** the templates were compiled and run with OCaml 4.14 and QCheck 0.21 (from apt), built with `ocamlfind`: the contract passes (2 properties plus the examples) and the disagreement template shrinks to a two-element input such as `[0.; 4.]`. The `dune` stanza below was not run (dune was not available where this was tested). Two QCheck details are handled in the templates: its list shrinker can shrink below the minimum size (to `[]`), and removing one element at a time flips odd/even length and can stop early.

## Setup

```sh
opam install qcheck-core
```

`dune` project, with the test as an executable:

```
; test/dune
(test (name median_contract) (libraries median qcheck-core qcheck-core.runner))
```

## Contract file

One file per module: `test/<name>_contract.ml`. Start from `templates/median_contract.ml`.

- Examples are a list of `(description, boolean)` pairs checked before the properties run.
- Properties use `QCheck.Test.make` with an arbitrary that carries a printer (`QCheck.set_print`), so a failure prints the minimal input. QCheck shrinks failures and prints the seed (`QCHECK_SEED`), so a counterexample can become a new example.
- The first line is the effects declaration: `(* behest-effects: none *)`. The test runner prints, so the contract file declares `io`; the module under test is scanned separately.
- `=` on floats is IEEE (`nan <> nan`, `0. = -0.`), `compare` is a total order (`compare nan nan = 0`). Use `Float.equal` when the contract distinguishes them.

Run:

```sh
dune test                 # or, without dune:
ocamlfind ocamlopt -package qcheck-core -package qcheck-core.runner -linkpkg src/median.ml test/median_contract.ml -o contract && ./contract
scripts/effects.sh --declared test/<name>_contract.ml src/<name>.ml
```

(`scripts/` is in the `behest-contract-first` skill directory.) Scan the implementation files, not the tests. For the pure module the declaration (a comment in the approved contract) would be `none` in the module itself; pass `--declared` with a file whose header says so, or let the module carry its own header.

## Disagreement check

Copy `templates/disagree_scratch.ml` next to the contract, add it as a test executable in `dune`, write the alternative, and run `dune test`. Each shrunk input QCheck prints is a missing example. Delete the file when done. The alternative must pass the approved contract first.

## Questions that are usually open in OCaml code

- **Failure convention:** raise (which exception: `Invalid_argument`, `Failure`, `Not_found`, a custom one?), `option`, or `result` (which error type)?
- **Numbers:** `int` is 63-bit and wraps silently. Floats: NaN, infinities, `=` versus `compare`, `-0.`. Integer division by zero raises.
- **Polymorphic equality and compare:** they raise on functional values and loop on cyclic ones; are they allowed, or must the code use typed `equal` functions?
- **Mutation:** `ref`, mutable record fields, `Array` and `Bytes` are mutable. May the function modify its argument (`Array.sort` does)?
- **Lists:** `List.map` and friends are not tail-recursive before OCaml 5.1, so long lists can overflow the stack. Must the function handle a million elements?
- **Laziness:** `Seq` is lazy and may be one-shot or repeatable.
- **Concurrency:** domains, threads, Lwt or Eio? What happens to exceptions in other fibers?
- **Interface:** is the `.mli` part of the contract? Abstract types, what is exposed.

## Effects in OCaml

Names: `send` (`Event`, `Mutex`, `Condition`, Eio streams, Lwt mvars), `spawn` (`Thread.create`, `Domain.spawn`, `Unix.fork`, Eio fibers), `io` (`print_*`, `Printf.printf`, channels, `Unix.`, `Sys.command`, `In_channel`), `time` (`Sys.time`, `Unix.gettimeofday`, sleeps), `random` (`Random.`), `state` (`ref`, `:=`, `mutable` fields, `Hashtbl`, `Array.set`, `Bytes.set`, `Atomic`). `ets` does not apply. `Printf.sprintf` is pure and is not reported. A local `ref` used as a loop counter is reported as `state` too: declare it or restructure. The scan is a grep heuristic: `open` of a module and then unqualified calls (`let open Unix in`) are missed.
