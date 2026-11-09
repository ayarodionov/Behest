# Behest as Claude skills

The same idea as the [Behest language](../README.md), delivered as Claude skills that work on ordinary Elixir, Erlang, Go, Rust, Python, Java and Julia projects today. No new language and no compiler: the human and Claude build a contract of examples and properties first, Claude asks about every unclear case instead of guessing, and only then implements.

| Skill | Purpose |
| --- | --- |
| [`behest-contract-first`](behest-contract-first/SKILL.md) | The workflow, plus scripts and a hook that enforce it |
| [`behest-elixir`](behest-elixir/SKILL.md) | ExUnit and StreamData contract and disagreement-test templates |
| [`behest-erlang`](behest-erlang/SKILL.md) | EUnit and PropEr contract and disagreement-test templates |
| [`behest-go`](behest-go/SKILL.md) | `testing` and `testing/quick` contract, fuzz-based disagreement check; standard library only |
| [`behest-rust`](behest-rust/SKILL.md) | cargo tests and proptest contract, proptest-based disagreement check |
| [`behest-python`](behest-python/SKILL.md) | pytest and Hypothesis contract, Hypothesis-based disagreement check, mypy |
| [`behest-java`](behest-java/SKILL.md) | JUnit 5 contract with seeded random properties, disagreement template with a small shrinker; jqwik optional |
| [`behest-julia`](behest-julia/SKILL.md) | `Test`-based contract and disagreement templates (run once on a user's machine) |

Use `behest-contract-first` together with the one for your language.

- **[Walkthrough](WALKTHROUGH.md):** a full session building `median`, with the real output of every command.
- **[Examples](examples/):** finished Erlang, Elixir, Go, Rust, Python and Java projects you can run.

The workflow, the freeze-by-hash script, the edit-blocking hook and the effect scan are language-independent. C++ is not covered: its contract would need a test framework chosen per project and its effects (memory, undefined behaviour) are not visible to a grep, so the fit is weaker.

## Install

You do **not** need the whole Behest repo. The skills are self-contained folders (`behest-contract-first` plus one per language: `behest-elixir`, `behest-erlang`, `behest-go`, `behest-rust`, `behest-python`, `behest-java`, `behest-julia`), and installing means copying them into a Claude Code skills directory:

| Where | Path | Effect |
| --- | --- | --- |
| All your projects | `~/.claude/skills/` | Personal install |
| One project | `<project>/.claude/skills/` | Commit it and your team gets the same skills |

Install `behest-contract-first` plus the one for your language (or all of them). The `examples/`, `WALKTHROUGH.md`, prototype and language design are not needed.

### Option 1: git, downloading only the skills

```sh
src="$(mktemp -d)"
git clone --depth 1 --filter=blob:none --sparse https://github.com/ayarodionov/Behest "$src"
git -C "$src" sparse-checkout set skills/behest-contract-first skills/behest-elixir skills/behest-erlang skills/behest-go skills/behest-rust skills/behest-python skills/behest-java skills/behest-julia
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
- For Erlang: EUnit and PropEr. For Elixir: Mix and StreamData. For Go: Go 1.21 or newer, nothing else. For Rust: cargo and access to crates.io (proptest). For Python: `pip install pytest hypothesis mypy`. For Java: a JDK and JUnit 5 (Maven or Gradle; the example runs with just `javac` and the JUnit console jar). For Julia: the `Test` and `Random` standard libraries (see the language skills).

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

**3. Check effects.** `scripts/effects.sh --declared <contract> <implementation files>` fails if the implementation uses an effect (`send`, `spawn`, `ets`, `io`, `time`, `random`, `state`) the contract did not declare. The language is chosen from the file extension (`.ex .exs .erl .hrl`, `.go`, `.jl`, `.rs`, `.py`, `.java`). It is a grep heuristic, not a proof.

## What this does and does not give you

| Behest idea | In the skills |
| --- | --- |
| Contract first, human approves | Yes: a workflow step, then frozen by hash |
| Inline examples and properties | As test files (ExUnit/StreamData, EUnit/PropEr, Go `testing`/`quick`, Rust cargo/proptest, Python pytest/Hypothesis, Java JUnit 5, Julia `Test`), not language syntax |
| `open` items: ask, don't guess | A workflow rule plus `check_open.sh`; Claude can still ignore it if no hook or CI enforces it |
| Disagreement check | A procedure and a template; Claude writes the two implementations |
| Effects visible | Declared in the contract, checked by a heuristic scan |
| Typed protocols between processes | **No.** This needs a real type system or compiler |
| Compile-time enforcement of everything | **No.** Enforcement is by hook and CI, and shell commands such as `sed -i` bypass the hook (CI catches them) |

## Status

What has actually been run:

- **Tested:** `check_open.sh`, `approved.sh`, `effects.sh` (including `--declared`) and the edit-blocking hook, on sample projects.
- **Tested:** the Erlang templates, compiled with `erlc` and run with EUnit and PropEr 1.2. The contract passes on a correct `median`, fails on a wrong one, and the disagreement check finds and shrinks a real counterexample. Not tested: the `rebar3` setup snippet.
- **Tested:** the install steps. Option 1 was run against the real GitHub repo (only the three skill folders were fetched, executable bits intact). For Option 2 the extract-and-copy steps were run on a local archive with GitHub's layout; the archive download itself could not be reached from where this was written.
- **Tested:** the [example projects](examples/): both Erlang ones pass their full `check.sh`; the Elixir one's examples, effect scan and approval checks run and pass.
- **Tested:** the Go skill, with Go 1.24: [`examples/median-go`](examples/median-go/) passes its `check.sh` including `go test -race`, the fuzz-based disagreement template found a lower-median alternative (shrunk automatically) and stayed quiet for an agreeing one, and the Go effect patterns were run on good and bad files. Writing the example, the contract found a real bug: `(a+b)/2` overflows to Inf for huge floats under `testing/quick`.
- **Tested:** the Rust skill, with cargo 1.97 and proptest 1.12: [`examples/median-rust`](examples/median-rust/) passes its `check.sh`, the proptest disagreement template found a lower-median alternative (shrunk automatically) and stayed quiet for an agreeing one, and the Rust effect patterns were run on good and bad files. Finding: the naive mean overflow survived 100,000 random proptest cases, so it became an explicit boundary example in the contract; the generator's reach matters.
- **Tested:** the Python skill, with Python 3.13, pytest 9, Hypothesis 6.170 and mypy 2.3: [`examples/median-python`](examples/median-python/) passes its `check.sh`. Against a naive first implementation the contract failed four tests: result type (`int` instead of `float`), NaN accepted, and a float overflow found both by an explicit example and, on its own, by Hypothesis (shrunk to two values near 9e307). The Hypothesis disagreement template found a lower-median alternative (shrunk to `[0, 1]`), caught an alternative that returned `0` instead of `0.0`, and stayed quiet for an agreeing one. The Python effect patterns were run on good and bad files; they are the weakest of the scans, since dynamic imports and aliases escape a grep.
- **Tested, with a limit:** the Java skill, with OpenJDK 21 and JUnit 5 (from apt): [`examples/median-java`](examples/median-java/) passes its `check.sh`. Against a naive implementation the contract failed on NaN and on a float overflow (the overflow only via the explicit boundary example; 2000 random inputs missed it, as in Rust). The disagreement template found a lower-median alternative shrunk to `[0.0, 1.0]` and stayed quiet for an agreeing one (the first shrinker stopped at a six-element input because removing one element flips odd/even length; it now also removes pairs). The Java effect patterns were run on good and bad files, and a bug in the `state` pattern was found and fixed that way. **Not tested:** Maven and Gradle builds and the optional jqwik upgrade. Maven Central was blocked where this was written (a proxy policy denial), so the example is compiled with `javac` and run with the JUnit console launcher instead.
- **Tested on a user's machine (not here):** the Julia skill. The contract template passes (6 examples, empty input, 3000 property checks) and the disagreement template printed a real disagreement. The first runs exposed two shrinker problems, both fixed and re-run: it stopped at a four-element input (removing one element flips odd/even length), and it drifted to a signed-zero difference (`0.0` vs `-0.0`); it now shrinks to the minimal two-element case. The `.jl` effect patterns were run here on good and bad files.
- **Tested on a user's machine (not here):** [`examples/gcd-elixir`](examples/gcd-elixir/) passes its full `check.sh` with StreamData: 4 properties and 5 tests, 0 failures, plus the open-items, approval and effect checks. The two Elixir *templates* (`behest-elixir/templates/`) also ran there: the contract passes (3 examples and 2 properties), and the disagreement template found and shrank a real disagreement to `[0, -1]` (mean vs lower middle value). The first run exposed weak shrinking (`list_of` removes one element at a time, flipping odd/even length), so the template now generates pairs. Neither was run where they were written (Hex was blocked there).
- Not tested in a live Claude session: how reliably Claude follows the skill steps. The hook and CI check are what make the key rules mechanical.
