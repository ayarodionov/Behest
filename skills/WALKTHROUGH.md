# Walkthrough: building `median` with the skills

A worked session using the [Behest skills](README.md) on an Erlang task: a human who writes almost no code, and Claude following `behest-contract-first` and `behest-erlang`.

**How to read this.** Every command and its output below is real: I ran the scripts, the tests and the PropEr searches while writing this page. The dialogue between "You" and "Claude" is illustrative; it shows what the skill asks Claude to say, not a recorded session. Random counterexamples differ from run to run (here `[0,0]` and `[0,-1]`; another run may give `[0,1]`). Long error output is trimmed to the lines that matter, marked `...`.

The finished project is [`examples/median-erlang`](examples/median-erlang/).

## Setup (once)

```sh
cp -r skills/behest-* .claude/skills/
```

and add the edit-blocking hook from the [skills README](README.md#enforcement-optional-recommended). `S` below stands for `.claude/skills/behest-contract-first`.

## 1. You make a request; Claude drafts a contract and sends one message

> **You:** I need a median function in Erlang. Module `median`, function `median/1`, takes a list of numbers.

Claude does not write the function. It first says which tier it is using ("**Tier: standard**, because this is a library function other code will call"; see [tiers](README.md#tiers)), then writes the contract (`test/median_contract_tests.erl`): one example, two properties, and the effects declaration at the top.

```erlang
%% behest-effects: none
...
odd_length_test() ->
    ?assertEqual({ok, 2.0}, median:median([3.0, 1.0, 2.0])).

order_does_not_matter_test_() -> prop_test(prop_order()).
between_min_and_max_test_() -> prop_test(prop_bounds()).
```

Everything the request did not say goes into `OPEN.md`, each point with a proposed answer, sorted into what to ask and what to assume:

```
$ cat OPEN.md
# Open items

## Questions

- [ ] median([]) -> {error, empty}, or a default such as {ok, 0}?

## Defaults

- [ ] median([5.0]) -> {ok, 5.0}
- [ ] the input order does not matter
- [ ] a list containing a non-number crashes (no special error)
$ S/scripts/check_open.sh
5:- [ ] median([]) -> {error, empty}, or a default such as {ok, 0}?
9:- [ ] median([5.0]) -> {ok, 5.0}
10:- [ ] the input order does not matter
11:- [ ] a list containing a non-number crashes (no special error)
unresolved open items in OPEN.md: show them to the human (questions asked, defaults listed), add each answer to the contract, then delete the item
(exit 1)
```

Then Claude sends one message with all of it:

> **Claude:** Before I write any code.
>
> **Question** (my proposal first): 1. `median([])` -> `{error, empty}`, or a default such as `{ok, 0}`?
>
> **I will also assume, unless you object:** `median([5.0])` -> `{ok, 5.0}`; the input order does not matter; a list containing a non-number crashes, with no special error.
>
> Reply `ok` to accept every proposal and approve the contract, or give the numbers you want changed.

Two choices are missing from that list, because Claude did not think of them: what an even-length list gives, and whether the result is always a float. Steps 5 and 6 show how they are caught anyway.

## 2. You answer in one line

> **You:** ok

Claude adds `empty_list_test` (`?assertEqual({error, empty}, median:median([]))`), deletes the items from `OPEN.md`, and the gate opens:

```
$ S/scripts/check_open.sh
no open items
(exit 0)
```

## 3. The contract is frozen

Your `ok` approved the contract with the answers folded in, so Claude records it:

```
$ S/scripts/approved.sh approve test/median_contract_tests.erl
approved test/median_contract_tests.erl
(exit 0)
```

From here the contract cannot change quietly. If Claude tries to edit it to make a failing build pass, the hook stops it:

```
Blocked: test/median_contract_tests.erl is an approved contract file. Do not change it to make the build pass. If you think the contract is wrong, stop and explain to the human with a concrete input; they can unlock it.
(exit 2)
```

## 4. Claude implements and checks

Claude writes `src/median.erl`, runs the contract and the effect scan:

```
OK: Passed 100 test(s).
OK: Passed 100 test(s).
  All 4 tests passed.
$ S/scripts/effects.sh --declared test/median_contract_tests.erl src/median.erl
effects match declarations (heuristic scan)
(exit 0)
```

Everything is green, and the contract is still incomplete. This contract has no reference model (a median is its own simplest description), so the standard tier calls for the disagreement check.

## 5. The disagreement check, round 1: a gap you did not know about

Claude writes a second implementation in `scratch/` that is deliberately different (here: for even lengths, take the lower middle value; integers stay integers). First it confirms the alternative also passes the approved contract (`All 4 tests passed.`). Then it compares the two on random inputs:

```
Failed: After 25 test(s).
[0,0]
Shrinking (0 time(s))
[0,0]
```

> **Claude:** Two implementations that both satisfy your contract disagree on `median([0, 0])`: one returns `{ok, 0.0}`, the other `{ok, 0}`. Should the result always be a float?
>
> **You:** Always a float.

You unlock the contract, add the answer, and approve again. Claude is not allowed to do this itself:

```
$ S/scripts/approved.sh unlock test/median_contract_tests.erl
unlocked test/median_contract_tests.erl
$ S/scripts/approved.sh approve test/median_contract_tests.erl
approved test/median_contract_tests.erl
```

The new contract adds `integers_give_a_float_test` and the property "result is always a float". The first implementation now fails it:

```
median_contract_tests: integers_give_a_float_test...*failed*
**error:{assertEqual,[{module,median_contract_tests},
              {line,18},
              {expression,"median : median ( [ 1 , 2 , 3 ] )"},
              {expected,{ok,2.0}},
              {value,{ok,2}}]}
```

Claude fixes the implementation (`float/1` on the odd-length case), not the contract. All 6 tests pass.

## 6. Round 2: a gap in the algorithm itself

Claude updates its alternative to return floats (so it passes the new contract) and compares again:

```
Failed: After 30 test(s).
[-3,-1]
Shrinking .(1 time(s))
[0,-1]
```

> **Claude:** For `median([0, -1])`, one implementation returns `-0.5` (mean of the two middle values) and the other `-1.0` (the lower of them). Which is right?
>
> **You:** The mean.

Unlock, add `even_length_is_the_mean_test` (`median([1, 2])` is `{ok, 1.5}`), approve. The lower-median alternative now fails the contract, so it is discarded:

```
**error:{assertEqual,[{module,median_contract_tests},
              ...
              {expected,{ok,1.5}},
              {value,{ok,1.0}}]}
```

The real implementation already used the mean, and still passes (All 7 tests).

## 7. Round 3: nothing left to find, and the final report

Claude writes a third alternative with a different formula, confirms it passes the contract, and compares:

```
OK: Passed 1000 test(s).
```

No disagreement over 1000 random inputs, so Claude stops and runs the final checks:

```
$ S/scripts/check_open.sh
no open items
$ S/scripts/approved.sh check
all approved files unchanged
$ S/scripts/effects.sh --declared test/median_contract_tests.erl src/median.erl
effects match declarations (heuristic scan)
```

> **Claude:** Done. The contract has 4 examples and 3 properties, frozen and passing. You answered three questions: empty list is an error (my proposal), results are always floats, even length means the mean of the middle two. Defaults you did not object to: a single element is its own median, order does not matter, non-numbers crash. The disagreement check found nothing more over 1000 random inputs, but that only covers inputs the generator reaches, and two implementations from the same model can share a blind spot. Effects: none.

You read about 40 lines of contract (the rest of the test file is helpers) and answered three questions. The implementation is Claude's to regenerate at any time.

## 8. The mutation check: is the contract tight?

The last check makes one small change at a time to the implementation and reruns the contract. A change the contract does not notice is a missing example.

```
$ S/scripts/mutate.py --test "<compile and run the contract>" src/median.erl
11 of 11 mutants killed, 0 survived (heuristic)
```

It was not always clean. In the Python and Go versions of this example, changing the middle index from `n / 2` to `n / 3` survived: no example had an odd length of five or more, and "order does not matter" and "between min and max" hold for any fixed position. That is why every `median` contract in this repository now has a five-element example and a property that at least half the values are at or below the median and at least half at or above (the finished contract here has 5 examples and 4 properties).

## When the logic must stay pure: the rate limiter

[`examples/rate-limiter-erlang`](examples/rate-limiter-erlang/) shows two more things the skills catch.

**The contract found a real bug in the first implementation.** One example says a limit of 0 must reject everything. The first `rate_limit:check/5` accepted the first call, because a client with no entry yet fell through to the "accept" branch:

```
rate_limit_clock_contract_tests: limit_zero_rejects_everything_test...*failed*
**error:{assertMatch,[{module,rate_limit_clock_contract_tests},
              ...
              {value,{ok,#{a => {-576460751000,1}}}}]}
  Failed: 1.  Skipped: 0.  Passed: 6.
```

Claude fixed the implementation with one guard clause and left the contract alone.

**Time stays out of the logic.** The core takes the time as an argument and declares no effects; a one-line wrapper reads the clock and declares `time`. If an implementation slips a clock read into the core, two things catch it. The examples fail:

```
rate_limit_contract_tests: a_new_window_resets_the_count_test...*failed*
              ...
              {expected,[ok,ok,ok,ok]},
              {value,[ok,ok,ok,rate_limited]}]}
```

and the effect scan names the reason:

```
src/rate_limit.erl: UNDECLARED effect 'time'
  src/rate_limit.erl:9:    NowMs = erlang:system_time(millisecond),
(exit 1)
```

## The same loop in Elixir

The workflow is identical; only the commands and files change.

| Step | Erlang | Elixir |
| --- | --- | --- |
| Contract file | `test/median_contract_tests.erl` (EUnit + PropEr) | `test/gcd_examples_test.exs` (ExUnit) and `test/gcd_properties_test.exs` (StreamData) |
| Run the contract | `rebar3 eunit` | `mix test` |
| Effect scan | `effects.sh --declared <contract> src/x.erl` | `effects.sh --declared <contract> lib/x.ex` |
| Disagreement check | `templates/disagree_tests.erl` | `templates/disagree_test.exs` |

See [`examples/gcd-elixir`](examples/gcd-elixir/). Its `check.sh`, including the StreamData properties, passes (run on a user's machine). The two Elixir templates in `behest-elixir/templates/` also ran on a user's machine and work.

## Other languages

The same loop works in Go, Rust, Python, Java, Julia, TypeScript, Kotlin, C#, Scala, Gleam, Clojure, Haskell and OCaml (see the table in the [skills README](README.md)); the first five are linked here: see [`behest-go`](behest-go/SKILL.md), [`behest-rust`](behest-rust/SKILL.md), [`behest-python`](behest-python/SKILL.md), [`behest-java`](behest-java/SKILL.md) and [`behest-julia`](behest-julia/SKILL.md). [`examples/median-go`](examples/median-go/) is the same `median` task in Go. Building it, the contract caught a real bug in the first implementation: the even-length mean `(a+b)/2` overflowed to Inf for huge floats, so `TestBetweenMinAndMax` failed (random counterexample, values around 1e308). Claude fixed the implementation, not the contract. The same run also exposed a mistake in the contract's own helper (`nil` and an empty slice are not `reflect.DeepEqual`), which was fixed before approval. Go's fuzzer shrinks disagreements automatically, so the human sees a small input such as `[0 -1]`. [`examples/median-rust`](examples/median-rust/) shows the limit of random search: proptest never produced the overflow (not in 100,000 cases), so the human-approved contract gained an explicit boundary example, `median(&[f64::MAX, f64::MAX])`, and that failed the naive code.

[`examples/median-python`](examples/median-python/) repeats the Erlang walkthrough's result-type finding in Python: a naive `median([1, 2, 3])` returns the `int` `2`, which `==` treats as equal to `2.0`, so only a check on `type(x)` notices. The disagreement template compares types as well as values for that reason.

## What this walkthrough does not show

- **A live session with a person.** The scripts, tests and counterexamples are real; the dialogue is written to show what the skill asks for. In the [experiment](../experiment/results/README.md), AI agents given only the skill text did follow it: they drafted a contract, sent one message with questions and defaults, waited, froze the contract and ran the checks. A person answering has not been recorded. How reliably Claude follows the steps depends on the model and the prompt, which is why the hook, `check_open.sh` and a CI `approved.sh check` exist.
- **The light tier.** For a small helper Claude would skip the freeze and the later checks: examples in an ordinary test file, the same one message, then the code.
- **A process.** For a `gen_server` the contract is built around a model and random command sequences; see [`examples/ttl-cache-erlang`](examples/ttl-cache-erlang/).
- **Proof of correctness.** The contract covers the cases and properties someone thought of, plus what the random search reached. It narrows the gap between intent and code; it does not close it.
