---
name: behest-erlang
description: "Erlang specifics for the behest-contract-first workflow: EUnit and PropEr contract files, effect declarations, and a disagreement-test template. Use together with behest-contract-first when working in an Erlang or rebar3 project."
---

# Behest for Erlang

Follow `behest-contract-first` for the workflow. This skill covers the Erlang details.

## Setup

Contracts use EUnit plus PropEr. In `rebar.config`, make sure PropEr is available for tests (check the current version on hex.pm):

```erlang
{profiles, [{test, [{deps, [proper]}]}]}.
```

Add `.behest-scratch/` to `.gitignore`; throwaway alternative implementations go there, outside `test/`, and are compiled from there for the disagreement check.

## Contract file

One file per module: `test/<module>_contract_tests.erl`. Start from `templates/contract_tests.erl`.

- Examples are EUnit tests with `?assertEqual`.
- Properties are `prop_*` functions using `?FORALL`, run from an EUnit wrapper so that `rebar3 eunit` alone runs everything.
- The first line is the effects declaration, for example `%% behest-effects: none`.

Run:

```sh
rebar3 eunit
rebar3 dialyzer          # if specs are part of the contract
scripts/effects.sh --declared test/<module>_contract_tests.erl src/<module>.erl
```

(`scripts/` is in the `behest-contract-first` skill directory.)

## Reference model and cases for the human

When a slow, obviously correct version exists, start from `templates/reference_tests.erl` instead: the reference lives in the contract file, the main property is `impl(X) =:= reference(X)`, and `cases/0` prints concrete inputs with the answer the contract demands, using the property's own generator:

```sh
erl -noshell -pa <ebin dirs> -eval "uniq_reference_tests:cases(), halt()."
```

Paste that output into the approval question. It needs only the compiled contract, not the implementation. Use `proper_gen:pick(vector(N, element()))` with chosen lengths; picking from `list(...)` at small sizes gives mostly one-element lists, which tell the human nothing.

## Disagreement check

Copy `templates/disagree_tests.erl` and write the alternative as `alt_<module>.erl` in `test/`. Run `rebar3 eunit --module=disagree_tests`. PropEr shrinks a failure to a minimal counterexample, which is the case to show the human. Delete both files when done.

## Questions that are usually open in Erlang code

Ask these before guessing; each one hides a silent choice:

- **Failure convention:** `{ok, V} | {error, R}`, or crash (let it crash)? Which error reason?
- **Equality:** `==` or `=:=`? `1 == 1.0` is true, `1 =:= 1.0` is false. Integer or float results?
- **Invalid input:** `badarg` error, error tuple, or accepted?
- **Binaries vs lists vs strings** for text.
- **Empty and single-element collections**, ordering, duplicates.

## Process code (gen_server, ETS)

- Test through the module's public API, with `start_link` in a fixture (`{setup, ...}`) and a `stop` in cleanup.
- Pass time in as an argument rather than calling the clock inside the logic; keep the clock read in one thin wrapper that declares `time`.
- No `timer:sleep` in contract tests.
- Write the messages and replies as examples: for each call, input and expected reply, including the rejected and unknown cases.
- Declare `send`, `spawn` or `ets` in the contract if the implementation needs them; adding one later is a contract change that needs the human's approval.

### A real process: the stateful contract

When the thing under test is a `gen_server` whose replies depend on what came before, start from `templates/statem_tests.erl` (the contract of [`examples/ttl-cache-erlang`](../examples/ttl-cache-erlang/), which runs):

- **A model** is the reference: a pure function `model(Command, State) -> {Reply, State}` over a small map. It is part of the contract and short enough to read.
- **The property** uses `proper_statem`: random command sequences run against the real process, and every reply must equal the model's. PropEr shrinks a failure to the shortest sequence, for example `put(a, 6, ttl 1); advance 1; get(a)` for an off-by-one in expiry.
- **Time is a command, not an effect.** The server gets its clock as a fun; the contract keeps the time in a counter and has an `advance` command. The effects line is `send, spawn`, so an implementation that reads the real clock or starts a timer fails the scan.
- **Examples are scripts** of `{Command, ExpectedReply}` in order, each also checked against the model so an example cannot contradict it.
- **`cases/0`** prints generated sequences with the model's reply at every step for the approval message. Random sequences are mostly dull (misses on an empty cache), so it generates 200 and prints the three in which the most happens.
- Weight the generator (`frequency`) towards the commands that build state, and use few keys and short lifetimes so that collisions and expiries are common.
