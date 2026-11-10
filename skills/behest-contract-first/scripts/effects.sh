#!/usr/bin/env bash
# Heuristic effect scan for Elixir, Erlang, Go, Julia, Rust, Python, Java, TypeScript/JavaScript,
# Kotlin, C#, Gleam, Clojure, Haskell, OCaml and Scala source files. A grep, not a proof.
#
# What the code may do is declared in a comment (any comment style works):
#     # behest-effects: none            (Elixir, Julia, Python)
#     %% behest-effects: time, ets      (Erlang)
#     // behest-effects: send, time     (Go, Rust, Java, TypeScript, Kotlin, C#, Scala)
#     ;; behest-effects: none           (Clojure)
#     -- behest-effects: none           (Haskell)
#     (* behest-effects: none *)        (OCaml)
# Effects: send spawn ets io time random state
#   send   messages, channels, remote calls
#   spawn  processes, goroutines, tasks, threads
#   ets    ETS tables (Erlang, Elixir, Gleam)
#   io     files, console, network, subprocesses
#   time   clock reads, sleeps, timers
#   random random numbers
#   state  global or shared mutable state (all except Erlang/Elixir)
#
# Usage: effects.sh --declared CONTRACT_FILE IMPL_FILE...
#        effects.sh IMPL_FILE...          (each file carries its own declaration)
#
# The language is chosen from each implementation file's extension
# (.ex .exs .erl .hrl | .go | .jl | .rs | .py | .java | .ts .tsx .js .jsx .mjs .cjs | .kt .kts | .cs |
# .gleam | .clj .cljs .cljc | .hs | .ml .mli | .scala .sc).
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
    *.java)                 echo java ;;
    *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs) echo typescript ;;
    *.kt|*.kts)             echo kotlin ;;
    *.cs)                   echo csharp ;;
    *.gleam)                echo gleam ;;
    *.clj|*.cljs|*.cljc)    echo clojure ;;
    *.hs)                   echo haskell ;;
    *.ml|*.mli)             echo ocaml ;;
    *.scala|*.sc)           echo scala ;;
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

    java:send)    echo 'BlockingQueue|ConcurrentLinkedQueue|SynchronousQueue|Exchanger|Piped(Input|Output)Stream|(^|[^A-Za-z_])(Server)?Socket\(|\.(sendMessage|publish)\(' ;;
    java:spawn)   echo 'new Thread\(|Thread\.(start|ofVirtual|ofPlatform)|Executor|CompletableFuture\.(supplyAsync|runAsync)|parallelStream|ForkJoin|ProcessBuilder|Runtime\.getRuntime' ;;
    java:io)      echo 'System\.(out|err|in)\b|import java\.(io|nio|net)|java\.(io|nio\.file|net)\.|(^|[^A-Za-z_])(Files|Paths)\.|Path\.of|new (File|FileReader|FileWriter|Scanner)\(|HttpClient|System\.console' ;;
    java:time)    echo 'System\.(currentTimeMillis|nanoTime)|(Instant|LocalDate|LocalDateTime|LocalTime|ZonedDateTime|OffsetDateTime)\.now|new Date\(\)|Thread\.sleep|TimeUnit\.[A-Z]+\.sleep|Clock\.system|Calendar\.getInstance' ;;
    java:random)  echo 'Math\.random|new (Secure)?Random\(|ThreadLocalRandom|SecureRandom|UUID\.randomUUID|RandomGenerator' ;;
    java:state)   echo '(^|[[:space:]])static [^(=;]*[]A-Za-z_>] +[A-Za-z_][A-Za-z_0-9]* *(=|;)|Atomic(Integer|Long|Boolean|Reference)|ConcurrentHashMap|synchronized|volatile|ThreadLocal' ;;

    rust:state)   echo 'static mut|Mutex|RwLock|Atomic[A-Z]|RefCell|OnceLock|OnceCell|LazyLock|lazy_static|thread_local!|Arc<' ;;

    typescript:send)   echo 'postMessage\(|\.emit\(|new (WebSocket|MessageChannel|BroadcastChannel|EventSource)|\.dispatchEvent\(|\.send\(' ;;
    typescript:spawn)  echo 'new (Worker|SharedWorker)\(|child_process|worker_threads|cluster\.fork|(^|[^A-Za-z_.])(spawn|fork|execSync|execFile)\(' ;;
    typescript:io)     echo 'console\.|(^|[^A-Za-z_.])fetch\(|from "(node:)?(fs|http|https|net|os|child_process|readline)(/promises)?"|process\.(stdout|stderr|stdin|argv|exit)|XMLHttpRequest|localStorage|sessionStorage|(^|[^A-Za-z_.])(document|window)\.|readFileSync|writeFileSync' ;;
    typescript:time)   echo 'Date\.now|new Date\(|performance\.now|setTimeout|setInterval|setImmediate|requestAnimationFrame|process\.hrtime' ;;
    typescript:random) echo 'Math\.random|crypto\.(randomUUID|getRandomValues|randomBytes|randomInt)|randomUUID' ;;
    typescript:state)  echo '^(export )?let |(^|[[:space:]])var |process\.env|globalThis|(^|[^A-Za-z_.])(window|global)\.' ;;

    kotlin:send)   echo 'Channel(<|\()|\.(trySend|offer)\(|(Mutable)?(Shared|State)Flow|BlockingQueue|\.emit\(' ;;
    kotlin:spawn)  echo '(^|[^A-Za-z_.])(launch|async) *[({]|GlobalScope|runBlocking|(^|[^A-Za-z_.])thread *[({(]|Thread\(|Executors|CoroutineScope|ProcessBuilder' ;;
    kotlin:io)     echo '(^|[^A-Za-z_.])(println|print|readLine|readln)\(|System\.(out|err|in)|java\.(io|nio|net)|(^|[^A-Za-z_])File\(|Files\.|Paths\.|HttpClient|\.(readText|writeText|bufferedReader)\(' ;;
    kotlin:time)   echo 'System\.(currentTimeMillis|nanoTime)|(Instant|LocalDate|LocalDateTime|LocalTime|ZonedDateTime|Clock)\.(now|system)|(^|[^A-Za-z_.])delay\(|Thread\.sleep|measureTime|TimeSource' ;;
    kotlin:random) echo '(^|[^A-Za-z_.])Random(\.|\()|kotlin\.random|java\.util\.Random|SecureRandom|UUID\.randomUUID|\.(random|shuffled)\(' ;;
    kotlin:state)  echo '(^|[[:space:]])var |lateinit|^object |Atomic(Int|Long|Boolean|Reference)|ConcurrentHashMap|mutable(List|Map|Set)Of|@Volatile|@Synchronized|synchronized\(|ThreadLocal' ;;

    csharp:send)   echo 'Channel(\.Create|<)|\.Writer\.|BlockingCollection|ConcurrentQueue|\.SendAsync\(|\.Post\(|(^|[^A-Za-z_])Socket' ;;
    csharp:spawn)  echo 'Task\.(Run|Factory|WhenAll|WhenAny)|new Thread\(|ThreadPool|Parallel\.|\.AsParallel\(|Process\.Start|ProcessStartInfo|async void' ;;
    csharp:io)     echo 'Console\.|System\.IO|(^|[^A-Za-z_.])(File|Directory)\.|StreamReader|StreamWriter|HttpClient|WebClient|Environment\.(Exit|GetEnvironmentVariable)|Debug\.Write|Trace\.' ;;
    csharp:time)   echo 'DateTime(Offset)?\.(Now|UtcNow|Today)|Stopwatch|Task\.Delay|Thread\.Sleep|Environment\.TickCount|TimeProvider|PeriodicTimer|new Timer\(' ;;
    csharp:random) echo 'new Random\(|Random\.Shared|RandomNumberGenerator|Guid\.NewGuid|System\.Security\.Cryptography' ;;
    csharp:state)  echo '(^|[[:space:]])static [^(=;]*[]A-Za-z_>] +[A-Za-z_][A-Za-z_0-9]* *(=|;|\{)|Interlocked|ConcurrentDictionary|volatile|lock *\(|ThreadStatic|AsyncLocal' ;;

    gleam:send)   echo 'process\.(send|call|try_call|receive|select)|actor\.(call|send)' ;;
    gleam:spawn)  echo 'process\.(start|spawn|spawn_unlinked)|actor\.start|supervisor|task\.async' ;;
    gleam:ets)    echo '(^|[^A-Za-z_])ets[._]|"ets"' ;;
    gleam:io)     echo 'io\.(print|println|debug)|simplifile|httpc|envoy|shellout|@external|argv' ;;
    gleam:time)   echo 'gleam/time|birl|system_time|monotonic|process\.sleep|os_time' ;;
    gleam:random) echo '(int|float)\.random|list\.shuffle|gleam/crypto|strong_random' ;;
    gleam:state)  echo 'persistent_term|process_dictionary|put_process|actor\.new|actor\.start' ;;

    clojure:send)   echo '\((send|send-off|deliver|promise|chan|>!!|<!!|>!|<!|put!|take!|offer!|poll!)[ )]|core\.async' ;;
    clojure:spawn)  echo '\((future|future-call|pmap|pcalls|pvalues|go|go-loop|thread|agent)[ )]|\(Thread\.|Executors|ExecutorService' ;;
    clojure:io)     echo '\((println|print|prn|pr|printf|slurp|spit|read-line|with-open|sh|flush)[ )]|clojure\.java\.(io|shell)|java\.(io|net|nio)|\(io/|\*out\*|\*err\*|\*in\*|System/(out|err|in|getenv|exit)|clj-http' ;;
    clojure:time)   echo 'System/(currentTimeMillis|nanoTime)|Thread/sleep|\((time|Date\.)[ )]|(Instant|LocalDate|LocalDateTime|ZonedDateTime)/now|clj-time' ;;
    clojure:random) echo '\((rand|rand-int|rand-nth|shuffle|random-uuid|random-sample)[ )]|java\.util\.Random|SecureRandom|UUID/randomUUID|Math/random|\(Random\.' ;;
    clojure:state)  echo '\((atom|ref|agent|volatile!|swap!|reset!|swap-vals!|reset-vals!|alter|dosync|commute|ref-set|alter-var-root|set!|defonce)[ )]|\^:dynamic|\(binding |ThreadLocal|\(aset |make-array|into-array' ;;

    haskell:send)   echo 'MVar|TVar|TChan|TQueue|TMVar|(^|[^A-Za-z_])Chan([^A-Za-z_]|$)|atomically|Control\.Concurrent' ;;
    haskell:spawn)  echo 'forkIO|forkOS|forkFinally|Control\.Concurrent\.Async|mapConcurrently|System\.Process|createProcess|callProcess|readProcess|Control\.Parallel|parMap' ;;
    haskell:io)     echo 'import +(qualified +)?(System\.(IO|Directory|Environment|Exit)|Network)|(^|[^A-Za-z_.])(putStrLn|putStr|print|getLine|getContents|readFile|writeFile|appendFile|hPutStr|hPutStrLn|interact|getArgs|lookupEnv|exitWith|exitFailure|trace|traceShow)([^A-Za-z_]|$)|(^|[^A-Za-z_.])IO([^A-Za-z_]|$)|unsafePerformIO|unsafeDupablePerformIO' ;;
    haskell:time)   echo 'getCurrentTime|getPOSIXTime|getZonedTime|getCPUTime|getMonotonicTime|threadDelay|Data\.Time\.Clock|System\.CPUTime|System\.Timeout' ;;
    haskell:random) echo 'System\.Random|randomRIO|randomIO|newStdGen|getStdGen|getStdRandom|Crypto\.Random' ;;
    haskell:state)  echo 'IORef|STRef|IOArray|IOUArray|Data\.Array\.(ST|IO|MArray)|Data\.Vector\.(Unboxed\.)?Mutable|unsafe[A-Z][A-Za-z]*|NOINLINE' ;;

    ocaml:send)   echo 'Event\.|Eio\.Stream|Lwt_mvar|Lwt_stream|Lwt\.(wakeup|wait)|Unix\.(send|sendto)|Mutex\.|Condition\.' ;;
    ocaml:spawn)  echo 'Thread\.create|Domain\.spawn|Unix\.(fork|create_process)|Sys\.command|Lwt\.async|Eio\.Fiber|Fiber\.(fork|both|all)' ;;
    ocaml:io)     echo '(^|[^A-Za-z_.])(print_(string|endline|newline|int|float|char|bytes)|prerr_[a-z]+|open_in|open_out|input_line|read_line|read_int|output_string|close_in|close_out|stdin|stdout|stderr)|Printf\.(printf|eprintf|fprintf)|Format\.(printf|eprintf|print_[a-z]+)|In_channel|Out_channel|Unix\.|Sys\.(command|getenv|readdir|file_exists|remove|rename|argv)|Filename\.temp|Eio_main|Lwt_io|Cohttp' ;;
    ocaml:time)   echo 'Sys\.time|Unix\.(time|gettimeofday|sleep|sleepf|localtime)|Ptime_clock|Mtime_clock|Eio\.Time|Lwt_unix\.sleep' ;;
    ocaml:random) echo '(^|[^A-Za-z_.])Random\.|Stdlib\.Random|Mirage_crypto_rng' ;;
    ocaml:state)  echo '(^|[^A-Za-z_.])ref[ (]|:=|mutable |Hashtbl\.(create|add|replace|remove)|Array\.(set|fill|blit|sort)|Bytes\.(set|fill|blit)|Atomic\.|Buffer\.(create|add)|Obj\.magic|Domain\.DLS' ;;

    scala:send)   echo 'ActorRef|\.tell\(|\.ask\(|(^|[^A-Za-z_])Actor|BlockingQueue|ConcurrentLinkedQueue|Exchanger|SyncVar|Promise\(|cats\.effect\.std\.Queue| ! ' ;;
    scala:spawn)  echo 'Future(\.|\()|new Thread\(|ExecutionContext|Executors|IO\.(start|fromFuture)|\.par\b|ForkJoin|scala\.sys\.process|Await\.' ;;
    scala:io)     echo '(^|[^A-Za-z_.])(println|print)\(|Console\.|StdIn|scala\.io|Source\.from|java\.(io|nio|net)|Files\.|Paths\.|(^|[^A-Za-z_])File\(|Http|sys\.(process|env)|System\.(out|err|in|getenv|exit)|IO\.(println|readLine|print|blocking)' ;;
    scala:time)   echo 'System\.(currentTimeMillis|nanoTime)|(Instant|LocalDate|LocalDateTime|LocalTime|ZonedDateTime|Clock)\.(now|system)|Thread\.sleep|Deadline\.now|IO\.sleep|scheduleAtFixedRate' ;;
    scala:random) echo 'scala\.util\.Random|(^|[^A-Za-z_.])Random\.|new Random|SecureRandom|UUID\.randomUUID|ThreadLocalRandom|Math\.random|math\.random' ;;
    scala:state)  echo '(^|[[:space:]])var |mutable\.|ArrayBuffer|ListBuffer|StringBuilder|Atomic(Integer|Long|Boolean|Reference)|TrieMap|ConcurrentHashMap|@volatile|synchronized|ThreadLocal|sys\.props|System\.getProperty' ;;
  esac
}

