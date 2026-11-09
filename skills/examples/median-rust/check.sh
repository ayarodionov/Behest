#!/usr/bin/env bash
# Runs the whole check chain for this example: the same checks the skill asks Claude to run.
# Needs cargo and access to crates.io (for proptest).
set -euo pipefail
cd "$(dirname "$0")"
S=../../behest-contract-first/scripts

echo "--- open items";     "$S/check_open.sh"
echo "--- approved files"; "$S/approved.sh" check
echo "--- contract"
cargo test --quiet --test median_contract 2>&1 | grep -E "^test result|FAILED|panicked" || true
cargo test --quiet --test median_contract >/dev/null
echo "--- effects"
"$S/effects.sh" --declared tests/median_contract.rs src/lib.rs
echo "all checks passed"
