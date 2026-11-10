# Does Behest help? A small experiment

Behest claims that an AI which builds a contract first and asks about unclear cases gets more of the human's intent right than one that just writes the code. This directory is a kit for testing that claim. **No AI runs have been recorded yet**: the kit is built and its scorer is checked, the experiment itself is still to be run.

## The idea

Each task is a short, deliberately underspecified request for one Elixir function. Behind it is a list of **decisions**: points the request leaves open, each with the answer the human has in mind. An AI that guesses will get some of them wrong; an AI that asks can get all of them right. Hidden checks, grouped by decision, measure which happened.

| Task | Function | Decisions |
| --- | --- | --- |
| [`slug`](tasks/slug/) | `Slug.slugify/1` | 8 |
| [`intervals`](tasks/intervals/) | `Intervals.merge/1` | 6 |
| [`duration`](tasks/duration/) | `Duration.parse/1` | 9 |

Each task has `prompt.md` (what the AI gets), `answers.md` (what the human says, and only if asked) and `checks.exs` (the hidden checks). `reference/` holds a solution that gets everything right.

## The two arms

- **plain:** the AI gets `prompt.md` and nothing else.
- **behest:** the AI gets `prompt.md` with the `behest-contract-first` and `behest-elixir` skills installed.

## How to run one

1. `experiment/new_run.sh TASK ARM DIR` creates an empty directory **outside this repository** with the prompt (and, for `behest`, the skills). The AI must not be able to read `checks.exs`, `answers.md` or `reference/`.
2. Start a fresh AI session in that directory. Paste `prompt.md` as the request. Start a stopwatch.
3. If the AI asks a question, answer it from `answers.md`, in those words. If the point is not listed, say "your choice". **Never volunteer an answer that was not asked for**, in either arm. If the AI asks for approval of a contract, read it, correct anything that contradicts `answers.md` only if you actually notice it, and approve.
4. Stop the stopwatch when the AI says it is done. Note the minutes you spent reading and answering, and the number of questions asked.
5. Score: `elixir experiment/score.exs TASK DIR/lib/<file>.ex`. Add a row to [`results/README.md`](results/README.md).

Use the same model for both arms, a fresh session for every run, and at least three runs per task and arm (18 runs): one run says little, because the same prompt gives different code each time.

## What is measured

- **Decisions right:** how many of the task's decisions the solution matches (a decision counts only if all its checks pass). The main number.
- **Core:** checks that the request does not leave open. Both arms should pass these; if one does not, the code is simply wrong.
- **Questions asked** and **human minutes:** the price paid. Behest is only worth it if the extra decisions are worth the extra minutes.

## What a result would mean

- behest gets clearly more decisions right for a few extra minutes: the approach does what it claims on this kind of task.
- No difference in decisions: the AI asks (or guesses well) without the skills, and the ceremony is not earning its keep here.
- behest asks many questions that are not in `answers.md`: it over-asks, which is the cost the tiers idea should fix.

## Limits (read before quoting a number)

- **The tasks favour the approach.** They are small pure functions chosen because they are ambiguous. Real work has more unambiguous code, where asking gains nothing.
- **"Right" is defined by the answers file.** Several of the decisions are matters of taste; the experiment measures whether the AI finds out what this human wants, not whether the code is good.
- **Human time is understated.** Reading an answer off a sheet is faster than deciding it. A real human would think.
- **The kit was written by Behest's author with an AI's help,** and the person running it knows which arm is which. Someone independent running it would be worth more.
- **Small numbers.** Three tasks and a handful of runs can show a large effect, not a small one.
- **One language, one model.** Results for Elixir with one model do not carry over automatically.

## Scorer check

The scorer was run on the reference solutions (everything passes) and on three hand-written first guesses in `naive/` (they pass the core checks and miss 2 to 6 decisions each), on a file that does not compile and on one that loops forever. Those rows are in the results table, marked as not being AI runs.
