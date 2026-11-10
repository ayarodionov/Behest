# Results

## Pilot, 2026-11-10: 18 runs

Three runs per task and arm. Each run was a fresh AI subagent of one Claude Code session (configured model `claude-fable-5-2`), given the same instructions in both arms apart from one sentence telling the `behest` arm to read and follow the two skills. Another AI (the session that launched them) played the human and answered from `answers.md`. No person timed anything, so there are **no human minutes**; agent seconds and tokens are the harness's own figures and stand in for cost.

| Task | Arm | Run | Core | Decisions right | Wrong | Questions asked | Human replies | Agent seconds | Tokens (thousands) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| slug | plain | 1 | 4/4 | 8/8 | | 0 | 0 | 34 | 81 |
| slug | plain | 2 | 4/4 | 8/8 | | 0 | 0 | 33 | 81 |
| slug | plain | 3 | 4/4 | 7/8 | nonlatin | 0 | 0 | 31 | 81 |
| slug | behest | 1 | 4/4 | 8/8 | | 10 | 2 | 193 | 107 |
| slug | behest | 2 | 4/4 | 8/8 | | 13 | 2 | 260 | 120 |
| slug | behest | 3 | 4/4 | 8/8 | | 8 | 2 | 218 | 117 |
| intervals | plain | 1 | 6/6 | 6/6 | | 0 | 0 | 33 | 82 |
| intervals | plain | 2 | 6/6 | 6/6 | | 1 (with its final message) | 0 | 24 | 80 |
| intervals | plain | 3 | 6/6 | 6/6 | | 0 | 0 | 32 | 82 |
| intervals | behest | 1 | 6/6 | 6/6 | | 6 | 2 | 191 | 113 |
| intervals | behest | 2 | 6/6 | 6/6 | | 7 | 1 | 178 | 110 |
| intervals | behest | 3 | 6/6 | 6/6 | | 6 | 1 | 205 | 113 |
| duration | plain | 1 | 7/7 | 9/9 | | 7 | 1 | 72 | 85 |
| duration | plain | 2 | 7/7 | 7/9 | case, spaces | 0 | 0 | 40 | 82 |
| duration | plain | 3 | 7/7 | 6/9 | case, spaces, units | 3 (with its final message) | 0 | 41 | 82 |
| duration | behest | 1 | 7/7 | 9/9 | | 15 | 2 | 173 | 104 |
| duration | behest | 2 | 7/7 | 9/9 | | 14 | 1 | 186 | 114 |
| duration | behest | 3 | 7/7 | 9/9 | | 12 | 1 | 216 | 117 |

### Totals

| | plain | behest |
| --- | --- | --- |
| Decisions right | 63 of 69 | 69 of 69 |
| Runs with every decision right | 6 of 9 | 9 of 9 |
| Core checks passed | all | all |
| Questions asked | 11 | 91 |
| Human replies needed | 1 | 14 |
| Agent seconds, mean per run | 38 | 202 |
| Tokens, mean per run | about 82 thousand | about 113 thousand |

Two plain runs said they were done and attached questions to that same message. They are scored above as they stood at that point. When those questions were then answered, `duration` plain 3 went from 6/9 to 9/9 and `intervals` plain 2 did not change, which would make the plain total 66 of 69.

### What this shows, and what it does not

- **The effect is in the expected direction and small.** `behest` got every decision right in every run; `plain` got 91% right and missed decisions in 3 of 9 runs. All the misses were matters of taste the request did not settle (keep or drop non-Latin letters, allow spaces and upper case, allow a days unit).
- **The price was large.** About five times the agent time, eight times the questions and 14 human replies against 1. Roughly a third of the `behest` questions were about points the human had no opinion on ("your choice"): input that is not a string, length limits, leading zeros, Unicode corner cases. That is the over-asking the tiers idea is meant to cut.
- **The plain arm is better than the kit assumed.** Unprompted, it mostly chose what the answer sheet says, and it listed its choices at the end of every run. One plain run stopped and asked on its own. The hand-written "first guesses" in `naive/` (3 to 4 decisions right) were far too pessimistic about what a current model does without help.
- **The tasks are too easy to separate the arms well.** The sheet's answers are mostly the conventional ones, so guessing works. `intervals` did not separate the arms at all (6/6 everywhere). A sharper kit needs decisions where the human wants something unconventional.
- **Not measured:** human minutes; whether the frozen contracts, mutation checks and disagreement checks the `behest` runs also produced are worth anything later (the plain runs left no contract, and five of them left no tests at all).

