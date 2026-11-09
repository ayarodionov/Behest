# Walkthrough: from request to approved contract

A worked example of how Behest is meant to be used, with `median` as the task. The human writes a few lines; the AI asks about whatever the contract leaves open; the human answers with examples. The human never writes the implementation.

Steps 1, 2 and 4 run in the [prototype](../prototype/) today. Step 3 (the disagreement check) is design only; the output shown comes from a throwaway script, not from the prototype.

## 1. The human writes a request and a first contract

In plain words: *"I need the median of a list of numbers."* The human turns that into a contract, and marks the one thing they know is undecided:

```elixir
defspec median(xs) do
  open "empty list: error, or some default?"

  examples do
    median([3.0, 1.0, 2.0]) == {:ok, 2.0}
  end
end
```

The AI is asked to write the `implementation`. Whatever it writes, the build now stops:

```
unresolved open items. Ask the human; answer each with an example or property, then delete its `open` line:
  median/1 (line 2): "empty list: error, or some default?"
```

## 2. The AI asks; the human answers with an example

The AI does not pick an answer. It comes back with a question:

> **AI:** Your contract leaves the empty list open. Options: return an error, or return a default such as 0. Which do you want?
>
> **Human:** An error.

The answer becomes an example, and the `open` line is deleted:

```elixir
examples do
  median([3.0, 1.0, 2.0]) == {:ok, 2.0}
  median([]) == {:error, :empty}
end
```

The build passes. The contract has grown by one line, and that line is now checked on every build.

## 3. The check finds a gap the human did not know about

The contract still has a hole: nothing says what an *even-length* list should give. The human never thought of it, so there was no `open` to mark.

The toolchain asks the AI for two different implementations that both pass the contract, then compares them on random inputs. Here is a real run of that idea (a throwaway script today):

```
A passes the contract: true      # lower middle value for even lengths
B passes the contract: true      # mean of the two middle values
disagree on: [1, 0]
  A -> {:ok, 0}
  B -> {:ok, 0.5}
```

Both are valid under the current contract, and they disagree. That input is a missing example. The AI shows it to the human:

> **AI:** Two correct-looking implementations disagree on `[1, 0]`: one returns 0, the other 0.5. Which is right?
>
> **Human:** 0.5, the mean of the two middle values.

The human's answer is added as an approved example, plus a property that states the general rule:

```elixir
examples do
  median([3.0, 1.0, 2.0]) == {:ok, 2.0}
  median([]) == {:error, :empty}
  median([1, 0]) == {:ok, 0.5}
end

property "order does not matter", xs: list_of(float()) do
  median(xs) == median(Enum.shuffle(xs))
end
```

Implementation A now fails the build (`example failed for median/1`), so it can never come back. Only implementations that agree with the human survive.

## 4. The result

```elixir
defspec median(xs) do
  examples do
    median([3.0, 1.0, 2.0]) == {:ok, 2.0}
    median([]) == {:error, :empty}
    median([1, 0]) == {:ok, 0.5}
  end

  property "order does not matter", xs: list_of(float()) do
    median(xs) == median(Enum.shuffle(xs))
  end

  implementation do
    # AI-written; can be regenerated at any time as long as the contract holds
  end
end
```

The human wrote about ten lines and answered two questions. Each answer is a concrete case, which people are good at judging, and each one is now permanent and executable.

## What works today

| Step | Status |
| --- | --- |
| `open` blocks the build and lists the questions | Works in the prototype |
| Examples and properties fail the build with a clear message | Works in the prototype |
| The AI asks the human instead of guessing | Depends on the AI; `open` forces it for known gaps |
| Disagreement check between two implementations | Design only ([design, section 4](design.md)); throwaway script above |
| Marking examples as human-approved so the AI can't edit them | Not built yet |
