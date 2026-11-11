# A *Claude* review of the ChatGPT response and proposal

Written by Claude on 2026-11-11, at the author's request. It describes and compares two approaches: Behest as built in this repository (with Claude), and the one ChatGPT sets out in its [response](chatgpt-response.md) and [independent proposal](chatgpt-independent-proposal.md). It is one AI's view of another AI's view, and Claude is one of the two being compared, so weigh it accordingly.

## Claude's approach (Behest as built in this repository)

Start from the workflow and the human's attention. Before any code is written, the AI shows every choice the request left open: a few questions and a list of proposed defaults, as concrete cases. The answers become a contract of examples and properties, checked against a simple reference model, and the code must pass it. Effort is matched to risk in three tiers. It runs today as [Claude skills](../skills/) on existing languages, with a small first [experiment](../experiment/results/README.md) on gain and cost.

## ChatGPT's approach (its independent proposal)

Start with a contract layer for existing Elixir/OTP applications, and let that show whether a new language is needed. The unit of review is a stateful service and what its clients can observe. Recovery, retries and timeouts are in the contract from the beginning, for example "repeating a request never charges twice" or "after a restart, completed charges remain discoverable". It builds four things:

- a decision record
- an executable reference model
- a controlled failure harness (crashes, restarts, timeouts, duplicate requests)
- a review report that separates static guarantees, tested properties and assumptions

It also turns the disagreement check around: ask the AI for an implementation that passes every check but violates a plausible intention, and show that to the human. Its example: "This rate limiter passes every example, but forgets usage after restarting. Is that acceptable?"

## How they compare

| | Claude (Behest) | ChatGPT |
| --- | --- | --- |
| Starting point | Any function: surface every decision first | A stateful OTP service: specify failure and recovery first |
| Main mechanism | Questions and defaults, contract, tiers | Decision record, reference model, failure harness |
| State today | Working skills, examples, first experiment | A proposal with one worked example |
| Strongest on | How to surface decisions, and at what cost | Crashes, restarts, retries, timeouts; precise claims |
| Weakest on | Failure behaviour; no human in the tests | No account of cost; nothing built or measured |

## Where they meet

They are close. ChatGPT had read the repository, and its decision record, proposed defaults and reference model match what Behest already does. Both say the same thing about a new language: build the workflow on existing code first, and let that decide.

ChatGPT's response also makes a fair criticism of the main README: the phrase "the compiler guarantees the rest matches" claims more than examples and randomized properties can deliver. They give evidence; only types and effect checks give guarantees, and the line between the two should be stated.

## What ChatGPT adds

Two things, both aimed at Behest's biggest gap:

1. **The failure harness.** Behest's stateful contract tests one healthy process answering calls. Nothing kills it, restarts it, times out a caller or repeats a request. ChatGPT's four questions (a caller times out: can the operation still complete? a process restarts: which state survives? a request is retried: can it apply twice? a mailbox grows faster than it drains: what happens?) are exactly the choices a request leaves open on the BEAM.
2. **The "passes the checks but breaks the intent" search.** Behest's disagreement check asks for a second honest implementation and hopes the two differ somewhere. Asking directly for a version that passes and is plausibly wrong aims at the same thing with a clearer purpose, and each result is a concrete question for the human.

Its report with separated claims (guaranteed, tested, assumed) is also a sharper version of the report headings the skills now use.

## What ChatGPT's proposal lacks

- **Cost.** Nothing about how much ceremony a small task deserves. In the experiment the full workflow cost several times a plain prompt, and the tiers were what made it affordable.
- **Evidence.** Nothing is built or measured yet. Its first milestone (specify the recovery behaviour of an existing OTP service, catch a meaningful bug, reduce review effort) is a good test, and it has not been run.
- **How the decisions reach the human.** It says the AI "proposes defaults and highlights consequential questions". The experiment's finding is about the details of that step: about half of the unusual things the human wanted were caught in the list of defaults, not by the questions, and only if the list is complete and read.

## What I would take from it

1. Add crash, restart, timeout and duplicate-request commands to the stateful contract, with the model saying what survives. Copilot's proposal pointed at the same gap ([review](claude-review-of-copilot.md)).
2. Try the "passes but breaks the intent" search next to the disagreement check on the same tasks, and see which finds more questions worth asking.
3. Soften "the compiler guarantees the rest matches" in the main README and say which checks are guarantees and which are evidence.
