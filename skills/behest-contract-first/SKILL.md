---
name: behest-contract-first
description: Contract-first workflow for Elixir, Erlang, Go, Rust, Python or Julia code that a human will review. Use when asked to implement a function or module whose behavior could be read more than one way, or when the user mentions Behest, contract-first, examples-first, or "ask before guessing". Writes examples and properties first, asks about every unclear case, gets approval, then implements.
---

# Behest contract-first workflow

The human states the request. You build a **contract** (examples, properties, effects) with them, one concrete question at a time, and only then write the implementation. The contract is what the human reviews; the implementation is yours and may be regenerated at any time.

Language details are in `behest-elixir`, `behest-erlang`, `behest-go`, `behest-rust`, `behest-python` and `behest-julia`. Use them together with this skill.

## The rule

**If the request does not say what to do in some case, ask. Never guess.** Ask with concrete cases, not abstract questions: "For `median([1, 0])` I could return `0` or `0.5`. Which?" People judge examples much better than they write specs.

## Steps

1. **Restate** the request in one sentence.
2. **Draft the contract** in a test file, before any implementation:
   - 3–6 **examples**, including at least one edge case and one invalid input.
   - **Properties**: what must be true for all inputs (symmetry, bounds, round trips, idempotence, agreement with a simple reference).
   - **Effects**: a comment at the top of the contract file, `behest-effects: none` (or a list such as `time, ets`), saying what the implementation may touch. Allowed names: `send`, `spawn`, `ets` (BEAM only), `io`, `time`, `random`, `state` (global or shared mutable state). It lives in the contract file so it is frozen with the rest of the contract.
3. **Record every unclear point** in `OPEN.md` as `- [ ] question`. Do not resolve any of them yourself.
4. **Stop and ask.** Show the human the draft contract and the open questions as concrete cases. Wait for answers.
5. **Fold each answer in** as an example or property, then delete the item from `OPEN.md`. Run `scripts/check_open.sh`; it must pass.
6. **Get approval.** When the human says the contract is approved, run `scripts/approved.sh approve <contract files>`. From then on those files are frozen.
7. **Implement.** Run the tests. If the implementation fails the contract, fix the implementation. **Never weaken, edit or delete an approved contract file to make the build pass.** If you believe the contract is wrong, stop and tell the human why, with a concrete input.
8. **Check effects.** Run `scripts/effects.sh --declared <contract file> <implementation files>`. Any undeclared effect means either remove it or ask the human to extend the contract.
9. **Disagreement check.** Write a second implementation that passes the same contract but is deliberately different (another algorithm, or the other plausible reading of the request), in a scratch directory that is not committed. Compare the two with a property test over random inputs (templates are in the language skills). Each input where they differ is a missing example: show the human both answers, ask which is right, add the answer to the contract as a new example, and repeat. Stop when no disagreement is found over about 1000 runs, or after two rounds that found nothing new.
10. **Report** briefly: what the contract covers, which answers the human gave, and what remains unchecked.

## Enforcement

- `scripts/approved.sh check` fails if any approved file changed. Run it before finishing and in CI.
- `hooks/block_approved_edits.sh` is a Claude Code `PreToolUse` hook that blocks `Edit` and `Write` on approved files and on the lock file. Setup is in `skills/README.md`.
- Never run `approved.sh approve` or `approved.sh unlock` unless the human explicitly told you to in this conversation.

## Be honest about limits

The disagreement check finds gaps that random inputs reach, and two implementations from the same model can share a blind spot. The effect scan is a grep heuristic. Say so in the report; do not claim the code is proven correct.
