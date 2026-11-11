I think the central idea is strong: when AI writes the implementation, the language should make human intent easier to inspect and harder to accidentally violate. Behest takes that seriously. I’m more convinced by the contract workflow than by the need for a new language—at least so far.

What I like most:
- Explicit unresolved choices. Making open items fail the build turns uncertainty into something the team must resolve. That’s useful because an implementation can be perfectly reasonable and still encode the wrong product decision.
- Examples alongside broader properties. Humans can judge concrete cases, while properties express rules that should survive implementation changes.
- Declared effects and process protocols. These give reviewers a compact description of what code can do and how processes interact. Those are promising foundations for reviewing generated code. Design
My biggest concern is the README’s claim that “the compiler guarantees the rest matches.” Randomized properties and examples provide evidence; they don’t establish that every possible behavior matches the contract. Static types and effect checks can guarantee particular constraints, but the boundary needs to be very clear. Otherwise the language risks making people more confident than its checks justify. README

For OTP specifically, I’d push the design hardest on failure behavior. A useful contract should answer questions like:
- A caller times out—can the operation still complete?
- A process restarts—which state survives?
- A request is retried—can it apply twice?
- A mailbox grows faster than it drains—what happens?
These are the cases I’d want Behest to make easy to express and test. Checking message shapes is valuable, but I’d want convincing examples of how protocol checks handle lifecycle and failure. The design already acknowledges that multiprocess deadlock proofs and protocol changes during upgrades remain outside its current guarantees. Design

The two-implementation disagreement check is particularly interesting. I’d treat it as a tool for discovering questions, with no implication that agreement establishes correctness. Two implementations can share the same assumption.

My next step would be to use the Elixir prototype on one real stateful service, introduce ambiguous requirements and failure scenarios, and measure human review time, missed requirements, and bugs that escape. Your README’s reported findings on existing libraries make that direction especially interesting, though the experiments remain preliminary. Reported results

My judgment: keep pursuing it. The strongest contribution could be a practical way to turn human decisions into durable, executable constraints. Let experience with that workflow show which guarantees genuinely require a new language.