# ignore_for LANG EFFECT -> regex of matched lines that are NOT an effect
ignore_for() {
  case "$1:$2" in
    go:state) echo 'errors\.New|fmt\.Errorf' ;;   # sentinel errors are fine
    java:state) echo 'static final [^=]*(String|int|long|double|boolean|char|Pattern|Logger) ' ;;   # constants
    csharp:state) echo 'static readonly [^=]*(string|int|long|double|bool|char|decimal|Regex) |(^|[[:space:]])const ' ;;
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
    echo "$f: unknown language (supported: .ex .exs .erl .hrl .go .jl .rs .py .java .ts .tsx .js .jsx .mjs .cjs .kt .kts .cs .gleam .clj .cljs .cljc .hs .ml .mli .scala .sc)" >&2
    status=1
    continue
  fi

  src="${declared_from:-$f}"
  header="$(grep -hoE 'behest-effects:.*' "$src" | head -n 1 | sed 's/behest-effects://; s/\*)//; s/-}//')"
  if [ -z "$header" ]; then
    echo "$src: no behest-effects declaration (write 'behest-effects: none' for pure code)" >&2
    status=1
    continue
  fi
  declared=" $(echo "$header" | tr ',' ' ' | tr -s ' ' | tr '[:upper:]' '[:lower:]') "

  for eff in $EFFECTS; do
    pat="$(pattern_for "$lang" "$eff")"
    [ -n "$pat" ] || continue
    hits="$(grep -nE "$pat" "$f" | grep -vE '^[0-9]+:[[:space:]]*(#|%|//|/\*|\*|--|;|\(\*)' || true)"
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
