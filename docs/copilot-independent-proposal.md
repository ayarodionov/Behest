# An *copilot* proposal: a language for AI-written OTP code

This is my independent proposal in response to the question of what a language on top of OTP should look like if AI writes most of the code. It is an attempt to reason from the problem itself, rather than to restate or evaluate another proposal.

If AI writes most of the implementation, the language should optimize for **reviewing behavior, finding mistakes, and safely changing systems**. It should not make generated code disappear behind a promise that the compiler or the model will take care of everything. A human should be able to understand the important decisions without reading every line, and still be able to inspect the implementation when something goes wrong.

## Put the OTP runtime model in the foreground

The language should make the parts of OTP that determine system behavior easy to see:

- **Process boundaries:** what a process accepts, what it sends, and which other processes it depends on.
- **State and lifecycle:** what state a process owns, how it is initialized, and what happens to that state when the process restarts.
- **Failure behavior:** which failures are expected, which are allowed to crash a process, and how supervisors respond.
- **Time and concurrency:** where timeouts, retries, ordering assumptions, and asynchronous work affect results.

These are not implementation details in a concurrent system. They shape user-visible behavior and operational reliability, so they should be straightforward to review and test. The language can provide concise declarations and compiler checks, but should preserve familiar OTP concepts and make the generated runtime behavior debuggable.

## Make boundaries clear and useful

Types should help most where components meet: process messages, public APIs, configuration, and calls into libraries. A compiler should catch incompatible message shapes and invalid return values where it can. At boundaries with ordinary Erlang, Elixir, or external services, it should make validation and uncertainty explicit rather than implying that the whole system is statically safe.

I would avoid making a new type system the only source of confidence. Types can rule out classes of mismatches, but they do not establish that a workflow is correct, that a retry is safe, or that a supervisor policy matches operational needs. Those decisions need examples, tests, and review.

## Treat tests as the executable explanation

AI-generated code should come with tests that explain the important behavior, not just tests that happen to make the build green. The workflow should make it natural to cover:

- representative examples and edge cases;
- properties that should hold across many inputs;
- process interactions, including message sequences and failures;
- timing-sensitive behavior using controllable clocks or other deterministic test facilities.

When a requirement is ambiguous, the tool should surface the decision instead of silently turning a guess into code. When checks pass, it should report what they covered and what they did not. A test suite is evidence, not a proof; generated tests can be wrong or incomplete too.

## Keep generated work inspectable

The source should have a predictable shape, formatting should be automatic, and compiler output and runtime traces should lead developers back to meaningful source locations. Generated code should be easy to diff, debug, and replace. A language that makes code technically regenerable but practically opaque would move the review burden rather than reduce it.

Changes to externally visible behavior, process interfaces, persistence assumptions, and failure handling deserve special attention in review. Those are the decisions that can have consequences beyond the function being edited. The tooling should help make such changes visible without requiring every implementation detail to be manually approved.

## Build on OTP, not beside it

Interop with Erlang and Elixir should be a first-class requirement: existing libraries, tools, releases, and operational practices are a major part of OTP's value. The language should not require teams to abandon the runtime model or ecosystem to get better checks around generated code.

I would first prototype the workflow and compiler feedback around existing OTP code. Then I would test whether a distinct syntax or compiler meaningfully improves readability, correctness, or iteration speed. A new language is justified only if it earns its cost in tooling, learning, interop, and long-term maintenance.

## Measure the human side

The central question is not whether AI can produce code in the language. It is whether developers can more quickly detect wrong assumptions, review changes, and safely maintain the resulting systems. Evaluate the approach on real tasks and with real developers: measure review effort, escaped defects, the quality of tests, and the cost of changing requirements. Compare it with well-tested Erlang or Elixir workflows, not only with unstructured prompting.

The goal is not to make humans approve every line or to claim that generated code is automatically trustworthy. It is to give humans a compact, honest view of the decisions that matter, backed by checks whose guarantees and limits are clear.

## Plan: how to build the tool

The plan follows the principles above: start with a workflow layer over existing Erlang/Elixir code, and introduce a new syntax or compiler only if measurements justify it. Each phase has an exit criterion; if it is not met, stop or change direction rather than proceeding.

### Phase 0: Define the review problem (1-2 weeks)

