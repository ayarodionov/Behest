#!/usr/bin/env bash
# Heuristic effect scan for Elixir and Erlang source files. A grep, not a proof.
#
# What the code may do is declared in a comment:
#     # behest-effects: none            (Elixir)
#     %% behest-effects: time, ets      (Erlang)
# Effects: send spawn ets io time random
#
# Usage: effects.sh --declared CONTRACT_FILE IMPL_FILE...
#        effects.sh IMPL_FILE...          (each file carries its own declaration)
#
# Prefer the first form: the declaration then lives in the human-approved
# contract file, which the AI cannot edit, not in the code being checked.
# Exits 1 if a file uses an effect it did not declare, or has no declaration.
set -uo pipefail

declared_from=""
if [ "${1:-}" = "--declared" ]; then
  declared_from="${2:-}"
  [ -f "$declared_from" ] || { echo "no such contract file: $declared_from" >&2; exit 2; }
  shift 2
fi

EFFECTS="send spawn ets io time random"

pattern_for() {
  case "$1" in
    send)   echo '(^|[^A-Za-z_.])send\(|Process\.send|GenServer\.(call|cast|reply)|gen_server:(call|cast|reply)|erlang:send|[A-Za-z_)] ! ' ;;
    spawn)  echo 'spawn|Task\.(async|start)|start_link|Agent\.start|Supervisor\.start|supervisor:start' ;;
    ets)    echo ':ets\.|(^|[^A-Za-z_])ets:' ;;
    io)     echo 'IO\.|File\.|Port\.|System\.cmd|:io\.|:file\.|:gen_tcp|:gen_udp|:httpc|(^|[^A-Za-z_])io:|(^|[^A-Za-z_])file:|gen_tcp:|gen_udp:|httpc:|HTTPoison|Req\.' ;;
    time)   echo 'System\.(monotonic_time|system_time|os_time)|DateTime\.utc_now|NaiveDateTime\.utc_now|Date\.utc_today|Process\.(sleep|send_after)|erlang:(system_time|monotonic_time|send_after|start_timer)|:erlang\.(system_time|monotonic_time|send_after|start_timer)|(^|[^A-Za-z_])timer:|:timer\.|os:system_time|:os\.system_time' ;;
    random) echo ':rand\.|(^|[^A-Za-z_])rand:|Enum\.(random|shuffle|take_random)|crypto:strong_rand|:crypto\.strong_rand' ;;
  esac
}

[ $# -gt 0 ] || { sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }

status=0
for f in "$@"; do
  if [ ! -f "$f" ]; then
    echo "no such file: $f" >&2
    status=1
    continue
  fi

  src="${declared_from:-$f}"
  header="$(grep -hoE 'behest-effects:.*' "$src" | head -n 1 | sed 's/behest-effects://')"
  if [ -z "$header" ]; then
    echo "$src: no behest-effects declaration (write 'behest-effects: none' for pure code)" >&2
    status=1
    continue
  fi
  declared=" $(echo "$header" | tr ',' ' ' | tr -s ' ' | tr '[:upper:]' '[:lower:]') "

  for eff in $EFFECTS; do
    hits="$(grep -nE "$(pattern_for "$eff")" "$f" | grep -vE '^[0-9]+:[[:space:]]*(#|%)' || true)"
    [ -n "$hits" ] || continue
    case "$declared" in
      *" $eff "*) ;;
      *)
        echo "$f: UNDECLARED effect '$eff'" >&2
        echo "$hits" | sed "s|^|  $f:|" >&2
        status=1
        ;;
    esac
  done
done

[ "$status" -eq 0 ] && echo "effects match declarations (heuristic scan)"
exit "$status"
