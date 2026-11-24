# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Behest is a **design proposal** for a BEAM language where a human approves a short contract (examples, properties, effects, protocols) and AI writes the implementation. There is no compiler. The repo has four independent parts, each with its own README:

| Part | What it is | Language / tooling |
| --- | --- | --- |
| `docs/`, `examples/*.bh`, `README.md` | The language design and sketches in proposed syntax (`.bh` files are not runnable) | Markdown |
| `prototype/` | The contracts as an Elixir macro library (`use Behest`, `defspec`) that fails *compilation* when an example, property or effect check fails | Mix, no deps |
| `skills/` | The same workflow as Claude Code skills for 15 languages, plus scripts and a hook that enforce it. This is the part people actually install and use | bash, python3, per-language test tools |
| `experiment/` | A kit measuring whether the skills help: underspecified Elixir tasks, answer sheets, hidden checks, recorded results | Elixir scripts |

## Commands

```sh
# Prototype
cd prototype && mix test
cd prototype && mix test test/behest_test.exs:LINE     # one test
BEHEST_SEED=<n> mix compile --force                    # reproduce a failing property (seed is printed)

# Skill examples: each has a check.sh that runs the full check chain the skill asks for
skills/examples/median-erlang/check.sh                 # erlc + EUnit + PropEr, no rebar3
skills/examples/gcd-elixir/check.sh                    # mix test (StreamData from Hex)
skills/examples/median-go/check.sh                     # go vet, go test -race
skills/examples/median-rust/check.sh                   # cargo test (proptest)
skills/examples/median-python/check.sh                 # mypy --strict, pytest, hypothesis
skills/examples/median-java/check.sh                   # needs JUNIT_CONSOLE=<junit-platform-console-standalone.jar>

# Enforcement scripts (run from a project dir; they act on ./OPEN.md and ./.behest-approved)
skills/behest-contract-first/scripts/check_open.sh [OPEN.md]
skills/behest-contract-first/scripts/approved.sh approve|check|list|unlock FILE...
skills/behest-contract-first/scripts/effects.sh --declared CONTRACT IMPL...
skills/behest-contract-first/scripts/mutate.py --test "CMD" [--max N] IMPL...

# Experiment
experiment/new_run.sh TASK plain|behest DIR            # DIR must be outside this repo
elixir experiment/score.exs TASK path/to/solution.ex
```

## How the pieces fit

- **Prototype** (`prototype/lib/behest.ex`): `defspec` expands at compile time, runs `examples`, `property` blocks (100 random cases via `Behest.Gen`, no shrinking) and an effect scan (`Behest.Effects`, syntactic; `defspec` callees bring their declared effects along). Any `open "..."` left in a contract raises `CompileError`. `prototype/examples/` is compiled as part of the lib (see `elixirc_paths` in `mix.exs`); the tests use `Code.compile_string` to show wrong implementations being rejected.
- **Skills**: `behest-contract-first/SKILL.md` holds the language-independent workflow (tiers light/standard/strict, one message with questions + "I will also assume" defaults, freeze, check, report). Each `behest-<lang>/` adds a `SKILL.md` and `templates/` (contract, disagreement, sometimes reference-model and stateful). The scripts are shared across languages:
  - `OPEN.md` with `- [ ]` items = undecided points; `check_open.sh` fails while any remain.
  - `.behest-approved` = content hashes of human-approved contract files; `approved.sh check` fails on any change, and `hooks/block_approved_edits.sh` (PreToolUse hook) blocks Edit/Write on those files.
  - Effects are declared in a comment `behest-effects: ...` in the contract; `effects.sh` greps the implementation per file extension.
  - `mutate.py` is text-based and language-independent; it refuses approved files and always restores originals.
- **Skill examples** (`skills/examples/*`) are finished projects following the workflow, each with its own `OPEN.md`, `.behest-approved` and `check.sh`. Because files there are frozen by hash, editing a contract file means `approved.sh unlock`, edit, `approve` again, run from that example's directory.
- **Experiment**: `tasks/<task>/` has `prompt.md` (what the AI sees), `answers.md` and `checks.exs` (hidden). `reference/` are correct solutions; `naive/` are scorer sanity checks. Runs happen outside the repo so the AI cannot read the answers.

## Keeping things consistent

- The list of 15 supported languages is repeated in many places: `README.md`, `skills/README.md` (skill table, install list, sparse-checkout command, prompt, requirements, Status), the `behest-contract-first/SKILL.md` frontmatter description and body, and the extension list in `effects.sh` (also quoted in `skills/README.md`). Adding or renaming a language means updating all of them.
- `skills/STATUS.md` is the log of what was actually run; entries are appended at the end and must say what was and was not tested. Do not claim a template was run unless it was. `skills/README.md` "Status" summarises it.
- `skills/SUGGESTIONS.md` and `docs/suggestions.md` list ideas not yet done; when one is implemented, update the list.
- Experiment numbers quoted in `README.md`, `skills/README.md` and `experiment/README.md` come from `experiment/results/README.md`; keep them in sync.
- Docs are written in plain, short sentences and are careful to state limits ("a first look, not proof", "a grep, not a proof"). Keep that tone.
