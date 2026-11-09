# Behest: Design

Behest is a small, statically typed BEAM language. Humans write and review the contract (protocols, examples, properties, effects). AI writes the implementation underneath.

## 1. Design goals

When AI writes most of the code, the bottleneck moves from writing to checking. Behest is optimized for the reviewer.

1. **Contract on top, code underneath.** Every module opens with what a human must approve: protocol, examples, properties, effects. The body is the AI's job.
2. **Executable intent.** Examples and properties are syntax, not comments, and the compiler runs them.
3. **Process conversations are typed.** Message mismatches, the most common OTP bug, become compile errors.
4. **Nothing hidden.** No macros, no implicit imports, no `use` injecting callbacks. What you read is what runs.
5. **One way to do it.** A small, regular language makes AI output uniform and diffs easy to read.
6. **Plain BEAM underneath.** Compiles to Core Erlang, runs under normal OTP, calls Erlang and Elixir libraries directly.

## 2. Protocols

A protocol declares the conversation between two roles: who sends what, in what order, and what may come back. It is a lightweight session type.

```
protocol Account
  client -> server : {deposit, amount: pos_int}
  server -> client : {ok, balance: int}

  client -> server : {withdraw, amount: pos_int}
  server -> client : {ok, balance: int} | {error, insufficient_funds}

  client -> server : close          # ends the session
end
```

What the compiler checks:

- Every message a process sends is one its peer's protocol expects.
- Every request in the protocol has a handler, and every handler replies with an allowed shape.
- A `call` always gets exactly one reply; a `cast` never gets one.
- Message payloads match their declared types.

Out of scope for v1: proofs about deadlock across many processes. Those need full multiparty session types; two-party checks already catch most real bugs.

At runtime a protocol compiles to ordinary `gen_server` calls and casts, so Behest processes talk to Erlang and Elixir processes. Messages from untyped code are validated at the boundary.

## 3. Examples and properties

Each function or handler can carry `examples` and `property` blocks. The build fails if any example fails or a property finds a counterexample.

```
fn median(xs: List(Float)) -> Result(Float, Empty)
  examples
    [3.0, 1.0, 2.0]       => ok(2.0)
    [4.0, 1.0, 3.0, 2.0]  => ok(2.5)
    []                    => error(Empty)
  property
    forall xs, p in permutations(xs): median(xs) == median(p)
  ...
end
```

For processes, examples are short scripts against a **virtual clock and mailbox**, so timing behaviour is deterministic and fast to test:

```
examples
  at 0ms    send check(:a) x3  => ok, ok, ok
  at 10ms   send check(:a)     => error(rate_limited)
  at 1000ms send check(:a)     => ok
```

Rules:

- Examples are exact; properties are randomized (PropEr-style generators derived from types).
- A property's generator seed is printed on failure, so a counterexample can become a new example.
- The AI may add examples; it may never edit or delete human-approved ones. Approved blocks carry a marker the compiler tracks.

## 4. Open items and contract gaps

The AI must ask when the contract does not say what to do, not guess. Models will often guess unless told otherwise, so Behest enforces this in two ways instead of relying on good behaviour.

**`open`: the human marks what is undecided.**

```
fn median(xs: List(Float)) -> Result(Float, Empty)
  open "NaN handling: skip, error, or propagate?"
  examples
    [3.0, 1.0, 2.0] => ok(2.0)
  ...
```

The build fails while any `open` remains, and lists the questions. The AI cannot silently pick an answer; it brings the question to the human, who answers by adding an example or property and deleting the `open` line. The [prototype](../prototype/) implements this.

**Disagreement check: finding gaps nobody noticed.** A contract can be incomplete in ways its author did not see. To find them, the toolchain asks the AI for two different implementations that both pass the contract, then searches for an input where they disagree (random and property-driven testing). Each disagreeing input is a missing example. The AI shows it with both answers, for example "`gcd(0, 0)`: one returns 0, the other raises. Which is right?", and the human's answer becomes a new approved example. Repeat until the implementations agree everywhere the search reaches.

Limits, stated plainly: the search finds gaps its generators reach, not all of them, and two implementations from the same model can share a blind spot. It narrows the gap between intent and contract; it does not close it.

The rule given to the AI is the same in both cases: if the contract is unclear, ask for another example or property, and never guess.

## 5. Effects

A function's header lists what it may do beyond computing a value. A function with no `effects` line is pure.

```
fn save(user: User) -> Result(Id, DbError)
  effects [db, log]
  ...
end
```

| Effect | Covers |
| --- | --- |
| `send` | sending messages to other processes |
| `spawn` | starting processes |
| `ets` | reading or writing ETS tables |
| `io` | files, sockets, ports |
| `time` | reading the clock, timers |
| `random` | randomness |
| custom (`db`, `log`) | declared by libraries, built from the ones above |

The compiler checks that a function's effects include those of everything it calls. For a reviewer, one glance answers "can this touch the network?" Pure functions are the easy majority to approve; the effectful ones get the attention.

## 6. Supervision as data

The supervision tree is a declared value, checked at compile time, not code spread across `init/1` callbacks.

```
supervisor Bank
  strategy one_for_one, max_restarts 5 per 10s
  children
    Ledger          restart permanent
    RateLimiter     restart permanent, args [limit: 100, window: 1s]
    AuditWriter     restart transient
end
```

The compiler checks that every child exists, its args match its `start` signature, and every process that uses a protocol has a peer somewhere in the tree. The same declaration renders as a diagram for review.

## 7. A complete program

See [examples/rate_limiter.bh](../examples/rate_limiter.bh). Everything above `implementation` is the contract a human approves; everything below is AI-written and may be regenerated freely as long as the contract holds.

If the AI later switches the implementation to ETS for speed, it must add `ets` to the effects line. That shows up in the diff as a contract change that needs approval.

## 8. How to build it

Compiler pipeline, written in Elixir or Erlang:

1. **Parse** to an AST (leex/yecc or a hand-written parser).
2. **Type check** with Hindley–Milner plus row types for records; no gradual typing inside Behest.
3. **Check protocols:** match every send and handler against the declared session.
4. **Check effects:** infer each function's effects and compare with its declared line.
5. **Run examples and properties** in a sandbox with a virtual clock.
6. **Emit Core Erlang**, then hand it to `compile:forms/2` for BEAM bytecode.

Phased plan:

| Phase | Delivers | Proves |
| --- | --- | --- |
| 1 | Pure functions, types, inline examples, Core Erlang output | The examples-as-syntax idea works |
| 2 | Properties with type-derived generators | AI-written code can be checked automatically |
| 3 | Processes, two-party protocols, virtual clock | The main BEAM-specific win |
| 4 | Effects, supervision as data | Review gets fast and reliable |
| 5 | Interop: typed wrappers for OTP and Elixir libraries | Usable on real projects |

Shortcut for phases 1–2: prototype as an Elixir macro library first (`defspec` with examples and properties) to test the ergonomics before writing a parser.

## 9. Open questions

- Build on Gleam (fork or compiler plugin) or start fresh?
- Surface syntax: Elixir-like or ML-like?
- How far to take session types: two-party only, or multiparty with deadlock checks later?
- How does the compiler mark examples as human-approved: a signature, a lock file, or git history?
- Hot code upgrade: how do protocol changes between versions get checked?
- Disagreement check: how are alternative implementations produced and compared (AI-generated variants, mutating the implementation, or symbolic execution), and how much of the search is affordable on every build?
- Name: Behest ("at someone's behest") says it: the human asks, the AI builds.
