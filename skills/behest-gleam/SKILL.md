---
name: behest-gleam
description: "Gleam specifics for the behest-contract-first workflow: gleeunit and qcheck contract files, effect declarations, a qcheck disagreement check, and the questions that are usually open in Gleam code. Use together with behest-contract-first in a Gleam project. Templates are written from the qcheck docs and have not been run."
---

# Behest for Gleam

Follow `behest-contract-first` for the workflow. This skill covers the Gleam details.

**Status:** the templates follow the qcheck 1.0 documentation but were not run on a real Gleam installation (the Hex package registry was not reachable where they were written). If a function name has changed, fix the template and tell the human.

## Setup

```sh
gleam add --dev gleeunit qcheck
```

Gleam 1.11 or newer is needed for `assert` in tests.

## Contract file

One file per module: `test/<name>_contract_test.gleam`. Start from `templates/contract_test.gleam`.

- Examples are `assert` expressions in `pub fn <name>_test()`.
- Properties use `use x <- qcheck.given(generator)`; qcheck shrinks failures and prints a minimal input.
- The first line is the effects declaration: `// behest-effects: none`.
- Gleam has no exceptions: the failure convention is a `Result`, so the contract names the error type.

Run:

```sh
gleam test
scripts/effects.sh --declared test/<name>_contract_test.gleam src/<name>.gleam
```

(`scripts/` is in the `behest-contract-first` skill directory.) Scan the implementation files, not the tests.

## Disagreement check

Copy `templates/disagree_test.gleam` to `test/disagree_scratch_test.gleam`, write the alternative, run `gleam test`. Each failing input qcheck prints is a missing example. Delete the file when done. The alternative must pass the approved contract first.

## Questions that are usually open in Gleam code

- **Error type:** `Result(a, Nil)` or a named error type? Which variants, and are they part of the public API?
- **Ints and floats:** no implicit conversion. Integer division by zero returns `0`, not an error. On the BEAM, ints are arbitrary precision; on the JavaScript target they are not, so say which target the contract is for.
- **Floats:** no NaN or infinity on the BEAM (overflow raises). `==` on floats is exact.
- **Order and stability:** is `list.sort` stability relied on? Is the order of `dict` keys part of the contract?
- **Partial functions:** `let assert` and `panic` crash the process. Are they allowed anywhere in the implementation?
- **Processes:** which actor protocol, which messages, which timeouts (see the Erlang and Elixir skills for the same questions).
- **FFI:** every `@external` is an unchecked call; the contract should say what it may do.

## Effects in Gleam

Names: `send` (`process.send`, `process.call`, `actor.call`), `spawn` (`process.start`, `actor.start`, `task.async`), `ets` (the `ets` packages), `io` (`io.println`, `simplifile`, HTTP clients, any `@external`), `time` (`gleam/time`, `process.sleep`, system time), `random` (`int.random`, `list.shuffle`, crypto), `state` (`persistent_term`, process dictionary, actors with state). Plain Gleam is pure by construction: there is no mutable state in the language, so most modules declare `none`. The scan is a grep heuristic; an `@external` is reported as `io`, but what it really does is up to the Erlang or JavaScript behind it.
