#!/usr/bin/env bash
# Runs the whole check chain for this example: the same checks the skill asks Claude to run.
# Needs: pip install pytest hypothesis mypy
set -euo pipefail
cd "$(dirname "$0")"
S=../../behest-contract-first/scripts

echo "--- open items";     "$S/check_open.sh"
echo "--- approved files"; "$S/approved.sh" check
echo "--- types";          mypy --strict median.py
echo "--- contract";       python3 -m pytest -q -p no:cacheprovider
echo "--- effects"
"$S/effects.sh" --declared tests/test_median_contract.py median.py
echo "all checks passed"
