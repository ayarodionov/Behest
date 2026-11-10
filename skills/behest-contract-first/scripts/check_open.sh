#!/usr/bin/env bash
# Fails while OPEN.md still has unresolved items ("- [ ] ..."), questions or defaults.
# Usage: check_open.sh [path/to/OPEN.md]
set -uo pipefail

file="${1:-OPEN.md}"

if [ ! -f "$file" ]; then
  echo "no $file: nothing open"
  exit 0
fi

if grep -nE '^[[:space:]]*[-*] \[ \]' "$file"; then
  echo "unresolved open items in $file: show them to the human (questions asked, defaults listed), add each answer to the contract, then delete the item" >&2
  exit 1
fi

echo "no open items"