- Collect 10-20 representative OTP tasks (a gen_server with retries, a supervision tree change, a protocol handler, a rate limiter, etc.), each with a known-good solution and a set of seeded bugs.
- Write down the review questions a human must answer for each: what does the process accept and send, what state does it own, what happens on crash and restart, where are the timeouts.
- Record a baseline: how long review takes, and which seeded bugs reviewers catch, using plain Erlang/Elixir plus an AI assistant.

**Exit criterion:** a benchmark task set and baseline numbers exist.

### Phase 1: Behavior summary extractor (3-5 weeks)

- Build a tool, written in Erlang/Elixir, that reads compiled OTP modules and their abstract code and produces a compact **behavior summary** per process: callbacks implemented, messages handled and sent, state shape, supervision strategy and restart intensity, timers and timeouts, linked and monitored processes.
- Render the summary as readable text and as a diff between two revisions, so reviewers see changes to interfaces, state, and failure handling without reading every line.
- Mark anything it cannot determine (dynamic dispatch, apply with computed arguments) explicitly as *unknown*, rather than guessing.

**Exit criterion:** on the benchmark, the summary surfaces the majority of seeded interface and failure-handling bugs, and reviewers find it accurate.

### Phase 2: Boundary checks (3-5 weeks)

- Add optional, declared specifications at process boundaries: message types, public API specs, configuration schemas. Reuse Erlang `-spec`/`-type` and Dialyzer or Elixir typespecs where possible, rather than inventing a new type system.
- Generate runtime validation at boundaries with untyped Erlang/Elixir code and external services, and report these as uncertain, not statically checked.
- Include checks that a message sent anywhere in the codebase matches a declared message type of the receiver, where the receiver can be determined.

**Exit criterion:** the checks catch incompatible message shapes and return values in the benchmark with an acceptable false-positive rate.

### Phase 3: Test and evidence workflow (4-6 weeks)

- Integrate with ExUnit/EUnit/Common Test and property-based testing (PropEr, StreamData) to provide templates for examples, properties, message-sequence tests, and failure-injection tests.
- Provide deterministic time control for timer-driven behavior.
- Produce a **coverage-of-intent report** after a run: which declared behaviors (messages, failure paths, timeouts, restarts) were exercised, and which were not. State explicitly that passing tests are evidence, not proof.
- When a requirement is ambiguous, the AI-facing part of the tool must emit a question or recorded assumption rather than silently choosing.

**Exit criterion:** generated tests for benchmark tasks detect seeded bugs better than baseline tests, and reports are understood by reviewers.

### Phase 4: AI integration (3-4 weeks)

- Expose the summary, boundary checks, and test reports to an AI coding assistant (for example, through an MCP server or CLI) so it can read the declared behavior, propose changes, and run checks in a loop.
- Define a review gate: changes touching process interfaces, persistence assumptions, or failure handling are flagged for explicit human approval; other changes need only the summary diff.
- Ensure compiler errors and runtime traces map back to source locations, and that formatting is automatic.

**Exit criterion:** an AI assistant completes benchmark tasks using the tool, and every flagged change is visible in the review output.

### Phase 5: Evaluate with real developers (4-6 weeks)

- Run a study on real tasks with real developers, comparing: unstructured prompting, a well-tested Erlang/Elixir workflow, and the tool.
- Measure review time, escaped defects, test quality, and cost of requirement changes.
- Collect qualitative feedback on where the summaries mislead or omit information.

**Exit criterion:** a written report with results, including negative ones.

### Phase 6: Decide on a new language (go/no-go)

- Only if Phases 1-5 show that remaining problems are caused by existing syntax or compiler limits (for example, behavior cannot be declared concisely or checked soundly), design a thin language or DSL that compiles to Erlang/Elixir (Core Erlang or the BEAM) and keeps full interop.
- If the tool already delivers the benefits, keep it as tooling and do not add a language.

**Exit criterion:** a documented decision with the evidence behind it.

### Risks and mitigations

- **Summaries give false confidence:** always list unknowns and unchecked areas; never present a summary as a proof.
- **Static analysis of dynamic OTP code is incomplete:** prefer conservative reporting and runtime validation at the boundaries.
- **Generated tests are weak or wrong:** require the coverage-of-intent report and seeded-bug evaluation; review tests as code.
- **Scope creep toward a new language:** gate it behind Phase 6 evidence.
- **Tool adoption cost:** keep it usable on existing projects with no source changes in Phase 1.
