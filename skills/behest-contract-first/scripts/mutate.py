#!/usr/bin/env python3
"""Mutation check: how much of the implementation does the contract really pin down?

Makes one small change at a time to the implementation (a "mutant"), runs the
contract, and restores the file. A mutant the contract fails on is "killed". A
mutant the contract still passes on "survived": the contract does not notice that
change, so it is either a missing example or a change that makes no difference.

Usage:
    mutate.py --test "COMMAND" [options] IMPL_FILE...

    --test CMD      command that runs the contract; exit 0 means it passed (required)
    --timeout SEC   per-run limit; a mutant that hangs counts as killed (default 120)
    --max N         try at most N mutants, spread evenly over the files (default 200)
    --seed N        seed for choosing which mutants to try when there are more than --max
    --strict        exit 1 if any mutant survived
    --list          print the mutants that would be tried and exit

Works on text, so it is language-independent: it swaps comparison, arithmetic and
logical operators (only where they have spaces around them), true/false, and the
integers 0, 1 and 2. Mutants that no longer compile count as killed, so the score
flatters the contract a little. Text inside triple-quoted blocks (Elixir @doc, Python
docstrings) is skipped: it is documentation, not behaviour. A heuristic, not a proof.

Mutate implementation files only. Files frozen by approved.sh are refused.
"""
import argparse
import os
import random
import re
import signal
import subprocess
import sys
import time

# (regex, replacement). Operators need spaces around them: fewer broken mutants and
# no clashes with ->, =>, <-, <<, >>, generics or type syntax.
SWAPS = [
    (r" <= ", " < "), (r" < ", " <= "), (r" >= ", " > "), (r" > ", " >= "),
    (r" =< ", " < "),                      # Erlang
    (r" === ", " !== "), (r" !== ", " === "),
    (r" == ", " != "), (r" != ", " == "),
    (r" =:= ", " =/= "), (r" =/= ", " =:= "),  # Erlang
    (r" /= ", " == "),                     # Haskell, Erlang
    (r" \+ ", " - "), (r" - ", " + "), (r" \* ", " / "), (r" / ", " * "),
    (r" \+\. ", " -. "), (r" -\. ", " +. "), (r" \*\. ", " /. "), (r" /\. ", " *. "),  # OCaml, Gleam
    (r" && ", " || "), (r" \|\| ", " && "),
    (r" and ", " or "), (r" or ", " and "),
    (r" andalso ", " orelse "), (r" orelse ", " andalso "),
    (r"\btrue\b", "false"), (r"\bfalse\b", "true"),
    (r"\bTrue\b", "False"), (r"\bFalse\b", "True"),
    (r"(?<![\w.])0(?![\w.])", "1"), (r"(?<![\w.])1(?![\w.])", "0"),
    (r"(?<![\w.])2(?![\w.])", "3"),
]
SWAPS = [(re.compile(p), r) for p, r in SWAPS]

COMMENT = re.compile(r"^\s*(#|%|//|/\*|\*|--|;|\(\*)")
SKIP_LINE = re.compile(r"behest-effects|^\s*(import|from|use|using|package|module|namespace|require|open|include)\b|^\s*-(module|export|include)")


def in_string(line, pos):
    """Crude: an odd number of double quotes before pos means we are inside a string."""
    return line.count('"', 0, pos) % 2 == 1


def find_mutants(path, text):
    mutants = []
    in_doc = False  # inside a """ ... """ block: Elixir @doc/@moduledoc, Python docstrings
    for n, line in enumerate(text.split("\n")):
        if line.count('"""') % 2 == 1:
            in_doc = not in_doc
            continue
        if in_doc or '"""' in line or COMMENT.match(line) or SKIP_LINE.search(line):
            continue
        for rx, repl in SWAPS:
            for m in rx.finditer(line):
                if in_string(line, m.start()):
                    continue
                mutants.append((path, n, m.start(), m.end(), repl))
    return mutants


def apply(text, mutant):
    _, n, start, end, repl = mutant
    lines = text.split("\n")
    lines[n] = lines[n][:start] + repl + lines[n][end:]
    return "\n".join(lines), lines[n]


