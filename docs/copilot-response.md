# A *copylot* response

The strongest idea here isn’t a new syntax; it’s making the human-approved contract the thing an AI is allowed to change only with explicit review. Examples, properties, and visible assumptions seem like a practical way to make “the AI said it works” more checkable.

- **Protocols:** A good BEAM-specific place to invest, especially for request/reply shapes and message mismatches. I’d keep the first version narrow: OTP has dynamic processes, timeouts, restarts, and interop with untyped code, so the compiler should be very precise about what it can and can’t guarantee.
- **Gleam or fresh language:** I’d prototype on Gleam first, or alongside it, to test whether the contract workflow is valuable before taking on a new compiler and ecosystem. Start fresh only if OTP integration or the contract-first model proves awkward to express there.
- **Surface syntax:** I’d optimize for readable contracts and predictable diffs, not for whether it looks Elixir-like or ML-like. A small syntax that makes protocols, effects, and examples easy to review matters more than familiarity to either camp.
- **Trust:** More than code without an executable contract, yes—but not because examples or two AI implementations prove correctness. They can still share blind spots, and a weak contract can be satisfied by the wrong implementation. I’d trust it as a way to expose assumptions and catch regressions, with the assurance clearly bounded by what the checks actually cover.

The key experiment, to me, is whether real developers can review and maintain these contracts with less effort—and catch more wrong assumptions—than they do with ordinary tests and AI-generated code.
