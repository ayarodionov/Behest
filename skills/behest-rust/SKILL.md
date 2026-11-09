---
name: behest-rust
description: "Rust specifics for the behest-contract-first workflow: cargo integration-test contract files with proptest properties, effect declarations, a proptest-based disagreement check, and the questions that are usually open in Rust code. Use together with behest-contract-first in a Cargo project."
---

# Behest for Rust

Follow `behest-contract-first` for the workflow. This skill covers the Rust details.

## Setup

Contracts use plain `#[test]` functions plus [proptest](https://crates.io/crates/proptest) for properties. Add it as a dev-dependency:

```toml
[dev-dependencies]
proptest = "1"
```

Add `Cargo.lock` handling and `/target` to `.gitignore` as usual, and `*.proptest-regressions` for scratch files.

## Contract file

One integration-test file per crate or module: `tests/<name>_contract.rs`. Start from `templates/contract.rs`. Integration tests only see the public API, which is what a contract should cover.

- Examples are `#[test]` functions with `assert_eq!`.
- Properties are `proptest!` blocks. proptest shrinks failures automatically.
- The first line is the effects declaration: `// behest-effects: none`.

Run:

```sh
cargo test
cargo clippy -- -D warnings          # optional
scripts/effects.sh --declared tests/<name>_contract.rs src/lib.rs
```

(`scripts/` is in the `behest-contract-first` skill directory.) Scan the implementation files, not the tests.

## Know what the random generator reaches

proptest's float strategies spread exponents widely, so two huge same-sign values in the middle of a vector almost never occur: in the example, a naive `(a + b) / 2` overflow survived 100,000 random cases. Boundary cases are therefore **explicit examples** in the contract (`f64::MAX`, `i32::MIN`, empty, one element), not something to hope the properties find. Go's `testing/quick` happened to find the same bug on its own because its generator is different.

## Disagreement check

Copy `templates/disagree.rs` to `tests/disagree_scratch.rs`, write the alternative in it, and run `cargo test --test disagree_scratch`. proptest prints a minimal failing input and both answers; each one is a missing example. Delete the file and any `.proptest-regressions` when done. The alternative must pass the approved contract first.

## Questions that are usually open in Rust code

- **Failure convention:** `Result<T, E>`, `Option<T>`, or panic? Which error type: a dedicated enum (as in the example) or `String`/`Box<dyn Error>`?
- **Ownership:** take `&[T]`, `Vec<T>` or `impl IntoIterator`? Does the function consume its input?
- **Integer overflow:** panics in debug and wraps in release unless checked. Should the function use `checked_*`, `wrapping_*` or `saturating_*`?
- **Floats:** NaN, infinities, `-0.0`, and whether results are compared exactly or within a tolerance.
- **Ordering and hashing:** `HashMap` iteration order is random; must the output be sorted?
- **`unsafe`:** allowed? If not, add `#![forbid(unsafe_code)]` to the crate; it is stronger than any grep.
- **Concurrency:** `Send`/`Sync` bounds, who owns shared state, blocking vs async.
- **Allocation and performance:** is it part of the contract?

## Effects in Rust

Names: `send` (channels: `mpsc`, `.send()`, `.recv()`), `spawn` (`thread::spawn`, `tokio::spawn`, rayon), `io` (`std::fs`, `std::io`, `std::net`, `std::process`, `println!`), `time` (`Instant::now`, `SystemTime::now`, `sleep`), `random` (`rand`, `getrandom`), `state` (`static mut`, `Mutex`, `RwLock`, `Atomic*`, `RefCell`, `OnceLock`, `thread_local!`). `ets` does not apply. Pass the clock and rng in as arguments to keep the core pure. The scan is a grep heuristic: it matches names, so `use` aliases and macros that expand to I/O can slip through, and `Arc<` is flagged even when it only shares immutable data.
