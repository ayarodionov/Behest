---
name: behest-elixir
description: "Elixir specifics for the behest-contract-first workflow: ExUnit contract files with StreamData, PropEr or the standard library, effect declarations, and disagreement and stateful (GenServer) templates. Use together with behest-contract-first when working in an Elixir or Mix project."
---

# Behest for Elixir

Follow `behest-contract-first` for the workflow. This skill covers the Elixir details.

## Setup

Contracts are ExUnit tests. The properties can be run by one of three engines; pick one per project and use its templates throughout.

| Engine | Use when | Dependency | Templates |
| --- | --- | --- | --- |
| **StreamData** (default) | Nothing else is in use | `{:stream_data, "~> 1.0", only: [:dev, :test]}` | `contract_test.exs`, `disagree_test.exs`, `reference_test.exs` |
| **[PropEr](https://github.com/proper-testing/proper)** | The project or team already uses PropEr (often alongside Erlang code), or you want PropEr's stateful testing (`proper_statem`) | `{:proper, "~> 1.5", only: :test}` | `contract_proper_test.exs`, `disagree_proper_test.exs`, `stateful_proper_test.exs` |
| **Standard library only** | No test dependencies can be installed | none | `contract_stdlib_test.exs`, `disagree_stdlib_test.exs`, `stateful_test.exs` |

The standard-library variants use a seeded `:rand` generator and a small shrinker. The PropEr and StreamData variants shrink properly and print the seed.

Add `.behest-scratch/` to `.gitignore`; throwaway alternative implementations go there, outside `test/`, so a plain `mix test` does not run them.

## PropEr from Elixir

The PropEr templates call PropEr directly, with no wrapper. Its Erlang macros are ordinary function calls underneath:

| Erlang | Elixir |
| --- | --- |
| `?FORALL(X, Type, Prop)` | `:proper.forall(type, fn x -> prop end)` |
| `?LET(X, Type, Expr)` | `:proper_types.bind(type, fn x -> expr end, false)` |
| `?SUCHTHAT(X, Type, Cond)` | `:proper_types.add_constraint(type, fn x -> cond end, false)` |
| `?WHENFAIL(Action, Prop)` | `:proper.whenfail(fn -> action end, fn -> prop end)`: **both** arguments are functions |
| `proper:quickcheck(P, Opts)` | `:proper.quickcheck(p, [{:numtests, 500}, {:to_file, :user}])`, then `:proper.counterexample()` for the shrunk input |

- Generators come from `:proper_types` (`list/1`, `non_empty/1`, `integer/0`, `integer/2`, `float/0`, `oneof/1`, `frequency/1`, `vector/2`). A tuple or list with generators inside is itself a generator.
- **Stateful:** the test module itself is the `proper_statem` callback module (`initial_state/0`, `command/1`, `precondition/2`, `next_state/3`, `postcondition/3`, all public), and commands are `{:call, Module, :fun, args}`. A helper the commands call, such as `advance/1` for the clock, must be public too. See `templates/stateful_proper_test.exs`.
- Use PropEr 1.4 or newer. PropEr 1.2 calls `erlang:get_stacktrace/0`, which Erlang/OTP 23 removed, so when a property raises it crashes instead of reporting the exception.

**PropCheck** ([github.com/alfert/propcheck](https://github.com/alfert/propcheck), `{:propcheck, "~> 1.5", only: [:test, :dev]}`) wraps the same engine in Elixir macros: `use PropCheck`, then `property "name" do forall xs <- list(integer()) do ... end end`, with `let`, `such_that` and `when_fail`, and `PropCheck.StateM` for stateful tests. It reads better and keeps failing counterexamples between runs. No PropCheck template is included: it could not be installed where these templates were written (the package registry was not reachable), so a PropCheck version would be untested. The PropEr templates translate directly: `check(type, fn x -> ... end)` becomes `forall x <- type do ... end`.

## Contract file

One file per module: `test/contracts/<module>_contract_test.exs`. Start from `templates/contract_test.exs` (or the PropEr or standard-library variant, as chosen above).

- Examples are plain `assert`s (or doctests for the simplest ones). Any `iex>` example in a `@doc` must be run: add `doctest MyModule` to a test file, or do not write the example.
- Properties use `property` and `check all` from `ExUnitProperties`.
- The first line is the effects declaration, for example `# behest-effects: none`.

Run:

```sh
mix test test/contracts
scripts/effects.sh --declared test/contracts/<module>_contract_test.exs lib/<module>.ex
```

(`scripts/` is in the `behest-contract-first` skill directory.)

## Reference model and cases for the human

When a slow, obviously correct version exists (a plain `Map` for a cache, `Enum` for a hand-written loop), start from `templates/reference_test.exs` instead: the reference lives in the contract file, the main property is `impl(x) === reference(x)`, and a test tagged `:cases` prints concrete inputs with the answer the contract demands (`mix test --only cases`; exclude the tag in `test_helper.exs`). Paste that output into the approval question. This template was not run where it was written; its Erlang twin was.

## Disagreement check

Copy `templates/disagree_test.exs` (or `disagree_stdlib_test.exs`) to `.behest-scratch/`, fill in the alternative implementation, and run `mix test .behest-scratch/disagree_test.exs` (a file path outside `test/` works when given explicitly). StreamData shrinks a failure to a minimal input, which is exactly the case to show the human. Delete the scratch file when done.

## Questions that are usually open in Elixir code

Ask these before guessing; each one hides a silent choice:

- **Failure convention:** `{:ok, v} | {:error, reason}`, or raise? Which exception?
- **Invalid input:** raise `ArgumentError`, return an error tuple, or accept it?
- **Numbers:** is `1 == 1.0` enough, or must results be exactly `===`? Integer or float results?
- **Empty and single-element collections.**
- **Ordering:** does output order matter? Is the sort stable?
- **Duplicates, nil, atoms vs strings** in keys and values.

## Process code (GenServer, Agent, ETS)

- Test through the public API, starting the process with `start_supervised!/1`.
- Pass time in as an argument (`now_ms`) instead of reading the clock inside the logic, so examples stay deterministic and the effect list stays small. Keep the clock read in one thin wrapper that declares `time`.
- No `Process.sleep` in contract tests.
- Write the messages and replies as examples: for each call, input and expected reply, including the "rejected" and "unknown client" cases.
- Declare `send`, `spawn` or `ets` in the contract if the implementation needs them; adding one later is a contract change that needs the human's approval.

### A real process: the stateful contract

When the thing under test is a `GenServer` whose replies depend on what came before, start from `templates/stateful_test.exs`. It needs only the standard library (no StreamData), and it was run against a `TtlCache` GenServer: 7 tests pass, and a seeded off-by-one in expiry was caught and shrunk to `[{:put, :a, 4, 3}, {:advance, 3}, :size]`.

- **A model** is the reference: `model(command, state) -> {reply, state}` over a small map, part of the contract.
- **The property** runs 300 seeded random command sequences against the real process; every reply must equal the model's. A failing sequence is shrunk by removing commands one at a time.
- **Time is a command, not an effect.** The server gets its clock as a function (`clock: fn -> ... end`); the contract keeps the time in a `:counters` cell and has an `{:advance, ms}` command. The effects line is `send, spawn`, so reading the real clock or starting a timer fails the scan.
- **Examples are scripts** of `{command, expected_reply}` in order, each also checked against the model.
- **`mix test --only cases`** prints the three most eventful of 200 generated sequences, with the model's reply at every step, for the approval message.

With StreamData available you can generate the command list with `list_of(one_of([...]))` instead and get its shrinking; the model, scripts and clock stay the same.
