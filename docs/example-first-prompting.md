# Example-First Prompting

The working method that led to Behest.

## The idea

You write the problem in plain language, as usual. The AI does the formal work: before coding, it shows how it understood you as a few concrete input → output examples, especially the tricky ones. You just say yes or no.

People are bad at writing precise specs, but very good at spotting a wrong answer to a concrete case. One wrong example exposes a misunderstanding faster than a page of rules.

1. Describe the task in normal words.
2. Read the AI's examples. Correct any that are wrong.
3. Let it code. Your approved examples become its tests.

## The prompt

Add this line after your task description:

```
Before coding, show me 5 input → output examples that reveal how you understood this, especially edge cases, and wait for my OK.
```

## Example: Julia

**You:** Write a Julia function that passes bits through a binary symmetric channel with flip probability p.

**AI:**

```
bsc([1,0,1,1], 0.0)   →  [1,0,1,1]        # p=0: unchanged copy
bsc([1,0,1,1], 1.0)   →  [0,1,0,0]        # p=1: all flipped
bsc([], 0.3)          →  []
bsc(bits, 0.7)        →  DomainError      # I assume p must be ≤ 0.5
same seed twice       →  same output; input not modified
```

**You:** p up to 1.0 is fine, don't throw. Rest OK.

## Example: Elixir

**You:** Write a GenServer that limits each client to 3 requests per second.

**AI:**

```
t=0ms     check(:a) ×3   →  :ok, :ok, :ok
t=10ms    check(:a)      →  {:error, :rate_limited}
t=10ms    check(:b)      →  :ok                       # clients independent
t=1001ms  check(:a)      →  :ok                       # sliding window
t=1001ms  check(:a)      →  {:error, :rate_limited}   # only one slot freed
```

**You:** I wanted a fixed window: at t=1000ms all 3 slots reset.

The prose "3 per second" fits both readings. The examples made the difference visible at once.

## Fallback: the three-line card

When you already know the tricky cases, write them yourself:

```
WANT:     what it does, in plain words
EXAMPLES: 3–5 input → output pairs, including one weird case
UNSURE:   anything you haven't decided (the AI asks, never guesses)
```

## From method to language

Behest turns this method into syntax: the approved examples live next to the code, and the compiler runs them on every build.
