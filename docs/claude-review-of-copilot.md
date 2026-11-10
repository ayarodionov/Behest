# A *Claude* review of the Copilot response and proposal

Written by Claude on 2026-11-10, at the author's request. It reviews two documents in this folder that GitHub Copilot wrote: its [response](copilot-response.md) to Behest, and its [independent proposal](copilot-independent-proposal.md) with a seven-step build plan. It is one AI's opinion of another AI's opinion, so weigh it accordingly. Where it cites results, they are from the [experiment](../experiment/results/README.md) in this repository, which was small and had an AI playing the human.

## In short

Both documents are sound and cautious, and they agree with most of what the experiments here showed. They are also fairly generic. They raise two challenges worth acting on, and they have four weak spots.

## Where I agree

- **Workflow before syntax.** The plan says to prototype the workflow on existing Erlang and Elixir code before inventing a language. That is what the [skills](../skills/) and the experiment did. Steps 1 and 2 of the plan are largely done, with one gap noted below.
- **Bounded trust.** Copilot says examples and two AI implementations do not prove correctness and can share blind spots. This repository's documents say the same.
- **Measure the human side.** It names the gap that matters most: real developers, review effort and missed defects. Every run so far had an AI answering the questions.
- **A narrow first slice of the language.** Step 3 of the plan is one process boundary: messages and replies, owned state, failure behaviour, allowed effects and timing. That is a good, concrete scope, and it fits the [suggestion](suggestions.md) to narrow the language to what tools cannot check (effects and message protocols).

## Two challenges worth acting on

### 1. The baseline was too weak

Copilot says to compare with a well-tested Erlang or Elixir workflow, not only with unstructured prompting. That is a fair criticism of the experiment here: its baseline was a plain prompt.

The experiment's main finding was that the gain comes from showing every choice before the code is written. A plain prompt with one added sentence ("list your assumptions before coding, and write tests first") might capture most of that gain without any skill. The light tier is close to exactly that. Until that arm is run, the results say Behest beats a bare prompt, not that it beats a careful one.

- **Do:** add a third arm to the experiment: the plain prompt plus that one sentence.
- **Work:** small. The tasks and the scorer exist.

### 2. Failure and lifecycle are missing from the contracts

Copilot puts restarts, crash behaviour, supervisor policy and what happens to state on a restart in the foreground. Behest's contracts cover none of it. The stateful example in this repository tests one healthy process answering calls; nothing kills it, restarts it, or checks what a caller sees meanwhile.

On the BEAM these are not details. Whether state survives a restart is exactly the kind of choice a request leaves open and a model fills in silently.

- **Do:** extend the stateful contract with a `crash` command: the model says what state survives, and the property checks the replies after the restart.
- **Work:** medium.

## Where it is weak

- **No mechanism for surfacing decisions.** The proposal says the tool "should surface the decision instead of silently turning a guess into code", but not how. The experiment's most useful result is about the how: a list of proposed defaults caught about half of the unusual things the human wanted, the questions caught the rest, and the list only works if it is complete and read. Nothing in the plan addresses that.
- **No account of cost.** The full workflow cost several times a plain prompt in agent time. Matching the ceremony to the risk (the three tiers) is what made it affordable. The plan treats the workflow as one thing.
- **The decision point comes late.** The plan builds a parser and a checker (steps 3 to 5) before evaluating with developers (step 6). I would decide before building any compiler, on evidence from the workflow alone, and build the language slice only if that evidence shows something the workflow cannot do.
- **The two documents disagree about Gleam.** The response says to prototype on Gleam first. The proposal says to prototype around existing OTP code first. I would follow the proposal: a Gleam prototype tests syntax, and the experiments suggest the workflow needs no new language. Gleam's typed message passing is still worth studying for the protocol slice.

One more observation, not a weakness: the proposal was written as an independent view, so it does not engage with what already exists here. Several things it recommends are in place, such as unresolved questions failing the build.

## The plan, step by step

| Copilot's step | State in this repository |
| --- | --- |
| 1. Baseline and success criteria | Partly. Tasks, hidden checks and measures exist. Missing: the stronger baseline, and developers instead of an AI. |
| 2. Prototype the workflow before syntax | Done, as skills for existing languages, and run by agents on those tasks. |
| 3. Specify the smallest useful language slice | Not started. Copilot's scope (one process boundary) is a good definition to adopt. |
| 4. One end-to-end vertical slice | Not started. An Elixir macro [prototype](../prototype/) covers examples and properties only. |
| 5. Validate runtime behaviour and interop | Not started for a language. The skills already run examples with a controllable clock on real OTP code. |
| 6. Evaluate with developers, decide whether to expand | Not started. I would move this decision before step 3. |
| 7. Harden the validated parts | Not applicable yet. |

## What I would take from it

1. Add the stronger baseline arm to the experiment.
2. Add a crash-and-restart command to the stateful contract.
3. Use Copilot's step 3 as the scope if the language work goes ahead.

And what I would keep from this repository that the plan lacks: the questions-and-defaults message, the tiers, and the rule that every example is checked against the reference before the contract is frozen.
