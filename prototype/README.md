# Behest prototype (Elixir macros)

A first, dependency-free prototype of Behest's contracts as an Elixir library. It tests whether "contract next to code, checked at compile time" feels good to use, before writing a real parser.

## What it does

`defspec` defines a function together with its contract. **The build fails** when:

- an **example** does not hold,
- a **property** finds a counterexample (100 random cases),
- the implementation uses an **effect** it did not declare.

```elixir
defmodule Stats do
  use Behest

  defspec median(xs) do
    examples do
      median([3.0, 1.0, 2.0]) == {:ok, 2.0}
      median([4.0, 1.0, 3.0, 2.0]) == {:ok, 2.5}
      median([]) == {:error, :empty}
    end

    property "order does not matter", xs: list_of(float()) do
      median(xs) == median(Enum.shuffle(xs))
    end

    implementation do
      # ... AI-written ...
    end
  end
end
```

A wrong implementation stops the build:

```
** (CompileError) examples/stats.ex:7: example failed for median/1:
    median([4.0, 1.0, 3.0, 2.0]) == {:ok, 2.5}
  got:      {:ok, 3.0}
  expected: {:ok, 2.5}
```

So does an undeclared side effect:

```
** (CompileError) examples/rate_limit.ex:9: check/5 uses effects it does not declare:
  :io (from IO.puts)
declared: []
```

## Try it

```sh
cd prototype
mix test
```

Examples: [`examples/gcd.ex`](examples/gcd.ex) (the smallest complete one: edge-case examples plus properties that define "greatest common divisor"), [`examples/stats.ex`](examples/stats.ex), [`examples/rate_limit.ex`](examples/rate_limit.ex).

## Contract blocks

| Block | Meaning |
| --- | --- |
| `examples do ... end` | One expression per line, usually `call == expected`; all must hold |
| `property "name", var: generator do ... end` | Must return `true` for 100 random inputs |
| `effects [:time, :io]` | Side effects the implementation may use; none means pure |
| `open "question"` | Something the human has not decided. **The build fails until it is answered**, so the AI has to ask instead of guess |
| `implementation do ... end` | The function body |

**Generators:** `integer()`, `positive_integer()`, `float()`, `boolean()`, `atom()`, `binary()`, `constant(v)`, `member_of(list)`, `one_of(gens)`, `list_of(g)`, `nonempty_list_of(g)`, `tuple({g1, g2})`.

**Effects detected:** `:send`, `:spawn`, `:ets`, `:io`, `:time`, `:random`. Calling another `defspec` brings its declared effects along.

An unanswered `open` stops the build and lists every question:

```
** (CompileError) unresolved open items. Ask the human; answer each with an example or property, then delete its `open` line:
  median/1 (line 4): "NaN handling: skip, error, or propagate?"
```

A failing property prints its seed; rerun with `BEHEST_SEED=<n> mix compile --force` to reproduce.

## Known limits

- No shrinking: counterexamples are reported as found.
- The effect scan is syntactic and covers common calls only; plain `def` helpers aren't scanned.
- No protocols, processes or virtual clock yet. Those need the real compiler (phase 3 of the [design](../docs/design.md)).
- No "approved by a human" marker on examples yet.
- No disagreement check yet (two implementations that pass the contract but differ reveal a missing example; see [design, section 4](../docs/design.md)).
