# Behest as Claude skills

The same idea as the [Behest language](../README.md), delivered as Claude skills that work on ordinary Elixir and Erlang projects today. No new language and no compiler: the human and Claude build a contract of examples and properties first, Claude asks about every unclear case instead of guessing, and only then implements.

| Skill | Purpose |
| --- | --- |
| [`behest-contract-first`](behest-contract-first/SKILL.md) | The workflow, plus scripts and a hook that enforce it |
| [`behest-elixir`](behest-elixir/SKILL.md) | ExUnit and StreamData contract and disagreement-test templates |
| [`behest-erlang`](behest-erlang/SKILL.md) | EUnit and PropEr contract and disagreement-test templates |

Use `behest-contract-first` together with the one for your language.

- **[Walkthrough](WALKTHROUGH.md):** a full session building `median`, with the real output of every command.
- **[Examples](examples/):** finished Erlang and Elixir projects you can run.

## Install

You do **not** need the whole Behest repo. The skills are three self-contained folders, `behest-contract-first`, `behest-elixir` and `behest-erlang`, and installing means copying them into a Claude Code skills directory:

| Where | Path | Effect |
| --- | --- | --- |
| All your projects | `~/.claude/skills/` | Personal install |
| One project | `<project>/.claude/skills/` | Commit it and your team gets the same skills |

Install `behest-contract-first` plus the one for your language (or all three). The `examples/`, `WALKTHROUGH.md`, prototype and language design are not needed.

### Option 1: git, downloading only the skills

```sh
src="$(mktemp -d)"
git clone --depth 1 --filter=blob:none --sparse https://github.com/ayarodionov/Behest "$src"
git -C "$src" sparse-checkout set skills/behest-contract-first skills/behest-elixir skills/behest-erlang
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
- For Erlang: EUnit and PropEr. For Elixir: Mix and StreamData (see the language skills).

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

**3. Check effects.** `scripts/effects.sh --declared <contract> <implementation files>` fails if the implementation uses an effect (`send`, `spawn`, `ets`, `io`, `time`, `random`) the contract did not declare. It is a grep heuristic, not a proof.

## What this does and does not give you

| Behest idea | In the skills |
| --- | --- |
| Contract first, human approves | Yes: a workflow step, then frozen by hash |
| Inline examples and properties | As test files (ExUnit/StreamData, EUnit/PropEr), not language syntax |
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
- **Not tested:** the Elixir templates and the StreamData properties in `examples/gcd-elixir`. StreamData could not be fetched where these skills were written (Hex was blocked), so treat them as a starting point and run them in your project first.
- Not tested in a live Claude session: how reliably Claude follows the skill steps. The hook and CI check are what make the key rules mechanical.
