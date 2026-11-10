# Suggestions for the skills

Concrete improvements to the skills, scripts and templates in this folder, collected on 2026-11-10. Items marked (done) are finished; the rest are not. Ideas about the approach itself are in [docs/suggestions.md](../docs/suggestions.md); what has been tested so far is in [STATUS.md](STATUS.md).

Most items come from watching 36 agent runs follow the skills in the [experiment](../experiment/results/README.md), and from building the examples.

**Done since this list was written:** 1, 2, 3 and 4 (see the last entries of [STATUS.md](STATUS.md)). Next in line: 5 and 6.

## A. Fixes the agent runs pointed to

### 1. A scratch directory that can be cleaned up (done)

- **Seen:** four agents could not delete their throwaway disagreement tests; a safety check blocked the `rm`. The files stayed in the project.
- **Do:** have the skill name one scratch directory (git-ignored, outside `test/` so a plain test run does not pick it up) and say to remove it by its full path, or to leave it and report it.
- **Work:** small.

### 2. Doc examples are either run or not written (done)

- **Seen:** several agents put `iex>` examples in `@doc` that no test ran, and said so in their reports.
- **Do:** one line in the language skills: wire doc examples into the test run (`doctest` in Elixir, `doctest` in Python, and so on) or leave them out.
- **Work:** small.

### 3. A fixed shape for the final report (done)

- **Seen:** the reports were good but each laid out differently, which makes them slow to compare.
- **Do:** give the report five fixed headings: your answers, defaults you did not object to, consequences pinned without asking, checks run, not pinned.
- **Work:** small.

### 4. Standard-library versions of the Elixir templates (done)

- **Seen:** StreamData could not be installed in the runs, so every agent wrote its own seeded generator, each a little different, none with shrinking.
- **Do:** add standard-library variants of the contract and disagreement templates, as already exists for the stateful one, with a small shrinker.
- **Work:** small to medium.

### 5. Guidance for a second round of questions

- **Seen:** when the human's answers were unusual, both `duration2` runs came back with a second round. That was reasonable, but the skill says nothing about it.
- **Do:** say that a second message lists only the new points, again as questions and defaults, and that a third round means the task should be split or moved up a tier.
- **Work:** small.

### 6. Keep the accepted defaults

- **Seen:** `OPEN.md` is emptied when answers are folded in, so the record of what was assumed lives only in the test file and the chat.
- **Do:** move accepted items to a decisions file instead of deleting them (this is the skill-side half of idea 2 in the general suggestions).
- **Work:** small.

## B. Gaps in what the skills cover

### 7. A workflow for existing code

- **Why:** the real bugs found so far were in existing libraries, but the skills give that case one paragraph.
- **Do:** a section (or its own skill) with the steps: record what the code does now as a draft contract; list every behaviour that looks surprising as a question ("bug, or a rule to keep?"); only then change code.
- **Work:** medium, with one worked example.

### 8. Reference-model and stateful templates beyond Erlang and Elixir

- **Why:** the other 13 languages still have only the `median` contract and a disagreement test.
- **Do:** add a reference-model template and a "print the cases" helper to the languages that were run (Go, Rust, Python, Java, TypeScript, Clojure, Haskell, OCaml); add a stateful template where the language has a natural one (Hypothesis has rule-based state machines, proptest and fast-check have model-based testing).
- **Work:** medium to large; do Python and TypeScript first.

### 9. A light-tier example

- **Why:** every example project is in the standard tier. The light tier is the one that matched a plain prompt on cost, and there is nothing to copy for it.
- **Do:** one small example with an ordinary test file, the one message, and the report.
- **Work:** small.

### 10. An end-to-end run of the strict tier

- **Why:** the strict tier has never been used. Its extras (independent review of the contract, frozen test configuration, CI check) are untested instructions.
- **Do:** run it once on a risky task and fix what does not work.
- **Work:** medium.

## C. The tools

### 11. Continuous integration

- **Why:** every "passes" in the status log comes from a manual run. Nothing stops a later edit from breaking an example.
- **Do:** a GitHub Actions workflow that runs each example's `check.sh`, plus a small workflow file users can copy that runs `approved.sh check`. The second one is what the strict tier asks for.
- **Work:** small to medium (Elixir needs Hex, which works on GitHub's runners).

### 12. A real effect check for Erlang and Elixir

- **Why:** `effects.sh` is a text search. It gave one false alarm in the runs and cannot see effects inside called modules.
- **Do:** use the compilers' own information: `xref` for Erlang, a compile tracer for Elixir, following calls into the project's own modules. Keep the text search for the other languages, and add a per-project allow list for its false alarms.
- **Work:** medium.

### 13. Mutation check: separate "did not compile" from "test failed"

- **Why:** a mutant that breaks the build counts as killed, which flatters the contract. The tool cannot tell the two apart.
- **Do:** accept an optional `--build` command; a mutant that fails it is reported as invalid, not killed.
- **Work:** small.

### 14. Mutation check: speed and memory of earlier verdicts

- **Why:** one contract run per mutant is slow (the `gen_server` example took minutes), and a mutant judged "makes no difference" is reported again on every run.
- **Do:** run mutants in parallel on copies of the project; keep a small file of survivors a human has marked as equivalent; add an option to mutate only lines changed since a given commit.
- **Work:** medium.

### 15. An amendment flow for frozen contracts

- **Why:** changing a contract is `unlock`, edit, `approve`. Nothing shows the human what changed or records why.
- **Do:** `approved.sh amend FILE` that prints the diff against the approved version and appends the date and a one-line reason to a history file.
- **Work:** small to medium (needs the approved text kept, not only its hash).

### 16. Close the easy way around the hook

- **Why:** the hook blocks the edit tools, but a shell command such as `sed -i` on a frozen file goes through. Only CI catches it.
- **Do:** a second hook on shell commands that refuses ones naming an approved file together with a write (`sed -i`, `>`, `tee`, `mv`). It will be a heuristic; say so.
- **Work:** small.

### 17. Check the format of the open items

- **Why:** `check_open.sh` only checks that no items remain. It does not check that each item had a proposal, which is the point of the new format.
- **Do:** a `--lint` mode: every item under "Questions" has options, every item under "Defaults" has a result.
- **Work:** small.

## D. Keeping the set maintainable

### 18. Fewer copies of the same thing

- **Why:** one change to the `median` contract meant editing 20 files across templates and examples. The 16 skills will drift.
- **Do:** either generate the per-language `median` templates from one description, or move the language details into reference files under a single skill, loaded only when that language is in use.
- **Work:** medium.

### 19. Run the four skills that were never run

- **Why:** the Kotlin, C#, Scala and Gleam templates were written from documentation.
- **Do:** run each once (GitHub's runners have Maven Central, NuGet and Hex) and fix the differences. If nobody will, mark them experimental or remove them.
- **Work:** small each, once item 11 exists.

### 20. Tests for the skills themselves

- **Why:** whether an agent follows the steps was checked by hand in the experiment. A wording change to the skill could break it without anyone noticing.
- **Do:** a small suite of scripted checks on a transcript: the tier is stated, there is exactly one message before any implementation file exists, no approved file changes after approval, the report has its headings.
- **Work:** medium.

### 21. Versions

- **Why:** the workflow changed three times in one day (questions and defaults, tiers, stateful contracts). A project that installed the skills last week has no way to tell which workflow it has.
- **Do:** a version line in each `SKILL.md` and a short changelog.
- **Work:** small.

## What is not suggested

- **More languages** before the existing ones are run and deduplicated.
- **More steps in the default tier.** The runs argue for fewer steps on small tasks, not more.
