#!/usr/bin/env bash
# Heuristic effect scan for Elixir, Erlang, Go, Julia, Rust and Python source files. A grep, not a proof.
#
# What the code may do is declared in a comment (any comment style works):
#     # behest-effects: none            (Elixir, Julia, Python)
#     %% behest-effects: time, ets      (Erlang)
#     // behest-effects: send, time     (Go, Rust)
# Effects: send spawn ets io time random state
#   send   messages, channels, remote calls
#   spawn  processes, goroutines, tasks, threads
#   ets    ETS tables (Erlang/Elixir only)
#   io     files, console, network, subprocesses
#   time   clock reads, sleeps, timers
#   random random numbers
#   state  global or shared mutable state (Go, Julia, Rust, Python)
#
# Usage: effects.sh --declared CONTRACT_FILE IMPL_FILE...
#        effects.sh IMPL_FILE...          (each file carries its own declaration)
#
# The language is chosen from each implementation file's extension
# (.ex .exs .erl .hrl | .go | .jl | .rs | .py).
# Prefer the first form: the declaration then lives in the human-approved
# contract file, which the AI cannot edit, not in the code being checked.
# Exits 1 if a file uses an effect it did not declare, or has no declaration.
set -uo pipefail

EFFECTS="send spawn ets io time random state"

declared_from=""
if [ "${1:-}" = "--declared" ]; then
  declared_from="${2:-}"
  [ -f "$declared_from" ] || { echo "no such contract file: $declared_from" >&2; exit 2; }
  shift 2
fi

lang_of() {
  case "$1" in
    *.ex|*.exs|*.erl|*.hrl) echo beam ;;
    *.go)                   echo go ;;
    *.jl)                   echo julia ;;
    *.rs)                   echo rust ;;
    *.py)                   echo python ;;
    *)                      echo unknown ;;
  esac
}

