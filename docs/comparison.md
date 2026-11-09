# How Behest compares to similar approaches

Behest is one answer to a question many people are working on: **if AI writes the code, what should a human review?** This page puts it next to the nearest alternatives, including where they are better. The Behest column describes both the language design (not built yet) and the [skills](../skills/) (built and tested), and says which.

## The short version

Behest's bet is a middle path: a contract that is **short, executable and frozen**, plus a loop in which the AI **asks** about unclear cases and **checks itself** for gaps. It gives up proof (like Dafny) and gives up prose (like spec-driven tools), and keeps what a human can judge quickly: concrete examples and a few properties.

| Approach | The human reviews | Checked by | Stops silent guessing? | Finds gaps in the spec? | Cost to the human |
| --- | --- | --- | --- | --- | --- |
| **Behest** | A short contract: examples, properties, effects | Running tests, hash-freeze, effect scan | Yes: `open` items fail the build | Yes: disagreement check | Low; judges concrete cases |
| Prompting and rules files (`CLAUDE.md`, Cursor rules) | The code | Nothing automatic | No | No | Reading all the code |
| Spec-driven tools (Spec Kit, Kiro, Tessl) | Markdown requirements, design, tasks | Mostly the AI itself | Partly (clarification steps) | No | Reading long documents |
| TDD or BDD with AI (unit tests, Gherkin) | The tests | Running tests | No | No | Moderate |
| Property-based testing (QuickCheck, PropEr, Hypothesis) | Properties | Random testing | No | Finds bugs, not missing intent | Writing good properties is hard |
| Design by contract (Eiffel, SPARK, specs and Dialyzer) | Pre/postconditions, types | Runtime checks or static analysis | No | No | Moderate; needs the language |
| Verification-aware languages (Dafny, Verus, Lean) | Formal specifications | A proof checker | No | Partly (the proof fails) | High; people must read formal logic |
| Typed protocols (session types) | The protocol | The type checker | n/a | Message mismatches only | Moderate; needs a research-grade type system |

## One by one

### Prompting and rules files

Telling the AI conventions in `CLAUDE.md` or a prompt is the baseline almost everyone uses. It is cheap and flexible, and it enforces nothing: the only check is a human reading the output. Behest's skills are partly this (instructions to the AI), but the important rules are **mechanical**: a hook blocks edits to approved files, and `approved.sh check` fails in CI if a contract changed.

### Spec-driven development: Spec Kit, Kiro, Tessl

These are the closest in spirit: write the spec, let the AI build. The specs are **markdown**: Kiro uses requirements with GIVEN/WHEN/THEN criteria, design and task files; GitHub's Spec Kit generates several files per feature; Tessl keeps a spec per code file with `@generate` and `@test` tags and marks generated code "do not edit". Martin Fowler's [analysis of the three](https://www.martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html) raises concerns that Behest tries to answer:

- **Review burden.** Reviewing long markdown can be harder than reviewing code, and a small bug turned into 16 acceptance criteria. Behest's contract is deliberately a few examples and properties.
- **No mechanical enforcement.** Checklists are interpreted by the AI, with "no 100% guarantee" they are followed. Behest's contract is executable and frozen by hash.
- **Non-determinism.** Regenerating from the same spec gave different code. Behest accepts that and uses it: two different implementations that both pass the contract are a *probe*, and where they differ is a missing example.

Where they are better: they cover whole features, requirements and architecture, not one function or module at a time. Behest as it stands is a unit-level tool and says little about large-scale design. The two compose: a Spec Kit plan can break work into units, and each unit gets a Behest contract.

### TDD and BDD with AI

"Write tests first, then have the AI make them pass" is the same instinct and works today. Three things differ. The AI can **edit the tests** to make a build pass unless something stops it (the hook and hash-freeze do). Nothing makes the AI **ask** about untested cases; Behest records them as `open` items that fail the build. And tests only cover cases someone thought of; the disagreement check looks for the ones nobody did. Behest's examples are ordinary tests, so the skills work with the test frameworks you already use.

### Property-based testing

QuickCheck, PropEr, StreamData, Hypothesis, `testing/quick` and proptest are a core ingredient of Behest, not a rival: properties are half of the contract. Research on [LLMs writing property-based tests](https://arxiv.org/pdf/2307.04346) suggests this is a good fit for AI. What Behest adds is the *process* around them: who approves the properties, freezing them, and an `open` list. One lesson from building the examples: random generators only find what they reach. In the Rust example a float overflow survived 100,000 random cases, and an explicit boundary example caught it. Properties complement examples; they do not replace them.

### Design by contract and static checking

Eiffel's pre/postconditions, SPARK/Ada, and on the BEAM typespecs checked by Dialyzer or eqWAlizer, state intent inside the code and check it statically or at runtime. They are strong, and they need no new process. They do not make the AI ask questions or check the spec for gaps, and they check what is written, not what is missing. Behest's `effects` declaration is a small cousin of this idea, checked here only by a grep heuristic.

### Verification-aware languages: Dafny, Verus, Lean

These give the **strongest guarantee**: a proof checker confirms the code meets a formal specification. Research on [LLMs writing verified Dafny methods](https://arxiv.org/abs/2402.00247v2) reports GPT-4 producing verified, human-checked methods for 58% of problems with an elaborate prompting strategy, but only 19% and 10% with simpler prompts. [Clover](https://arxiv.org/pdf/2310.17807) goes a step further and checks that code, formal annotations and a docstring all agree with each other, rejecting every adversarial incorrect variant in its benchmark.

Clover's consistency idea is the nearest relative of Behest's **disagreement check**: both treat agreement between independently produced artefacts as evidence, and both look for gaps. The differences are the price and the guarantee:

- **Cost to the human.** Someone has to read and trust a formal specification, which most reviewers cannot do quickly. A concrete example (`median([0, 0])` returns `0.0` or `0`?) is something almost anyone can judge.
- **Strength.** A proof covers all inputs; a Behest contract covers its examples plus what random search reaches. Behest does not claim correctness. It claims a smaller gap between intent and code.
- **Ecosystem.** Dafny and Verus are separate languages or toolchains. Behest's skills work in the languages you already use, including Erlang and Elixir where such tools barely exist.

If you need proof (cryptography, kernels, safety-critical code), use these. Behest is for the large amount of code where a proof is not worth it but "the AI said it works" is not enough either.

### Typed protocols and session types

Session types check the *conversation* between processes. Behest's language design adopts them for the BEAM; they are not in the skills, and the Elixir prototype does not implement them either. This is the least proven part of Behest. It builds on research that exists outside it, and its main open question is whether the effort is worth it compared with what Dialyzer and eqWAlizer already provide.

## What Behest does not claim

- **It is not novel in its parts.** Examples, properties, contracts, effect systems and consistency checks all exist. The contribution, if any, is the combination aimed at one problem: a human reviewing AI-written code.
- **It is not proof.** The disagreement check only finds gaps that the generator reaches, and two implementations written by the same model can share a blind spot.
- **It has not been measured.** I have run the skills on small examples (median, rate limiter, gcd), where they found real bugs, but there is no study showing that people review less or err less. Treat the design as a hypothesis.
- **The language is a design, not a compiler.** What works today is the Elixir prototype and the skills for Elixir, Erlang, Go, Rust and Julia (the Julia and Elixir property templates have not been run).

*Sources for other tools' behaviour: Martin Fowler's article above, the Clover and Dafny papers linked above, and general knowledge of Eiffel, SPARK and the property-testing libraries. I did not re-verify Eiffel, SPARK, Verus or Lean for this page, and the tools move quickly, so check their current documentation.*
