# Skill examples

Finished example projects, each in the state you reach after following the skills: contract files approved and frozen, `OPEN.md` empty, implementation written. Each has a `check.sh` that runs the same checks the skill asks Claude to run. The [walkthrough](../WALKTHROUGH.md) shows how one of them was built, step by step.

| Example | Shows | Status |
| --- | --- | --- |
| [`median-erlang`](median-erlang/) | A pure function. Contract grown through questions: empty list, result type, even-length rule. | `check.sh` passes (EUnit + PropEr 1.2) |
| [`rate-limiter-erlang`](rate-limiter-erlang/) | Time kept out of the logic: a pure core (`behest-effects: none`) plus a one-line clock wrapper (`behest-effects: time`). The contract caught a real bug in the first implementation (limit 0 accepted the first call). | `check.sh` passes (EUnit + PropEr 1.2) |
| [`gcd-elixir`](gcd-elixir/) | Elixir: examples in plain ExUnit and properties in StreamData, as two frozen files. | Examples, effect scan and approval checks run and pass. **Properties file not executed** (StreamData could not be fetched where this was written; syntax checked only). |

## Run them

```sh
cd skills/examples/median-erlang && ./check.sh        # needs Erlang with EUnit and PropEr
cd skills/examples/rate-limiter-erlang && ./check.sh
cd skills/examples/gcd-elixir && ./check.sh           # needs Elixir, Mix and access to Hex
```

On Debian or Ubuntu, `apt install erlang-proper erlang-proper-dev erlang-dev` provides what the Erlang examples need.

## What to look at in each project

- `test/*_contract_*` is the contract the human approved. Its first line is the effects declaration.
- `.behest-approved` holds the hash of each approved contract file; `scripts/approved.sh check` fails if one changes.
- `OPEN.md` is empty: every question was answered and folded into the contract.
- `src/` (or `lib/`) is the AI-written implementation, free to regenerate as long as the contract holds.
