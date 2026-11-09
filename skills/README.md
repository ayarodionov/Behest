# Behest as Claude skills

The same idea as the [Behest language](../README.md), delivered as Claude skills that work on ordinary Elixir and Erlang projects today. No new language and no compiler: the human and Claude build a contract of examples and properties first, Claude asks about every unclear case instead of guessing, and only then implements.

| Skill | Purpose |
| --- | --- |
| [`behest-contract-first`](behest-contract-first/SKILL.md) | The workflow, plus scripts and a hook that enforce it |
| [`behest-elixir`](behest-elixir/SKILL.md) | ExUnit and StreamData contract and disagreement-test templates |
| [`behest-erlang`](behest-erlang/SKILL.md) | EUnit and PropEr contract and disagreement-test templates |

Use `behest-contract-first` together with the one for your language.

## Install

Copy the skill folders into your skills directory:

```sh
cp -r skills/behest-* ~/.claude/skills/      # for all your projects
# or: cp -r skills/behest-* <project>/.claude/skills/
```

## Enforcement (optional, recommended)

Skills are advice: Claude can skip a step. These pieces make the important rules mechanical.

**1. Freeze approved contract files.** When you approve a contract, record it:

```sh
.claude/skills/behest-contract-first/scripts/approved.sh approve test/contracts/median_contract_test.exs
```

This writes `.behest-approved` (commit it). `approved.sh check` fails if any approved file changes; run it in CI or a pre-commit hook.

**2. Block edits while Claude works.** Add a hook to `.claude/settings.json`:

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
- **Not tested:** the Elixir templates. StreamData could not be fetched where these skills were written, so treat `behest-elixir` templates as a starting point and run them in your project first.
- Not tested in a live Claude session: how reliably Claude follows the skill steps. The hook and CI check are what make the key rules mechanical.
