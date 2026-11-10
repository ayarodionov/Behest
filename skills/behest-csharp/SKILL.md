---
name: behest-csharp
description: "C# specifics for the behest-contract-first workflow: xUnit and FsCheck contract files, effect declarations, an FsCheck disagreement check, and the questions that are usually open in C# code. Use together with behest-contract-first in a C# project. Templates have not been run."
---

# Behest for C#

Follow `behest-contract-first` for the workflow. This skill covers the C# details.

**Status:** the templates were written from the FsCheck and xUnit documentation and were not compiled or run (NuGet was not reachable where they were written). FsCheck 2.x and 3.x differ in places; if a type or attribute name does not exist, fix the template and tell the human.

## Setup

```sh
dotnet new xunit -o tests
cd tests
dotnet add package FsCheck.Xunit
```

## Contract file

One file per class: `tests/<Name>Contract.cs`. Start from `templates/MedianContract.cs`.

- Examples are `[Fact]` tests with `Assert.Equal` and `Assert.Throws<E>`.
- Properties are `[Property]` methods; FsCheck generates the arguments from their types, shrinks failures and prints the seed (`Replay`) so a counterexample can become a new example.
- The first line is the effects declaration: `// behest-effects: none`.
- `NormalFloat` generates finite doubles only; `NonEmptyArray<T>` avoids the empty case. Use plain `double` when NaN and infinities are part of the contract.

Run:

```sh
dotnet test
scripts/effects.sh --declared tests/<Name>Contract.cs src/<Name>.cs
```

(`scripts/` is in the `behest-contract-first` skill directory.) Scan the implementation files, not the tests.

## Disagreement check

Copy `templates/DisagreeScratch.cs` into the test project, write the alternative, and run `dotnet test --filter DisagreeScratch`. Each shrunk input FsCheck prints is a missing example. Delete the file when done. The alternative must pass the approved contract first.

## Questions that are usually open in C# code

- **Failure convention:** throw (which exception type, `ArgumentException` or a custom one?), `bool TryX(out ...)`, `null`, or a result type?
- **Nullability:** are nullable reference types enabled? Is `null` accepted?
- **Numbers:** `int` overflow is unchecked by default (wraps) unless `checked`. `double`: NaN (`NaN == NaN` is false, `NaN.Equals(NaN)` is true), infinities, `-0.0`. `decimal` versus `double`.
- **Collections:** `IEnumerable<T>` may be enumerated twice, or be lazy. May the function mutate its argument (`Array.Sort` does)? Read-only interfaces are not immutable.
- **Equality and ordering:** `Equals` versus `==` on classes, structs and records; stability (`OrderBy` is stable, `Array.Sort` is not).
- **Async:** `Task` or sync? `CancellationToken`, `ConfigureAwait`, what happens to unobserved exceptions.
- **Culture:** parsing and formatting depend on the current culture unless you pass `CultureInfo.InvariantCulture`.
- **Time:** `DateTime.Kind`, `DateTimeOffset`, time zones.

## Effects in C#

Names: `send` (`Channel`, `BlockingCollection`, `ConcurrentQueue`, sockets), `spawn` (`Task.Run`, `new Thread`, `Parallel.`, `Process.Start`), `io` (`Console`, `System.IO`, `File`, `HttpClient`), `time` (`DateTime.Now`, `Stopwatch`, `Task.Delay`, `Thread.Sleep`), `random` (`new Random`, `Random.Shared`, `Guid.NewGuid`, `RandomNumberGenerator`), `state` (mutable `static` fields, `Interlocked`, `ConcurrentDictionary`, `lock`, `volatile`; `static readonly` and `const` of simple types are ignored). `ets` does not apply. Pass the clock (`TimeProvider`) and the rng in as arguments to keep the core pure. The scan is a grep heuristic: aliases, reflection and library calls that do I/O internally are not seen.
