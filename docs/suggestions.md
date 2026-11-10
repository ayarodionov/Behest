# Suggestions for the general idea

Ideas for where Behest could go next, collected on 2026-11-10 after the [experiments](../experiment/results/README.md). None of them is built. Each says what it is, why the evidence points that way, and roughly how much work it would be.

They start from the main thing the experiments showed: **the gain comes from showing the human every choice the request left open, with a proposal, before the code is written.** Freezing and the later checks add assurance, but the list of choices is what changed the scores.

Suggested order: 1, then 3, then 2. The reasons are at the end.

## A. Make the list of choices stronger

### 1. Show defaults as results on the human's own data

- **What:** before implementing, run the reference model on twenty or so real inputs from the project (real titles, real durations, real intervals) and show a table of input and result next to the list of defaults.
- **Why:** every result now depends on the human reading a list of 10 to 15 assumptions. In the runs, 18 of 33 unusual decisions were caught only there, and the "human" was an AI that reads everything. A person skims a list of rules, but spots a wrong slug among their own titles quickly.
- **Work:** small. The reference model already exists before any implementation; this needs a step that finds sample inputs and a line in the skill.

### 2. Keep the decisions as a lasting record

- **What:** a file per project (for example `DECISIONS.md`) holding what this human chose: "underscores are kept", "nothing usable gives `untitled`", "reversed input is swapped, not rejected". The next task starts from it, so known preferences become defaults that are already right.
- **Why:** the cost of Behest is the human's attention. A record makes the number of questions fall over time instead of starting from zero on every task. It also survives regenerating the code.
- **Work:** small to medium. The risk is a stale or over-general record, so each entry needs the task it came from.

### 3. Choose the questions by where two models disagree

- **What:** ask a second model (or the same model with a different prompt) for its own list of defaults. Points where the two lists differ become the questions; points where they agree stay defaults.
- **Why:** the current rule for what to ask ("an ordinary caller could hit it, and reasonable people would differ") did not predict what the human cared about: more than half of the unusual decisions landed in the defaults list. Disagreement between independent authors is a measurable stand-in for "reasonable people would differ".
- **Work:** medium. One extra model call per task; needs a run to see whether it moves the right points into the questions.

### 4. Order the defaults by how likely the human is to object

- **What:** put first the defaults that change results for common inputs, or that this human has overruled before; put last the ones about invalid input.
- **Why:** if the human reads only the top of the list, the top should be where the surprises are.
- **Work:** small once 2 exists.

## B. Test the claims that are still untested

### 5. Regenerate from the contract alone

- **What:** give a fresh agent only the frozen contract, with no conversation and no first implementation, and have it write the code. Every difference between its version and the original is a hole in the contract.
- **Why:** the central claim of the design is that the contract is the asset and the implementation can be thrown away. Nothing has tested it. This is also the disagreement check done properly, with a truly independent author, and it measures the contract better than text mutations do.
- **Work:** small. The contracts from the experiment runs can be reused.

### 6. Put a person in the experiment

- **What:** a person (not an AI) answers the questions and reads the defaults, with a stopwatch, ideally without knowing which arm is which.
- **Why:** this is the largest gap in the evidence. Human minutes have never been measured, and neither has how carefully a real reader checks the list.
- **Work:** about an hour of a person's time for a first look.

### 7. Measure whether the defaults list is read

- **What:** in experiments only, and with the participant told beforehand that it may happen, include one default that is deliberately wrong and see whether it is caught.
- **Why:** it turns "did the human read the list?" from a guess into a number. It must never be done outside an experiment: a tool that plants errors in real work would be deceiving its user.
- **Work:** small, as part of 6.

### 8. Test the tier choice on risky tasks

- **What:** tasks where the right tier is standard or strict: a money calculation, a function that deletes files, a process protocol.
- **Why:** all three agents picked the light tier, correctly, on small pure functions. Whether an agent moves up when it should is unknown.
- **Work:** small to medium (new tasks and hidden checks).

## C. Where the idea fits best

### 9. Lead with existing code

- **What:** present Behest first as a way to recover and audit the contract of code that already exists, asking the human only where the current behaviour is surprising.
- **Why:** the strongest results in the whole project are still the real bugs found in two existing Elixir libraries. For new small functions a plain prompt was close behind.
- **Work:** medium: its own workflow (record current behaviour first, then decide bug or rule case by case) and one worked example.

### 10. Use the same list to review a change

- **What:** given a pull request, written by a person or an AI, derive the choices the code makes and present them as "this change assumes...", with the same questions-and-defaults layout.
- **Why:** the experiments showed a plain run delivers conventional choices without saying so, and a reviewer cannot object to a choice nobody showed them. That is true of any code, however it was written.
- **Work:** medium. No contract or freeze is needed, which makes it the cheapest way to try the core idea on real work.

### 11. Let the tier adjust itself

- **What:** count how many proposals the human changes per task. A kind of task that keeps getting `ok` with no changes drops to a plain prompt; one with frequent changes moves up.
- **Why:** the experiment's two task sets behaved completely differently, and nobody can say in advance which kind a project has. The project's own history can.
- **Work:** small once 2 exists.

## D. The language

### 12. Narrow the language to what tools cannot do

- **What:** drop the plan for a whole new language. Keep the two checks that need a compiler: effects and message protocols between processes. Build them as a compiler pass or library for Elixir.
- **Why:** examples, properties, approval and tiers all work as skills on 15 existing languages. The weakest tool in the set is the effect scan, a text search that cannot see into called modules; protocols are not checked at all. Those are exactly the parts the original design wanted from a compiler.
- **Work:** large, but far smaller than a language, and it can be adopted one module at a time.

### 13. Contracts between modules and processes

- **What:** extend the contract from one function or one process to the conversation between two: which messages, in what order, with what replies and timeouts.
- **Why:** everything tested so far is one function or one process answering calls. The original BEAM-specific claim was about processes talking to each other, and it is untested.
- **Work:** medium for a first example with two processes and a model of both; large for anything general.

## E. Smaller additions

### 14. Limits on speed and memory in the contract

- **What:** properties such as "sorting 100,000 elements takes under a second" or "memory stays linear".
- **Why:** a contract of examples and properties accepts an implementation that is correct and far too slow.
- **Work:** small; the difficulty is making such tests stable.

### 15. Treat "not pinned" as a list to work through

- **What:** the final report already lists behaviour the contract does not pin. Keep that list in the project and let the human promote items into the contract when they start to matter.
- **Why:** it is the honest record of what was left to chance, and it is currently lost after the report is read.
- **Work:** small.

## Why this order

- **1 first:** it strengthens the one step every result depends on, and it is cheap.
- **3 next:** it replaces a rule that the experiment showed to be a poor predictor with something measurable.
- **2 after that:** it is what makes the cost fall over time, and 4 and 11 depend on it.
- **5 and 6 alongside:** they are tests, not features. 5 can be run now with what already exists; 6 needs a person.

## What is not suggested

- **More languages.** Fifteen is already more than is tested; four of them have never been run.
- **A heavier default.** The standard tier cost about 2.7 times a plain prompt and changed no score that the light tier did not also reach on these tasks.
- **Proof.** Nothing here makes the code proven correct, and the documents should keep saying so.
