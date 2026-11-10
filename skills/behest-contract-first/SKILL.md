---
name: behest-contract-first
description: "Contract-first workflow for Elixir, Erlang, Go, Rust, Python, Java, Julia, TypeScript, Kotlin, C#, Scala, Gleam, Clojure, Haskell or OCaml code that a human will review. Use when asked to implement a function or module whose behavior could be read more than one way, or when the user mentions Behest, contract-first, examples-first, or \"ask before guessing\". Writes examples and properties first, asks about every unclear case, gets approval, then implements."
---

# Behest contract-first workflow

The human states the request. You build a **contract** (examples, properties, effects) with them, one concrete question at a time, and only then write the implementation. The contract is what the human reviews; the implementation is yours and may be regenerated at any time.

Language details are in `behest-elixir`, `behest-erlang`, `behest-go`, `behest-rust`, `behest-python`, `behest-java`, `behest-julia`, `behest-typescript`, `behest-kotlin`, `behest-csharp`, `behest-scala`, `behest-gleam`, `behest-clojure`, `behest-haskell` and `behest-ocaml`. Use them together with this skill.

## The rule

**If the request does not say what to do in some case, never guess silently.** Every such point gets a proposed answer that the human sees before anything is frozen. Use concrete cases, not abstract questions: "For `median([1, 0])` I could return `0` or `0.5`. I propose `0.5`." People judge examples much better than they write specs.

**The human's attention is the scarce resource.** Sort the open points into two kinds and treat them differently:

- **Question:** an ordinary caller could plausibly send this input, **and** two reasonable people would expect different results. Example: does `"1H30M"` parse, do touching intervals merge. These are asked, each with the options and your proposed answer.
- **Default:** the input is unusual or invalid under any reading (wrong argument type, invalid encoding, absurd sizes, exotic Unicode), or nearly everyone would expect the same result (an empty list gives an empty list). These are **not asked**. You pick the conventional behaviour, list it in one line, and the human can object.

When unsure which kind a point is, make it a question. Aim for at most five questions; if you have more, the least likely to matter become defaults.

## Steps

1. **Restate** the request in one sentence.
2. **Draft the contract** in a test file, before any implementation:
   - 3–6 **examples**, including at least one edge case and one invalid input.
   - **Reference model first.** If a slow, obviously correct version exists (a plain map instead of a cache, a brute-force loop, a quadratic scan), write it in the contract file and make "the implementation agrees with the reference on every input" the main property. It is the strongest check and the one a human can read. Keep it short enough to verify at a glance; if it is not obviously correct, it is not a reference.
   - **Other properties**, when there is no reference or it does not cover everything: symmetry, bounds, round trips, idempotence.
   - **Effects**: a comment at the top of the contract file, `behest-effects: none` (or a list such as `time, ets`), saying what the implementation may touch. Allowed names: `send`, `spawn`, `ets` (BEAM only), `io`, `time`, `random`, `state` (global or shared mutable state). It lives in the contract file so it is frozen with the rest of the contract.
3. **Record every unclear point** in `OPEN.md`, each with your proposed answer, under two headings (see "The rule"):
   - `## Questions`: `- [ ] <case> -> <proposed result>, or <other option>?`
   - `## Defaults`: `- [ ] <case> -> <result>` (not asked; listed so the human can object)

   Put the proposed answers and the defaults into the draft contract as examples already, so the cases the human sees are what the contract really says.
4. **Stop and ask.** Show the human the draft contract and the open questions as concrete cases. **Show every property as cases too:** generate five or so inputs from the property's own generator and print what the property demands for each (for a reference model: input and the reference's answer; for others: the two things that must be equal, or the bound). Run this for real, do not make the cases up; it needs no implementation. People judge cases far better than generator code, and a wrong reference or a generator that only produces trivial inputs shows up here. Then, in the **same message**:
   - the questions, numbered, each with its options and your proposal first;
   - the defaults as a short list under "I will also assume, unless you object";
   - one closing line: "Reply `ok` to accept every proposal and approve the contract, or give the numbers you want changed."

   One reply from the human should be enough. Do not ask for approval in a separate round unless an answer changed something they have not seen. Wait for the reply.
5. **Fold each answer in** as an example or property, then delete the item from `OPEN.md` (questions and defaults alike; an accepted default is deleted too). Run `scripts/check_open.sh`; it must pass. If an answer raises a new point, apply the same sorting: only a new **question** goes back to the human.
6. **Approval.** `ok`, "approved" or "all as proposed" in reply to step 4 approves the contract with the answers folded in; so does a reply that only changes some numbers, unless the change is one you could not fold in without a new question. Then run `scripts/approved.sh approve <contract files>`. From then on those files are frozen. Without such a reply, do not freeze.
7. **Implement.** Run the tests. If the implementation fails the contract, fix the implementation. **Never weaken, edit or delete an approved contract file to make the build pass.** If you believe the contract is wrong, stop and tell the human why, with a concrete input.
8. **Check effects.** Run `scripts/effects.sh --declared <contract file> <implementation files>`. Any undeclared effect means either remove it or ask the human to extend the contract.
9. **Disagreement check.** Write a second implementation that passes the same contract but is deliberately different (another algorithm, or the other plausible reading of the request), in a scratch directory that is not committed. Compare the two with a property test over random inputs (templates are in the language skills). Each input where they differ is a missing example. Sort it as in "The rule": if an ordinary caller could send that input, it is a **question** (show both answers, ask which is right, add the answer to the contract as a new example, and repeat); if the input is exotic, keep the current behaviour and list the case in the final report under "not pinned" without asking. Draw the random inputs mostly from what ordinary callers send, so the disagreements you find are ones worth a question. Stop when no disagreement is found over about 1000 runs, or after two rounds that found nothing new.
10. **Mutation check.** Run `scripts/mutate.py --test "<command that runs the contract>" <implementation files>`. It makes one small change at a time to the implementation and reruns the contract. Each `SURVIVED` line is a change the contract does not notice. For each one decide: does the change alter behaviour for some input? If yes, that input is a missing example: handle it exactly as in step 9 (a question if ordinary, a line in the report if exotic). If no (the change makes no difference), say so in the report. Do not edit an approved contract yourself to kill a mutant.
11. **Report** briefly: what the contract covers, which answers the human gave, which defaults you chose, how many mutants survived and why, and what remains unchecked or not pinned. Do not end with new questions unless one is a real **question** by the rule above.

## Enforcement

- `scripts/approved.sh check` fails if any approved file changed. Run it before finishing and in CI.
- `hooks/block_approved_edits.sh` is a Claude Code `PreToolUse` hook that blocks `Edit` and `Write` on approved files and on the lock file. Setup is in `skills/README.md`.
- Never run `approved.sh approve` or `approved.sh unlock` unless the human explicitly told you to in this conversation.

## Be honest about limits

The disagreement check finds gaps that random inputs reach, and two implementations from the same model can share a blind spot. The effect scan is a grep heuristic. The mutation check only makes simple text changes, and counts mutants that no longer compile as killed. Say so in the report; do not claim the code is proven correct.
