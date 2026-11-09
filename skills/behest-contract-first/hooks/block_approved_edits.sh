#!/usr/bin/env bash
# Claude Code PreToolUse hook: blocks Edit/Write/MultiEdit/NotebookEdit on
# human-approved contract files (listed in .behest-approved) and on the lock
# file itself. Exit code 2 blocks the tool call; stderr is shown to Claude.
#
# Needs python3 (to read the hook's JSON input and normalize paths).
# Limit: this does not see shell commands such as `sed -i`. Run
# `approved.sh check` in CI to catch those.

root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOCK="${BEHEST_LOCK:-$root/.behest-approved}"

[ -f "$LOCK" ] || exit 0

abs() {
  python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

path="$(python3 -c '
import json, sys
try:
    d = json.load(sys.stdin).get("tool_input", {})
except Exception:
    d = {}
print(d.get("file_path") or d.get("notebook_path") or "")
' 2>/dev/null)"

[ -n "$path" ] || exit 0
case "$path" in
  /*) ;;
  *) path="$root/$path" ;;
esac
target="$(abs "$path")"

if [ "$target" = "$(abs "$LOCK")" ]; then
  echo "Blocked: .behest-approved is managed by the human. Do not edit it." >&2
  exit 2
fi

while IFS= read -r line; do
  [ -n "$line" ] || continue
  f="${line#*  }"
  case "$f" in
    /*) cand="$f" ;;
    *) cand="$root/$f" ;;
  esac
  if [ "$target" = "$(abs "$cand")" ]; then
    echo "Blocked: $f is an approved contract file. Do not change it to make the build pass. If you think the contract is wrong, stop and explain to the human with a concrete input; they can unlock it." >&2
    exit 2
  fi
done < "$LOCK"

exit 0
