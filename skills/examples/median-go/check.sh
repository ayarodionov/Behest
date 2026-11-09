#!/usr/bin/env bash
# Runs the whole check chain for this example: the same checks the skill asks Claude to run.
# Needs Go 1.21 or newer; no other dependencies.
set -euo pipefail
cd "$(dirname "$0")"
S=../../behest-contract-first/scripts

echo "--- open items";     "$S/check_open.sh"
echo "--- approved files"; "$S/approved.sh" check
echo "--- vet";            go vet ./... && echo ok
echo "--- contract (with the race detector)"
go test -race -count=1 ./...
echo "--- effects"
"$S/effects.sh" --declared median_contract_test.go median.go
echo "all checks passed"
