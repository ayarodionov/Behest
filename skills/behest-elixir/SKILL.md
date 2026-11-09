---
name: behest-elixir
description: "Elixir specifics for the behest-contract-first workflow: ExUnit and StreamData contract files, effect declarations, and a disagreement-test template. Use together with behest-contract-first when working in an Elixir or Mix project."
---

# Behest for Elixir

Follow `behest-contract-first` for the workflow. This skill covers the Elixir details.

## Setup

Contracts use ExUnit plus StreamData. If `mix.exs` lacks it, add:

```elixir
{:stream_data, "~> 1.0", only: [:dev, :test]}
```

Add `test/scratch/` to `.gitignore`; throwaway alternative implementations go there.

## Contract file

One file per module: `test/contracts/<module>_contract_test.exs`. Start from `templates/contract_test.exs`.

- Examples are plain `assert`s (or doctests for the simplest ones).
- Properties use `property` and `check all` from `ExUnitProperties`.
- The first line is the effects declaration, for example `# behest-effects: none`.

Run:

```sh
mix test test/contracts
scripts/effects.sh --declared test/contracts/<module>_contract_test.exs lib/<module>.ex
```

(`scripts/` is in the `behest-contract-first` skill directory.)

## Disagreement check

Copy `templates/disagree_test.exs` to `test/scratch/`, fill in the alternative implementation, and run `mix test test/scratch`. StreamData shrinks a failure to a minimal input, which is exactly the case to show the human. Delete the scratch file when done.

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
