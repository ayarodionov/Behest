# Behest as Claude skills

The same idea as the [Behest language](../README.md), delivered as Claude skills that work on ordinary Elixir, Erlang, Go, Rust, Python, Java, Julia, TypeScript, Kotlin, C#, Scala, Gleam, Clojure, Haskell and OCaml projects today. No new language and no compiler: before writing code, Claude shows the human every choice the request left open, each with a proposed answer, as concrete cases. The agreed answers become a contract of examples and properties that the implementation must pass.

| Skill | Purpose |
| --- | --- |
| [`behest-contract-first`](behest-contract-first/SKILL.md) | The workflow, plus scripts and a hook that enforce it |
| [`behest-elixir`](behest-elixir/SKILL.md) | ExUnit and StreamData contract, reference-model, disagreement and stateful (GenServer) templates |
| [`behest-erlang`](behest-erlang/SKILL.md) | EUnit and PropEr contract, reference-model, disagreement and stateful (`proper_statem`) templates |
| [`behest-go`](behest-go/SKILL.md) | `testing` and `testing/quick` contract, fuzz-based disagreement check; standard library only |
| [`behest-rust`](behest-rust/SKILL.md) | cargo tests and proptest contract, proptest-based disagreement check |
| [`behest-python`](behest-python/SKILL.md) | pytest and Hypothesis contract, Hypothesis-based disagreement check, mypy |
| [`behest-java`](behest-java/SKILL.md) | JUnit 5 contract with seeded random properties, disagreement template with a small shrinker; jqwik optional |
| [`behest-julia`](behest-julia/SKILL.md) | `Test`-based contract and disagreement templates (run once on a user's machine) |
| [`behest-typescript`](behest-typescript/SKILL.md) | Vitest and fast-check contract (TypeScript or JavaScript), fast-check disagreement check, `tsc --strict` |
| [`behest-kotlin`](behest-kotlin/SKILL.md) | Kotest property contract and disagreement check (templates not run) |
| [`behest-csharp`](behest-csharp/SKILL.md) | xUnit and FsCheck contract and disagreement check (templates not run) |
| [`behest-scala`](behest-scala/SKILL.md) | ScalaCheck contract and disagreement check (templates not run) |
| [`behest-gleam`](behest-gleam/SKILL.md) | gleeunit and qcheck contract and disagreement check (templates not run) |
| [`behest-clojure`](behest-clojure/SKILL.md) | `clojure.test` and test.check contract and disagreement check |
| [`behest-haskell`](behest-haskell/SKILL.md) | QuickCheck contract and disagreement check |
| [`behest-ocaml`](behest-ocaml/SKILL.md) | QCheck contract and disagreement check |

Use `behest-contract-first` together with the one for your language.

- **[Walkthrough](WALKTHROUGH.md):** a full session building `median`, with the real output of every command.
- **[Examples](examples/):** finished Erlang, Elixir, Go, Rust, Python and Java projects you can run, including a `gen_server` with a stateful contract.
- **[Experiment](../experiment/):** runs comparing the skills with a plain prompt, with results and limits.
- **[Status](STATUS.md):** the full log of what was tested, where, and what each test found.

## How a session goes

1. You state the request. Claude picks a **tier** (light, standard or strict) from the risk and says why.
2. Claude drafts the contract and sends **one message**: a few numbered questions (each with its options, its proposal first), a list headed "I will also assume, unless you object", and real generated cases showing what the contract demands.
3. You reply `ok`, or name what to change. **Read the list of assumptions**: in the experiment about half of the unusual things a human wanted were caught there, not by the questions.
4. Claude folds the answers in, freezes the contract (standard and strict), implements, and runs the checks its tier calls for.
5. The final report says what the contract covers, which choices were yours, which were defaults, and what is not pinned.

**Not only for new code.** The skills also work on code you already have. Ask Claude to write the contract for an existing function or library (examples, properties, effects) and to list the unclear cases in `OPEN.md` before changing anything. The disagreement check compares the current code against a second implementation or a plain reference model, and each disagreement is either a bug or a missing example. This is how the bugs in [elx_vast](https://github.com/ayarodionov/elx_vast) and [Exfoil](https://github.com/ayarodionov/exfoil) were found: both existed before Behest. The contract records what the code should do, so you decide, case by case, whether a surprising current behaviour is a bug to fix or a rule to keep.

The workflow, the freeze-by-hash script, the edit-blocking hook and the effect scan are language-independent. C++ is not covered: its contract would need a test framework chosen per project and its effects (memory, undefined behaviour) are not visible to a grep, so the fit is weaker.

## Tiers

The workflow has three levels, chosen by risk. What never changes is that every choice the request left open is shown to the human, with a proposal, before any code is written.

| Tier | For | What it does |
| --- | --- | --- |
| Light | Small code that is cheap to redo | Examples as an ordinary test file, one message with questions and defaults, implement, report. Nothing frozen. |
| Standard | Library and public functions (the default) | Contract with a reference model, one-message approval, freeze, effect scan, mutation check; a disagreement check only when there is no reference model. |
| Strict | Money, security, data loss, concurrency, APIs that cannot change | Everything, plus an independent review of the contract, frozen test configuration and a CI check. |

## Install

You do **not** need the whole Behest repo. The skills are self-contained folders (`behest-contract-first` plus one per language: `behest-elixir`, `behest-erlang`, `behest-go`, `behest-rust`, `behest-python`, `behest-java`, `behest-julia`, `behest-typescript`, `behest-kotlin`, `behest-csharp`, `behest-scala`, `behest-gleam`, `behest-clojure`, `behest-haskell`, `behest-ocaml`), and installing means copying them into a Claude Code skills directory:

| Where | Path | Effect |
| --- | --- | --- |
| All your projects | `~/.claude/skills/` | Personal install |
| One project | `<project>/.claude/skills/` | Commit it and your team gets the same skills |

Install `behest-contract-first` plus the one for your language (or all of them). The `examples/`, `WALKTHROUGH.md`, prototype and language design are not needed.

### Easiest: ask Claude Code to install them

If you use Claude Code, paste a prompt like this into a session (replace `<LANGUAGES>` with yours, from `elixir`, `erlang`, `go`, `rust`, `python`, `java`, `julia`, `typescript`, `kotlin`, `csharp`, `scala`, `gleam`, `clojure`, `haskell`, `ocaml`, and say "project install" if you want them in the current project instead of for all your projects):

```text
Install the Behest skills from https://github.com/ayarodionov/Behest for me.
Copy only skills/behest-contract-first and the skills for these languages:
<LANGUAGES, for example: elixir, erlang, julia> into ~/.claude/skills/.
Keep the scripts executable, then check that
~/.claude/skills/behest-contract-first/SKILL.md exists and tell me what you
installed.
```

Claude runs the same steps as Option 1 below and will ask your permission before running commands. Then start a **new** Claude Code session so the skills are picked up, and ask for something the skill covers (see "Check that it worked"). To turn on the edit-blocking hook as well, add: *"Also add the PreToolUse hook from skills/README.md (Enforcement, step 2) to .claude/settings.json."* Read the hook and the scripts first if you want to know what they do; they are short.

### Option 1: git, downloading only the skills

```sh
src="$(mktemp -d)"
git clone --depth 1 --filter=blob:none --sparse https://github.com/ayarodionov/Behest "$src"
git -C "$src" sparse-checkout set skills/behest-contract-first skills/behest-elixir skills/behest-erlang skills/behest-go skills/behest-rust skills/behest-python skills/behest-java skills/behest-julia skills/behest-typescript skills/behest-kotlin skills/behest-csharp skills/behest-scala skills/behest-gleam skills/behest-clojure skills/behest-haskell skills/behest-ocaml
mkdir -p ~/.claude/skills                       # or <project>/.claude/skills
cp -r "$src"/skills/behest-* ~/.claude/skills/
rm -rf "$src"
```

### Option 2: no git, one archive download

```sh
tmp="$(mktemp -d)"
curl -L https://github.com/ayarodionov/Behest/archive/refs/heads/main.tar.gz | tar -xz -C "$tmp"
mkdir -p ~/.claude/skills                       # or <project>/.claude/skills
cp -r "$tmp"/*/skills/behest-* ~/.claude/skills/
rm -rf "$tmp"
```

### Option 3: by hand

On the GitHub page choose **Code, Download ZIP**, unzip it, and copy the `skills/behest-*` folders into `~/.claude/skills/` (or `<project>/.claude/skills/`).

### Check that it worked

```sh
ls ~/.claude/skills/behest-contract-first/SKILL.md
ls -l ~/.claude/skills/behest-contract-first/scripts/    # the .sh files should be executable (-rwxr-xr-x)
```

Then start a new Claude Code session and ask for something the skill covers, for example *"Implement a median function in Erlang with the Behest contract-first workflow"*. Claude should begin with a contract and questions, not code.

### Requirements

- Claude Code (the scripts and the hook run on your machine).
- `bash`. On Windows use WSL or Git Bash.
- `python3`, only for the edit-blocking hook.
- For Erlang: EUnit and PropEr. For Elixir: Mix and StreamData. For Go: Go 1.21 or newer, nothing else. For Rust: cargo and access to crates.io (proptest). For Python: `pip install pytest hypothesis mypy`. For Java: a JDK and JUnit 5 (Maven or Gradle; the example runs with just `javac` and the JUnit console jar). For Julia: the `Test` and `Random` standard libraries. For TypeScript: Node 18 or newer, `vitest` and `fast-check`. For Kotlin: Gradle with Kotest. For C#: the .NET SDK with xUnit and FsCheck. For Scala: sbt with ScalaCheck. For Gleam: `gleeunit` and `qcheck`. For Clojure: `test.check`. For Haskell: GHC with QuickCheck. For OCaml: dune with `qcheck-core` (see the language skills).

### Update or remove

To update, run the same commands again; they overwrite the old files. To remove: `rm -rf ~/.claude/skills/behest-*`. Contract files you approved in your projects, and their `.behest-approved` lists, are not affected.

## Enforcement (optional, recommended)

Skills are advice: Claude can skip a step. These pieces make the important rules mechanical.

**1. Freeze approved contract files.** When you approve a contract, record it:

```sh
.claude/skills/behest-contract-first/scripts/approved.sh approve test/contracts/median_contract_test.exs
```

This writes `.behest-approved` (commit it). `approved.sh check` fails if any approved file changes; run it in CI or a pre-commit hook.

**2. Block edits while Claude works.** Add a hook to `.claude/settings.json`. (The paths below assume a project install. For a personal install under `~/.claude/skills`, use `"$HOME"/.claude/skills/behest-contract-first/hooks/block_approved_edits.sh` as the command, and run the scripts from `~/.claude/skills/...` in step 1 and 3.)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit|NotebookEdit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/skills/behest-contract-first/hooks/block_approved_edits.sh"
          }
        ]
      }
    ]
  }
}
```

Claude then cannot edit an approved file or the lock file; it is told to stop and explain instead. To change a contract, you run `approved.sh unlock <file>`, edit, and approve again.

**3. Check effects.** `scripts/effects.sh --declared <contract> <implementation files>` fails if the implementation uses an effect (`send`, `spawn`, `ets`, `io`, `time`, `random`, `state`) the contract did not declare. The language is chosen from the file extension (`.ex .exs .erl .hrl`, `.go`, `.jl`, `.rs`, `.py`, `.java`, `.ts .tsx .js .jsx .mjs .cjs`, `.kt .kts`, `.cs`, `.scala .sc`, `.gleam`, `.clj .cljs .cljc`, `.hs`, `.ml .mli`). It is a grep heuristic, not a proof.

**4. Measure the contract.** `scripts/mutate.py --test "<command that runs the contract>" <implementation files>` makes one small change at a time to the implementation (swaps `<` and `<=`, `+` and `-`, `true` and `false`, `0` and `1`, and so on), reruns the contract and restores the file. A change the contract still passes on is printed as `SURVIVED`: it is either a missing example or a change that makes no difference. It works on text, so it is the same script for every language; it needs `python3`, refuses approved contract files, and restores the originals even when interrupted. For code written as a chain of steps it also deletes one step at a time (a line starting with `|>` or `.name(`), and in regular expressions it changes character classes (`[^...]` to `[...]`, one member dropped, `]+` to `]*`). It is slow (one contract run per mutant; `--max` limits the number) and a heuristic: mutants that no longer compile count as killed.

## What this does and does not give you

| Behest idea | In the skills |
| --- | --- |
| Contract first, human approves | Yes: one message with questions and defaults, one reply, then frozen by hash (standard and strict tiers) |
| Inline examples and properties | As test files (ExUnit/StreamData, EUnit/PropEr, Go `testing`/`quick`, Rust cargo/proptest, Python pytest/Hypothesis, Java JUnit 5, Julia `Test`, and the property libraries of the other languages), not language syntax |
| `open` items: never guess silently | Open points are sorted into questions (asked) and defaults (listed, with a proposal); `check_open.sh` fails while any remain. Claude can still ignore it if no hook or CI enforces it |
| A reference to check against | A slow, obviously correct reference model in the contract; for processes, a model run against random command sequences |
| Disagreement check | A procedure and a template; Claude writes the two implementations. Used when there is no reference model, and always in the strict tier |
| Measuring the contract | A mutation check (`mutate.py`): changes the contract does not notice are missing examples |
| Effort matched to risk | Three tiers; the light tier costs about the same as a plain prompt |
| Effects visible | Declared in the contract, checked by a heuristic scan |
| Typed protocols between processes | **No.** This needs a real type system or compiler |
| Compile-time enforcement of everything | **No.** Enforcement is by hook and CI, and shell commands such as `sed -i` bypass the hook (CI catches them) |

## Status

The full log, with what each test found, is in [STATUS.md](STATUS.md). In short:

| Part | State |
| --- | --- |
| Workflow scripts (`check_open.sh`, `approved.sh`, the edit-blocking hook) | Run on sample projects and in every example's `check.sh` |
| Effect scan (`effects.sh`) | Patterns for all 15 languages run on good and bad sample files. A text search, not a proof; it has given one false alarm, since fixed |
| Mutation check (`mutate.py`) | Run on the Python, Go, Erlang and Elixir code here; it found real gaps in the `median` contracts and in the `gen_server` example |
| Erlang, Go, Rust, Python, Java, TypeScript, Clojure, Haskell, OCaml templates | Compiled and run where they were written |
| Elixir and Julia contract and disagreement templates | Run on a user's machine. The Elixir stateful template was run where it was written; the Elixir reference-model template was not run |
| Kotlin, C#, Scala, Gleam templates | **Not run.** Written from documentation; expect small API differences |
| Install steps | Option 1 run against GitHub; Option 2 run on a local archive |

**Does it help?** In the [experiment](../experiment/results/README.md), on tasks where the human wants several unusual things, the skills got 52 of 52 decisions right and a plain prompt 46 of 52 after one round of corrections; the light tier got 26 of 26 at the same agent time as the plain prompt. On tasks where the conventional answer is what the human wants, a plain prompt was nearly as good (63 of 69 against 69 of 69) at a fifth of the cost. These are small runs with an AI playing the human, so treat them as a first look, not as proof.

**Not tested:** a person (not an AI) answering the questions and reading the defaults; a live Claude Code session with the hook installed; whether an agent picks the standard or strict tier when it should; contracts between several processes; the `rebar3`, Maven, Gradle and `dune` setups.
