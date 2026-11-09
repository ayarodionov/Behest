#!/usr/bin/env bash
# Tracks which contract files a human has approved, by content hash.
#
#   approved.sh approve FILE...   record the current hash of each file
#   approved.sh check             fail if any approved file changed or vanished
#   approved.sh list              list approved files
#   approved.sh unlock FILE...    stop tracking a file (a human decision)
#
# The lock file is .behest-approved in the current directory (override with BEHEST_LOCK).
set -euo pipefail

LOCK="${BEHEST_LOCK:-.behest-approved}"

usage() {
  sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

hash_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

# Remove one file's entry from the lock file.
drop() {
  [ -f "$LOCK" ] || return 0
  local tmp
  tmp="$(mktemp)"
  awk -v f="$1" '{ h = $1; sub(/^[^ ]+  /, ""); if ($0 != f) print h "  " $0 }' "$LOCK" > "$tmp"
  mv "$tmp" "$LOCK"
}

cmd="${1:-}"
[ -n "$cmd" ] || usage
shift

case "$cmd" in
  approve)
    [ $# -gt 0 ] || usage
    for f in "$@"; do
      [ -f "$f" ] || { echo "no such file: $f" >&2; exit 1; }
      drop "$f"
      echo "$(hash_of "$f")  $f" >> "$LOCK"
      echo "approved $f"
    done
    ;;

  check)
    if [ ! -f "$LOCK" ]; then
      echo "nothing approved yet"
      exit 0
    fi
    bad=0
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      want="${line%%  *}"
      f="${line#*  }"
      if [ ! -f "$f" ]; then
        echo "MISSING  $f"
        bad=1
      elif [ "$(hash_of "$f")" != "$want" ]; then
        echo "CHANGED  $f"
        bad=1
      fi
    done < "$LOCK"
    if [ "$bad" -eq 1 ]; then
      echo "approved contract files were modified" >&2
      exit 1
    fi
    echo "all approved files unchanged"
    ;;

  list)
    [ -f "$LOCK" ] && sed 's/^[^ ]*  //' "$LOCK" || echo "nothing approved yet"
    ;;

  unlock)
    [ $# -gt 0 ] || usage
    for f in "$@"; do
      drop "$f"
      echo "unlocked $f"
    done
    ;;

  *)
    usage
    ;;
esac
