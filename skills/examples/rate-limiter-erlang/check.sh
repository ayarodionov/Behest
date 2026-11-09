#!/usr/bin/env bash
# Runs the whole check chain for this example: the same checks the skill asks Claude to run.
# Needs Erlang with EUnit and PropEr on the code path; no rebar3.
set -euo pipefail
cd "$(dirname "$0")"
S=../../behest-contract-first/scripts
OUT=_build_example
MODS="rate_limit_contract_tests, rate_limit_clock_contract_tests"   # comma-separated contract modules

rm -rf "$OUT" && mkdir -p "$OUT"

echo "--- open items";     "$S/check_open.sh"
echo "--- approved files"; "$S/approved.sh" check
echo "--- compile";        erlc -o "$OUT" src/*.erl test/*.erl && echo ok

echo "--- contract"
if out="$(erl -noshell -pa "$OUT" -eval \
    "R = eunit:test([$MODS], []), halt(case R of ok -> 0; _ -> 1 end)." 2>&1)"; then
  echo "$out" | sed 's/\x1b\[[0-9;]*m//g' | grep -E 'All [0-9]+ tests passed'
else
  echo "$out" | sed 's/\x1b\[[0-9;]*m//g' | grep -v 'in call from'
  exit 1
fi

echo "--- effects (each implementation file against its own contract)"
"$S/effects.sh" --declared test/rate_limit_contract_tests.erl       src/rate_limit.erl
"$S/effects.sh" --declared test/rate_limit_clock_contract_tests.erl src/rate_limit_clock.erl

echo "all checks passed"
