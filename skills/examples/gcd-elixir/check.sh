#!/usr/bin/env bash
# Runs the whole check chain for this example: the same checks the skill asks Claude to run.
# Needs Elixir and Mix, and network access to fetch StreamData from Hex on first run.
set -euo pipefail
cd "$(dirname "$0")"
S=../../behest-contract-first/scripts

echo "--- open items";     "$S/check_open.sh"
echo "--- approved files"; "$S/approved.sh" check
echo "--- contract (examples + properties)"
mix deps.get >/dev/null
mix test
echo "--- effects"
"$S/effects.sh" --declared test/gcd_examples_test.exs lib/gcd.ex
echo "all checks passed"
