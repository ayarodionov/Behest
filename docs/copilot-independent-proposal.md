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

## A staged plan for building the language and tool

1. **Set a baseline and success criteria.** Choose a small set of representative OTP tasks and record how developers currently specify, implement, test, and review them. Define measures up front: review effort, defects found or missed, test quality, and the cost of changing a requirement.
2. **Prototype the workflow before inventing syntax.** Use existing Erlang or Elixir projects to try concise contracts, concrete examples, properties, and explicit unresolved questions. Check that the workflow exposes assumptions and produces useful tests without requiring a new language or compiler.
3. **Specify the smallest useful language slice.** Use what the workflow teaches to define syntax and semantics for one process boundary: messages and replies, owned state, failure behavior, allowed effects, and relevant timing. Write down what the compiler can guarantee and what remains a runtime or human-review concern.
4. **Build one end-to-end vertical slice.** Implement a parser and checker for that slice, then generate ordinary OTP-compatible code with useful source locations and inspectable output. Start with one common process pattern and one protocol; make unresolved decisions and invalid contracts clear build failures rather than silently choosing behavior.
5. **Validate runtime behavior and interop.** Run examples and properties deterministically, including message sequences, failures, timeouts, and restart behavior. Compile and exercise the generated code with existing Erlang and Elixir libraries, and verify that diagnostics and runtime traces lead back to the contract and generated source.
6. **Evaluate with developers and decide whether to expand.** Compare the tool with a well-tested Erlang or Elixir workflow on the same tasks. Use the predefined measures to find where it helps and where it adds friction. Expand the language only if it improves review and maintenance enough to justify its compiler, tooling, learning, and interop costs; otherwise, keep the useful workflow as tooling for existing OTP languages.
7. **Harden only the validated parts.** After the core approach shows value, improve editor support, formatting, documentation, reproducible generation, and compatibility. Keep generated code replaceable and make changes to contracts and externally visible behavior easy to review.
