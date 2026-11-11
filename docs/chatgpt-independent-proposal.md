I’d start with a contract layer for existing Elixir/OTP applications, then let that experience guide whether a new language is necessary.

The unit of review would be a stateful service and its observable behavior. A human approves what clients can observe; AI implements it using ordinary Elixir.

For a payment service, the contract might say:
Command: charge(account, amount, request_id)

Decisions:
  Repeating a request_id never creates another charge.
  A timeout means the outcome is unknown.
  After a restart, completed charges remain discoverable.

Scenario:
  Submit charge.
  Kill the service after payment succeeds but before it replies.
  Restart and retry with the same request_id.
  Expect one payment and the original receipt.
That makes recovery, retries, and uncertainty part of the specification from the beginning.

I’d build four things around this:
1. A decision record. Every material choice has an answer, a reason, and executable examples where possible. AI proposes defaults and highlights consequential questions. Human approval happens through ordinary code review.
2. An executable reference model. Describe states, commands, and allowed transitions in a small Elixir module. Test the implementation against that model across generated command sequences.
3. A controlled failure harness. Exercise timeouts, crashes, restarts, duplicate requests, and interrupted operations at explicit boundaries. This would be the main OTP-specific investment.
4. A review report with precise claims. Show approved behavior changes, counterexamples found, and checks performed. Distinguish static guarantees, tested properties, and assumptions about external systems.
I would also adapt your disagreement idea: ask AI to produce an implementation that passes the checks but violates a plausible intention. A concrete example: “This rate limiter passes every example, but forgets usage after restarting. Is that acceptable?” That gives the human a useful decision to make. The search would still be incomplete, but its purpose would be explicit.

The tradeoff is weaker compiler enforcement initially. You gain compatibility with existing applications and a faster way to discover whether people can write, review, and maintain these contracts.

The first milestone I’d choose: take an existing OTP service, specify its recovery behavior, and show that the tool catches a meaningful bug while reducing review effort. That would give a future Behest language a concrete foundation—and tell you which features deserve language-level enforcement.