# pattern_for LANG EFFECT -> extended regex ("" = this effect does not apply)
pattern_for() {
  case "$1:$2" in
    beam:send)   echo '(^|[^A-Za-z_.])send\(|Process\.send|GenServer\.(call|cast|reply)|gen_server:(call|cast|reply)|erlang:send|[A-Za-z_)] ! ' ;;
    beam:spawn)  echo 'spawn|Task\.(async|start)|start_link|Agent\.start|Supervisor\.start|supervisor:start' ;;
    beam:ets)    echo ':ets\.|(^|[^A-Za-z_])ets:' ;;
    beam:io)     echo 'IO\.|File\.|Port\.|System\.cmd|:io\.|:file\.|:gen_tcp|:gen_udp|:httpc|(^|[^A-Za-z_])io:|(^|[^A-Za-z_])file:|gen_tcp:|gen_udp:|httpc:|HTTPoison|Req\.' ;;
    beam:time)   echo 'System\.(monotonic_time|system_time|os_time)|DateTime\.utc_now|NaiveDateTime\.utc_now|Date\.utc_today|Process\.(sleep|send_after)|erlang:(system_time|monotonic_time|send_after|start_timer)|:erlang\.(system_time|monotonic_time|send_after|start_timer)|(^|[^A-Za-z_])timer:|:timer\.|os:system_time|:os\.system_time' ;;
    beam:random) echo ':rand\.|(^|[^A-Za-z_])rand:|Enum\.(random|shuffle|take_random)|crypto:strong_rand|:crypto\.strong_rand' ;;

    go:send)     echo '<-' ;;
    go:spawn)    echo '(^|[[:space:]])go [A-Za-z_(]' ;;
    go:io)       echo '(^|[^A-Za-z_])(os|io|ioutil|bufio|net|http|exec|syscall|log)\.|fmt\.(Print|Fprint|Scan|Fscan)' ;;
    go:time)     echo 'time\.(Now|Since|Until|Sleep|After|AfterFunc|Tick|NewTimer|NewTicker)' ;;
    go:random)   echo '(^|[^A-Za-z_])rand\.' ;;
    go:state)    echo '^var |(^|[^A-Za-z_])(sync|atomic)\.' ;;

    julia:send)   echo 'put!\(|take!\(|Channel\(|remotecall|@spawnat|RemoteChannel' ;;
    julia:spawn)  echo '@spawn|@async|@threads|@distributed|@sync|(^|[^A-Za-z_])Task\(|addprocs' ;;
    julia:io)     echo '(^|[^A-Za-z_!])(print|println|printstyled|display|open|readline|readlines|readdir|mkdir|mkpath|rm|cp|mv|download|run|isfile|isdir|ispath)\(|@(info|warn|error|debug)|(^|[^A-Za-z_])(stdout|stderr|stdin)|HTTP\.|(^|[^A-Za-z_.])(read|write)\(' ;;
    julia:time)   echo '(^|[^A-Za-z_])(time|time_ns|now|today|sleep)\(|@(time|elapsed|timed)|Timer\(' ;;
    julia:random) echo '(^|[^A-Za-z_])(rand|randn|randperm|randstring|randexp|shuffle|sample)!?\(|Random\.|RandomDevice' ;;
    julia:state)  echo '(^|[[:space:]])global |Ref\(|Ref\{|ENV\[' ;;

    rust:send)    echo '\.(send|try_send|recv|try_recv|recv_timeout)\(|mpsc::|(^|[^A-Za-z_])(sync_)?channel(::<[^>]*>)?\(' ;;
    rust:spawn)   echo 'thread::(spawn|scope|Builder)|tokio::(spawn|task)|(^|[^A-Za-z_.])spawn(_blocking)?\(|rayon|par_iter|\.spawn\(' ;;
    rust:io)      echo 'std::(fs|io|net|process|env)|(^|[^A-Za-z_])(print|println|eprint|eprintln|dbg)!|File::|tokio::(fs|io|net)|Command::new|reqwest|::stdin\(|::stdout\(|::stderr\(' ;;
    rust:time)    echo 'Instant::now|SystemTime::now|(thread|tokio::time)::sleep|tokio::time|\.elapsed\(' ;;
    rust:random)  echo '(^|[^A-Za-z_])rand::|thread_rng|rand::random|getrandom|fastrand|OsRng' ;;
    python:send)   echo '(^|[^A-Za-z_.])(queue|socket)\.|(^|[^A-Za-z_])(Queue|SimpleQueue|Pipe)\(|\.(send|sendall|recv|put_nowait|get_nowait)\(' ;;
    python:spawn)  echo '(^|[^A-Za-z_.])(threading|multiprocessing|subprocess)\.|(^|[^A-Za-z_])(Thread|Process|ThreadPoolExecutor|ProcessPoolExecutor)\(|concurrent\.futures|asyncio\.(create_task|run|gather|ensure_future)|os\.(fork|system|popen)' ;;
    python:io)     echo '(^|[^A-Za-z_.])(print|open|input)\(|(^|[^A-Za-z_.])(os|sys|shutil|pathlib|socket|requests|urllib|http|logging|tempfile|glob|subprocess)\.|(^|[^A-Za-z_])Path\(|\.(read_text|write_text|read_bytes|write_bytes)\(' ;;
    python:time)   echo '(^|[^A-Za-z_.])time\.(time|sleep|monotonic|perf_counter|process_time)|datetime\.(now|utcnow|today)|date\.today|asyncio\.sleep' ;;
    python:random) echo '(^|[^A-Za-z_.])(random|secrets)\.|(np|numpy)\.random|uuid\.uuid[14]|import (random|secrets)' ;;
    python:state)  echo '(^|[[:space:]])global |lru_cache|functools\.cache|os\.environ|^[A-Za-z_][A-Za-z_0-9]* *(:[^=]*)?= *(\[\]|\{\}|dict\(\)|list\(\)|set\(\))|def [A-Za-z_0-9]+\(.*= *(\[\]|\{\})[,)]' ;;

    rust:state)   echo 'static mut|Mutex|RwLock|Atomic[A-Z]|RefCell|OnceLock|OnceCell|LazyLock|lazy_static|thread_local!|Arc<' ;;
  esac
}

# ignore_for LANG EFFECT -> regex of matched lines that are NOT an effect
ignore_for() {
  case "$1:$2" in
    go:state) echo 'errors\.New|fmt\.Errorf' ;;   # sentinel errors are fine
  esac
}

usage() {
  awk 'NR > 1 && /^set /{exit} NR > 1 {print}' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

[ $# -gt 0 ] || usage

status=0
for f in "$@"; do
  if [ ! -f "$f" ]; then
    echo "no such file: $f" >&2
    status=1
    continue
  fi

  lang="$(lang_of "$f")"
  if [ "$lang" = unknown ]; then
    echo "$f: unknown language (supported: .ex .exs .erl .hrl .go .jl .rs .py)" >&2
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
    pat="$(pattern_for "$lang" "$eff")"
    [ -n "$pat" ] || continue
    hits="$(grep -nE "$pat" "$f" | grep -vE '^[0-9]+:[[:space:]]*(#|%|//|/\*|\*)' || true)"
    ign="$(ignore_for "$lang" "$eff")"
    if [ -n "$ign" ] && [ -n "$hits" ]; then
      hits="$(echo "$hits" | grep -vE "$ign" || true)"
    fi
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
