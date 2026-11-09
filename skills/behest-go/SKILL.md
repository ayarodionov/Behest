---
name: behest-go
description: Go specifics for the behest-contract-first workflow: contract files using only the standard library (testing, testing/quick), effect declarations, a fuzz-based disagreement check, and the questions that are usually open in Go code. Use together with behest-contract-first in a Go module.
---

# Behest for Go

Follow `behest-contract-first` for the workflow. This skill covers the Go details. Everything uses the standard library, so nothing needs installing.

## Contract file

One file per package: `<name>_contract_test.go`. Start from `templates/contract_test.go`.

- Examples: a table-driven `TestExamples`, plus one test per answered question (`TestEmptyIsAnError`).
- Properties: `testing/quick` (`quick.Check`). Note that `quick` generates huge floats and arbitrary slices, which is useful: it finds overflow and empty-input bugs. Filter out NaN and Inf in the property if the contract says they are out of scope, and say so in the contract.
- The first lines are the effects declaration as a comment: `// behest-effects: none`.

Run:

```sh
go vet ./...
go test -race -count=1 ./...
scripts/effects.sh --declared <name>_contract_test.go <name>.go
```

(`scripts/` is in the `behest-contract-first` skill directory.) Exclude `_test.go` files from the effect scan; scan the implementation only.

## Disagreement check

1. Write the alternative as `altX` in `alt_scratch_test.go` (copy `templates/alt_scratch_test.go.txt`), same package, deliberately different. It must pass the approved contract first: in a scratch copy of the package, put the alternative's body in the real function and run `go test`.
2. Copy `templates/disagree_test.go` next to the package and run:

   ```sh
   go test -run XXX -fuzz FuzzDisagree -fuzztime 20s
   ```

3. The fuzzer shrinks a failure to a small input and prints both answers. Show them to the human; each one is a missing example.
4. Delete `alt_scratch_test.go`, `disagree_test.go` and `testdata/fuzz/FuzzDisagree/`. They are scratch, never committed.

The template turns bytes into small integer-valued floats, so it hits ties, zeros and negatives. Change `decode` for other input types. Fuzzing finds gaps it reaches, and two implementations from the same model can share a blind spot.

## Questions that are usually open in Go code

- **Failure convention:** return `(T, error)`, return a zero value plus `bool`, or panic? Which sentinel or error type (`errors.Is` / `errors.As`)?
- **Zero values:** is `nil` the same as an empty slice or map? (`reflect.DeepEqual(nil, []T{})` is false, which bites tests.)
- **Mutation:** may the function modify its argument, or must it copy?
- **Numbers:** integer overflow behaviour, float NaN/Inf, rounding, and whether `float64` or `int` results are wanted.
- **Concurrency:** safe for concurrent use? Run with `-race`. Who closes a channel? Is a goroutine allowed to outlive the call (leaks)?
- **Context:** does it take a `context.Context`, and what happens on cancellation?
- **Ordering:** map iteration order is random; must the output be sorted or stable?

## Effects in Go

Names: `send` (channel send `<-`), `spawn` (`go`), `io` (`os`, `net`, `fmt.Print*`, `log`), `time` (clock reads, sleeps), `random` (`rand`), `state` (package-level `var`, `sync`, `atomic`). Sentinel errors made with `errors.New` are not counted as state. Pass the clock and random source in as arguments (`now time.Time`, `*rand.Rand`) to keep the core pure, and keep the one-line wrapper that reads the real clock in a separate file that declares `time`.
