# Skill examples

Finished example projects, each in the state you reach after following the skills: contract files approved and frozen, `OPEN.md` empty, implementation written. Each has a `check.sh` that runs the same checks the skill asks Claude to run. The [walkthrough](../WALKTHROUGH.md) shows how one of them was built, step by step.

| Example | Shows | Status |
| --- | --- | --- |
| [`median-erlang`](median-erlang/) | A pure function. Contract grown through questions: empty list, result type, even-length rule. | `check.sh` passes (EUnit + PropEr 1.2) |
| [`rate-limiter-erlang`](rate-limiter-erlang/) | Time kept out of the logic: a pure core (`behest-effects: none`) plus a one-line clock wrapper (`behest-effects: time`). The contract caught a real bug in the first implementation (limit 0 accepted the first call). | `check.sh` passes (EUnit + PropEr 1.2) |
| [`ttl-cache-erlang`](ttl-cache-erlang/) | A real `gen_server` with a **stateful contract**: random command sequences (`proper_statem`) checked against a small model, time moved by a command instead of the clock, effects limited to `send, spawn`. A seeded off-by-one in expiry was caught and shrunk to three commands. | `check.sh` passes (EUnit + PropEr 1.2); 5 of 5 mutants killed |
| [`median-go`](median-go/) | Go, standard library only (`testing/quick`, `-race`). The contract caught a real overflow in the first implementation: `(a+b)/2` gives Inf for huge floats. | `check.sh` passes (Go 1.24) |
| [`median-rust`](median-rust/) | Rust: cargo tests and proptest. The random properties missed a float overflow even at 100,000 cases, so it became an explicit boundary example in the contract; the naive implementation then failed it. | `check.sh` passes (cargo 1.97, proptest 1.12) |
| [`median-python`](median-python/) | Python: pytest, Hypothesis and `mypy --strict`. The contract failed a naive implementation on result type, NaN and float overflow (Hypothesis found the overflow by itself). | `check.sh` passes (Python 3.13, Hypothesis 6.170) |
| [`median-java`](median-java/) | Java: JUnit 5 with seeded random properties. The contract failed a naive implementation on NaN and float overflow; the random properties missed the overflow, an explicit boundary example caught it. | `check.sh` passes (OpenJDK 21, JUnit 5; run with `javac` and the console jar, not Maven) |
| [`gcd-elixir`](gcd-elixir/) | Elixir: examples in plain ExUnit and properties in StreamData, as two frozen files. | `check.sh` passes on a user's machine (4 properties and 5 tests, with StreamData). Not run where this was written (Hex was blocked there). |

## Run them

```sh
cd skills/examples/median-erlang && ./check.sh        # needs Erlang with EUnit and PropEr
cd skills/examples/rate-limiter-erlang && ./check.sh
cd skills/examples/ttl-cache-erlang && ./check.sh
cd skills/examples/median-go && ./check.sh             # needs Go 1.21 or newer
cd skills/examples/median-rust && ./check.sh           # needs cargo and crates.io
cd skills/examples/median-python && ./check.sh         # needs: pip install pytest hypothesis mypy
cd skills/examples/median-java && ./check.sh           # needs a JDK and: apt install junit5 (or set JUNIT_CONSOLE)
cd skills/examples/gcd-elixir && ./check.sh           # needs Elixir, Mix and access to Hex
```

On Debian or Ubuntu, `apt install erlang-proper erlang-proper-dev erlang-dev` provides what the Erlang examples need.

## What to look at in each project

- `test/*_contract_*` is the contract the human approved. Its first line is the effects declaration.
- `.behest-approved` holds the hash of each approved contract file; `scripts/approved.sh check` fails if one changes.
- `OPEN.md` is empty: every question was answered and folded into the contract.
- `src/` (or `lib/`) is the AI-written implementation, free to regenerate as long as the contract holds.
