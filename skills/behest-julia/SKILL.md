---
name: behest-julia
description: "Julia specifics for the behest-contract-first workflow: contract files using the Test standard library, a random-input property loop, effect declarations, a disagreement-check template with simple shrinking, and the questions that are usually open in Julia code. Use together with behest-contract-first in a Julia package."
---

# Behest for Julia

Follow `behest-contract-first` for the workflow. This skill covers the Julia details. The templates use only the standard libraries `Test` and `Random`, so nothing needs installing. (Supposition.jl is a good property-testing package if the project already uses it; it shrinks automatically.)

**Status:** the templates here have not been run (no Julia was available where they were written). Run them in your project before relying on them; the effect scan for `.jl` files was tested.

## Contract file

One file per module: `test/<name>_contract.jl`, included from `test/runtests.jl`. Start from `templates/contract.jl`.

- Examples: `@testset` with `@test`; use `@test_throws` for invalid input.
- Properties: a loop over random inputs from a seeded `MersenneTwister` (`Random.seed!` or an explicit rng), so a failure is reproducible.
- The first line is the effects declaration: `# behest-effects: none`.

Run:

```sh
julia --project -e 'using Pkg; Pkg.test()'
scripts/effects.sh --declared test/<name>_contract.jl src/<name>.jl
```

(`scripts/` is in the `behest-contract-first` skill directory.)

## Disagreement check

Copy `templates/disagree.jl` to a scratch directory and write the alternative as `alt_<name>` (deliberately different; it must pass the approved contract first: `include` the contract against the alternative in a scratch module). Run `julia --project scratch/disagree.jl`. The template shrinks a failing vector by dropping elements and halving values, so you show the human a small input. Delete the scratch files when done.

## Questions that are usually open in Julia code

- **Failure convention:** throw (`ArgumentError`, `DomainError`, a custom exception), return `nothing`/`missing`, or return a default?
- **Numeric types:** what does `median([1, 2])` return, `1.5` or something that depends on the element type? Integers in, integer out? Should the result type be stable (`Float64`) whatever the input?
- **Tolerance:** `==` or `isapprox` (and which `rtol`/`atol`)? Floating-point sums depend on order.
- **NaN, Inf and `missing`:** propagate, error, or skip?
- **Mutation:** `f` or `f!`? An in-place function must say so in its name and in the contract; a non-mutating one must not change its argument (`sort` vs `sort!`).
- **Indexing:** 1-based only, or `OffsetArrays` allowed? `eachindex` vs `1:length`?
- **Array types:** accept any `AbstractVector`, or just `Vector{Float64}`? Views and ranges?
- **Type stability and allocation:** is performance part of the contract (`@inferred`, `@allocated`)?
- **Multiple dispatch:** which argument types must have methods, and what should a call with any other type do (`MethodError` is acceptable if the contract says so).

## Effects in Julia

Names: `send` (`put!`, `take!`, `Channel`, `remotecall`), `spawn` (`@spawn`, `@async`, `@threads`, `Task`), `io` (`println`, `open`, `read`/`write`, `@info`, `run`, `HTTP`), `time` (`time()`, `now()`, `sleep`, `@time`), `random` (`rand`, `randn`, `shuffle`, `Random.`), `state` (`global`, `Ref`, `ENV`). `ets` does not apply. Pass the clock and rng in as arguments to keep the core pure. The scan is a heuristic: it matches names, so a local function called `open` or `time` is flagged and a call through an alias is missed.
