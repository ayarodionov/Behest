#!/usr/bin/env bash
# Prepares an empty working directory for one run of the experiment.
#
#     experiment/new_run.sh TASK ARM DIR
#
# TASK  slug | intervals | duration
# ARM   plain   - only the prompt
#       behest  - the prompt plus the Behest skills in DIR/.claude/skills
# DIR   a new directory OUTSIDE this repository, so the AI cannot see the
#       hidden checks, the answers or the reference solutions.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
[ $# -eq 3 ] || { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
task="$1"; arm="$2"; dir="$3"

[ -f "$here/tasks/$task/prompt.md" ] || { echo "no such task: $task" >&2; exit 2; }
case "$arm" in plain|behest) ;; *) echo "ARM must be plain or behest" >&2; exit 2 ;; esac
[ ! -e "$dir" ] || { echo "$dir already exists" >&2; exit 2; }

mkdir -p "$dir"
abs="$(cd "$dir" && pwd)"
case "$abs/" in "$(dirname "$here")"/*) rmdir "$dir"; echo "DIR must be outside the Behest repository" >&2; exit 2 ;; esac

cp "$here/tasks/$task/prompt.md" "$dir/prompt.md"
if [ "$arm" = behest ]; then
  mkdir -p "$dir/.claude/skills"
  cp -R "$here/../skills/behest-contract-first" "$here/../skills/behest-elixir" "$dir/.claude/skills/"
fi
echo "ready: $abs ($task, $arm). Start a fresh AI session there and give it prompt.md."