class Files:
    """Writes mutants and always puts the originals back."""

    def __init__(self, paths):
        self.original = {}
        for p in paths:
            with open(p, encoding="utf-8") as f:
                self.original[p] = f.read()
        self.tick = time.time()

    def write(self, path, text):
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        # A strictly increasing mtime, so build tools and bytecode caches that
        # compare timestamps always see the change (and the restore).
        self.tick = max(self.tick + 2, time.time())
        os.utime(path, (self.tick, self.tick))

    def restore(self, path=None):
        for p in [path] if path else self.original:
            self.write(p, self.original[p])


def run(cmd, timeout):
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")
    proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                            env=env, start_new_session=True)
    try:
        return proc.wait(timeout=timeout) == 0, False
    except subprocess.TimeoutExpired:
        os.killpg(proc.pid, signal.SIGKILL)
        proc.wait()
        return False, True


def approved_files():
    lock = ".behest-approved"
    if not os.path.isfile(lock):
        return set()
    names = set()
    with open(lock, encoding="utf-8") as f:
        for line in f:
            parts = line.split()
            if parts:
                names.add(os.path.normpath(parts[-1]))
    return names


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--test", required=True)
    ap.add_argument("--timeout", type=float, default=120)
    ap.add_argument("--max", type=int, default=200)
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--strict", action="store_true")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("files", nargs="+")
    args = ap.parse_args()

    frozen = approved_files()
    for p in args.files:
        if not os.path.isfile(p):
            sys.exit(f"no such file: {p}")
        if os.path.normpath(p) in frozen:
            sys.exit(f"{p} is an approved contract file; mutate the implementation, not the contract")

    files = Files(args.files)
    mutants = []
    for p in args.files:
        mutants += find_mutants(p, files.original[p])
    total_found = len(mutants)
    if total_found > args.max:
        random.Random(args.seed).shuffle(mutants)
        mutants = sorted(mutants[: args.max])

    if args.list:
        for m in mutants:
            _, line = apply(files.original[m[0]], m)
            print(f"{m[0]}:{m[1] + 1}: {line.strip()}")
        print(f"{len(mutants)} mutants (of {total_found} found)")
        return 0
    if not mutants:
        print("no mutants found (nothing this tool knows how to change)")
        return 0

    def bail(signum, _frame):
        files.restore()
        sys.exit(f"interrupted (signal {signum}); originals restored")

    signal.signal(signal.SIGINT, bail)
    signal.signal(signal.SIGTERM, bail)

    ok, timed_out = run(args.test, args.timeout)
    if not ok:
        sys.exit("the contract does not pass on the unmodified code"
                 + (" (timed out)" if timed_out else "") + "; fix that first")

    survived, killed, hung = [], 0, 0
    try:
        for i, m in enumerate(mutants, 1):
            path = m[0]
            text, new_line = apply(files.original[path], m)
            files.write(path, text)
            try:
                passed, timed_out = run(args.test, args.timeout)
            finally:
                files.restore(path)
            if passed:
                old_line = files.original[path].split("\n")[m[1]]
                survived.append((path, m[1] + 1, old_line.strip(), new_line.strip()))
            else:
                killed += 1
                hung += timed_out
            if sys.stderr.isatty():
                print(f"\r{i}/{len(mutants)} tried, {len(survived)} survived", end="", file=sys.stderr)
    finally:
        files.restore()
        if sys.stderr.isatty():
            print(file=sys.stderr)

    for path, n, old, new in survived:
        print(f"SURVIVED {path}:{n}")
        print(f"    was: {old}")
        print(f"    now: {new}")
    note = f" ({hung} by timeout)" if hung else ""
    sampled = f", sampled from {total_found}" if total_found > len(mutants) else ""
    print(f"{killed} of {len(mutants)} mutants killed{note}, {len(survived)} survived{sampled} (heuristic)")
    if survived:
        print("Each survivor is a change the contract does not notice: a missing example, or a "
              "change that makes no difference. Show them to the human; do not edit the contract yourself.")
    return 1 if survived and args.strict else 0


if __name__ == "__main__":
    sys.exit(main())
