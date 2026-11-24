# Tutorial: your first session, and best practice

A short guide for the person using the skills, for new code and for [code you already have](#code-you-already-have). The [walkthrough](WALKTHROUGH.md) shows a full session with the real output of every command; this page is the version to read first.

## Before you start (once per project)

1. **Install** `behest-contract-first` and the skill for your language into `<project>/.claude/skills/` ([install](README.md#install)). Prefer the project install over `~/.claude/skills/`: then the scripts are in the repo, your team gets the same skills, and CI can run them.
2. **Add the edit-blocking hook** to `.claude/settings.json` ([enforcement, step 2](README.md#enforcement-optional-recommended)). Without it the skills are only advice.
3. **Add two lines to CI**, so the rules hold even when nobody is watching:

   ```sh
   .claude/skills/behest-contract-first/scripts/check_open.sh
   .claude/skills/behest-contract-first/scripts/approved.sh check
   ```

4. **Add `.behest-scratch/` to `.gitignore`.** The disagreement check writes its second implementation there.
5. **Start a new Claude Code session** so the skills are picked up.

## Your first session

**1. Ask for something small and a little ambiguous.** Name the module and function, and say what it does in one sentence. Do not try to settle every detail: finding the gaps is the skill's job.

> I need a median function in Erlang. Module `median`, function `median/1`, takes a list of numbers.

**2. Claude names a tier and sends one message.** It does not write code yet. The message has three parts:

- a few numbered **questions**, each with Claude's proposal first;
- a list headed **"I will also assume, unless you object"**;
- **cases** generated from the contract's properties, showing what the contract will demand.

> **Question:** 1. `median([])` -> `{error, empty}`, or a default such as `{ok, 0}`?
>
> **I will also assume, unless you object:** `median([5.0])` -> `{ok, 5.0}`; the input order does not matter; a list containing a non-number crashes, with no special error.

**3. Reply once.** `ok` accepts every proposal and approves the contract. To change something, give the number or the case: `1: return {ok, 0.0}`, or `non-numbers: return {error, badarg}`.

**4. Claude freezes the contract, implements and checks.** In the standard tier it records the contract's hash with `approved.sh`, writes the code, and runs the effect scan, the mutation check and, when there is no reference model, the disagreement check. If the disagreement check finds an input where two valid implementations differ, you get one more question about that case.

**5. Read the report.** It always has the same headings: *Your answers*, *Defaults*, *Pinned without asking*, *Checks*, *Not pinned*. The last two you have not seen before, so read them.

## Code you already have

The skills also work on existing programs, and `behest-contract-first` has its own steps for this case. Here the order is reversed: the code exists, and the contract records what it does, so you can decide what it *should* do. The real bugs found so far came from this, in two existing Elixir libraries ([elx_vast](https://github.com/ayarodionov/elx_vast) and [Exfoil](https://github.com/ayarodionov/exfoil)).

**1. Pick one module or function and start from a clean working tree.** Good first choices: code that is about to change, code with few tests, or code whose behaviour people disagree about. Do not start with the whole program.

**2. Ask Claude to record the code before changing it.**

> Use the Behest contract-first workflow on the existing `Parser.parse/1` in `lib/parser.ex`. Do not change the code yet. Write a contract that records what it does now: examples, properties and effects. Put every behaviour that looks surprising in `OPEN.md` as a question: bug to fix, or rule to keep?

**3. Claude reads the code and probes it.** It writes examples for the normal cases and properties for the general rules, then looks for the surprising cases. Two checks are especially useful here:

- **Disagreement check:** the existing code is one side, and a plain reference model or a second implementation is the other. Each input where they differ is either a bug or a case nobody decided.
- **Effect scan:** declare what the code is supposed to touch and run `effects.sh`. An effect you did not expect, such as a clock read or a write to ETS, is a finding in itself.

**4. You decide each surprising case.** You get the same single message as for new code, but each question now reads "today `parse("")` returns `nil`: keep it, or should it be `{:error, :empty}`?"

- **Rule to keep:** the example records the current behaviour and passes.
- **Bug:** the example records the behaviour you want, marked with a comment such as `fix: was nil`, and fails for now.

Callers may already depend on odd behaviour, so "keep" is often the right answer. The point is that it becomes a choice someone made on purpose.

**5. Freeze the contract, then fix.** Approve the contract first. Fixing the bugs is a separate step: Claude makes the failing examples pass without touching the frozen contract, and every other recorded behaviour stays as it was. From then on the contract guards the code against regressions, whoever changes it next.

Some tips:

- **Keep recording and fixing apart.** If Claude fixes things while it records them, the contract describes the fixed code and you never get to see the old behaviour or decide on it.
- **Keep your existing tests.** The contract comes in addition to them, not instead.
- **Run the mutation check on the old code.** It shows how much of the code the contract (and your old tests) actually pins down, before anyone changes it.
- **Less tested than new code.** The experiment only measured new functions. For existing code the evidence is the two libraries above.

## Best practice

### When you ask

- **Let Claude pick the tier, then check its choice.** It says which tier and why in its first message, and you can change it. Use **light** for code that is cheap to redo: in the experiment it got 26 of 26 decisions right at the same agent time as a plain prompt. Ask for **strict** for money, security, data loss, concurrency or an API that cannot change later.
- **Skip the skills when the obvious answer is the one you want.** On ordinary tasks a plain prompt got 63 of 69 decisions right, at about a fifth of the cost. The skills pay off when you want something unusual: there a plain prompt missed choices it never mentioned (46 of 52, against 52 of 52).
- **Use it on existing code too.** Record what the code does, decide each surprising case, then fix ([above](#code-you-already-have)).

### When you answer

- **Read the assumptions, not only the questions.** In the experiment about half of the unusual things the human wanted were caught in the "I will also assume" list. A default you skim past is a decision you made without noticing.
- **Answer with a case, not a rule.** `median([1, 2]) -> 1.5` becomes an example in the contract as it stands. "Use the usual definition" leaves Claude to guess again.
- **Look at the generated cases.** They show a wrong reference model, or a generator that only makes trivial inputs, before anything is frozen. One template first printed almost only one-element lists; the cases made that obvious.
- **Ask for extreme values as explicit examples.** Random inputs miss edges: a float overflow in `(a + b) / 2` survived 100,000 random proptest cases in Rust and 2,000 in Java. It was only caught by an example with two huge numbers. If your inputs have limits (huge numbers, empty or very long strings, NaN), name them.
- **Keep the questions few.** The skill aims for at most five. If you get more, saying "your choice" to the minor ones is fine; they then show up under *Defaults* in the report.

### After the contract is frozen

- **You unlock, never Claude.** If Claude says the contract is wrong, it must show you a concrete input. If you agree, run `approved.sh unlock <file>`, edit or let Claude edit, then `approved.sh approve <file>` again. The skill tells Claude never to run `approve` or `unlock` unless you asked it to in that conversation.
- **Treat each surviving mutant as a possible missing example.** In the `median` examples, changing the middle index from `n / 2` to `n / 3` survived, because no example had an odd length of five or more. A five-element example and one more property closed the gap.
- **For processes, pass the clock in.** Make time a command the contract issues instead of something the code reads. Then the tests never sleep, the effect line can forbid the real clock, and failures shrink to short scripts such as `put(a, 6, ttl 1); advance 1; get(a)`. See [`examples/ttl-cache-erlang`](examples/ttl-cache-erlang/).
- **Run untested templates once before relying on them.** The Kotlin, C#, Scala and Gleam templates were written from documentation and never run; expect small API differences ([status](STATUS.md)).

### What not to expect

- **Not a proof.** The disagreement check only finds gaps that random inputs reach, and two implementations from the same model can share a blind spot. The effect scan is a grep. The mutation check only makes simple text changes.
- **The hook does not see shell commands.** `sed -i` on a frozen file gets past it; `approved.sh check` in CI catches it.
- **Not measured with real people yet.** In every run so far an AI played the human. Your own time spent reading and answering is the cost that has not been measured.

## Checklist

- [ ] Skills installed in the project, hook added, `check_open.sh` and `approved.sh check` in CI
- [ ] Tier named in Claude's first message, and you agree with it
- [ ] Questions answered with cases
- [ ] "I will also assume" list read line by line
- [ ] Generated property cases look like real inputs
- [ ] Extreme values covered by explicit examples
- [ ] Report read, especially *Pinned without asking* and *Not pinned*