### Limits of this pilot

- One model, one language, nine runs per arm. The difference (6 decisions out of 69) is too small to call significant.
- The "human" was an AI that knew which arm each run was in and wrote the kit. It answered only what was asked, in the sheet's words, but it was not blind.
- In `behest` runs 2 and 3 the approval was given together with the answers ("approved once these are folded in"), so nobody read the final contract before it was frozen. In run 1 approval was a separate reply.
- Isolation was by instruction, not enforced: the answers, checks and reference solutions were moved out of the repository during the runs but stayed on the same machine. One agent created a stray file outside its directory by mistake. Nothing suggests an agent read the hidden files, and the plain arm's misses argue against it, but it was not prevented.
- The agents could see the user's saved notes; one mentioned knowing that Behest is the user's own project.
- StreamData could not be installed, so the `behest` runs wrote their own seeded generators (no shrinking). Both arms were told this up front.
- Agent seconds include the agent's own waiting on tools, not the time the "human" took to reply.

### Side findings about the tools (fixed after the pilot)

- `mutate.py` also changed words and numbers inside `@doc` text, so most "survivors" in the runs were documentation (for example 12 of 12 in one run). It now skips triple-quoted blocks; rerun on that run's solution, 4 of 4 mutants are killed.
- `effects.sh` reported the pure `IO.iodata_to_binary` as `io`. It now ignores that and two similar conversions.
- Four agents could not delete their scratch disagreement tests (a safety check blocked the command), and several noted that the doc examples they wrote were not run as doctests.

## Rerun after cutting questions, 2026-11-10: 3 runs

After the pilot the workflow was changed: every open point gets a proposed answer, only points an ordinary caller could hit and reasonable people would answer differently are asked (five at most), the rest are listed as defaults, and questions, defaults and the approval request go in one message. One `behest` run per task was repeated with the new skill text, same instructions and same answer sheets.

| Task | Core | Decisions right | Questions asked | Defaults listed | Human replies | Agent seconds | Tokens (thousands) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| slug | 4/4 | 8/8 | 5 | 9 | 1 ("ok") | 154 | 105 |
| intervals | 6/6 | 6/6 | 4 | 6 | 1 ("ok") | 103 | 107 |
| duration | 7/7 | 9/9 | 5 | 9 | 1 ("ok, except 3") | 149 | 113 |

| | plain (pilot, 9 runs) | behest before (pilot, 9 runs) | behest after (3 runs) |
| --- | --- | --- | --- |
| Decisions right | 63 of 69 | 69 of 69 | 23 of 23 |
| Questions per run, mean | 1.2 | 10.1 | 4.7 |
| Human replies per run, mean | 0.1 | 1.6 | 1.0 |
| Agent seconds per run, mean | 38 | 202 | 135 |

- **Questions fell by about half and no decision was lost.** In two runs every proposal matched the answer sheet and the human's whole reply was "ok". In the third the AI proposed rejecting upper case and spaces; the human changed that one number. That is the case the questions exist for.
- **Decisions that moved into the defaults list were all conventional ones** (an empty list gives an empty list, digits are kept, runs of punctuation collapse) and all matched the sheet. None of the runs asked a follow-up question after implementing; exotic inputs were listed under "not pinned" in the final report.
- **The cost is still well above plain:** about three and a half times the agent time, where it was five times.
- **Limits:** three runs, the same tasks and the same non-blind AI "human" as the pilot; a default that happened to be wrong would only be caught if the human reads the list, which here was an AI comparing it with the sheet. With these tasks the proposals were right nearly every time, so the rerun shows the questions can be cut safely here, not that the sorting rule is right in general.

## Scorer checks (not AI runs)

| Task | Solution | Core | Decisions right | Wrong decisions |
| --- | --- | --- | --- | --- |
| slug | reference | 4/4 | 8/8 | |
| slug | hand-written first guess | 4/4 | 3/8 | accents, collapse, edges, nonlatin, underscore |
| intervals | reference | 6/6 | 6/6 | |
| intervals | hand-written first guess | 6/6 | 4/6 | adjacent, reversed |
| duration | reference | 7/7 | 9/9 | |
| duration | hand-written first guess | 6/7 | 3/9 | bare, case, order, repeat, sign, units |

## Adding a run

Copy the `RESULT` line from `score.exs` into a new row and add what you measured by hand, including human minutes.
