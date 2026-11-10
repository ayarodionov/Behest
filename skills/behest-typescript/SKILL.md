---
name: behest-typescript
description: "TypeScript and JavaScript specifics for the behest-contract-first workflow: Vitest and fast-check contract files, effect declarations, a fast-check disagreement check, tsc strict in the check chain, and the questions that are usually open in JS/TS code. Use together with behest-contract-first in a TypeScript or JavaScript project."
---

# Behest for TypeScript and JavaScript

Follow `behest-contract-first` for the workflow. This skill covers the TypeScript details; plain JavaScript works the same without the `tsc` step.

## Setup

```sh
npm i -D vitest fast-check typescript
```

Add `"test": "vitest run"` to `package.json`.

## Contract file

One file per module: `<name>.contract.test.ts`, next to the module. Start from `templates/contract.test.ts`.

- Examples are plain `expect` tests; use `toThrow(ErrorClass)` for invalid input.
- Properties use `fc.assert(fc.property(...))`. fast-check shrinks failures and prints the seed, so a counterexample can become a new example.
- The first line is the effects declaration: `// behest-effects: none`.
- `0` and `-0` are different under `Object.is` and equal under `===`. Decide which the contract means and write an example for it.

Run:

```sh
npx vitest run
npx tsc --noEmit --strict
scripts/effects.sh --declared <name>.contract.test.ts <name>.ts
```

(`scripts/` is in the `behest-contract-first` skill directory.) Scan the implementation files, not the tests.

## Disagreement check

Copy `templates/disagree.test.ts` to `disagree.scratch.test.ts`, write the alternative in it, and run `npx vitest run disagree.scratch.test.ts`. fast-check prints a minimal failing input; each one is a missing example. Delete the file when done. The alternative must pass the approved contract first.

## fast-check finds a lot by itself

`fc.double()` includes huge values, `-0`, infinities and subnormals, and shrinks well, so overflow bugs surface without an explicit boundary example. Still write the boundary example: it documents the decision for the human. Use `{ noNaN: true }` only where the contract rejects NaN.

## Questions that are usually open in TypeScript code

- **Failure convention:** throw (which class?), return `undefined` or `null`, a `Result` object, or a rejected promise?
- **Numbers:** only `number`, so no int/float split. NaN, `Infinity`, `-0`, precision above 2^53, `BigInt` if exact integers matter. `sort()` without a comparator sorts numbers as strings.
- **`undefined` and `null`:** which is accepted? Optional parameters versus `null`.
- **Mutation:** may the function modify its argument? `sort()`, `reverse()`, `splice()` mutate in place; `readonly` arrays only help at compile time.
- **Async:** sync or returning a `Promise`? Cancellation, ordering, unhandled rejections.
- **Types versus runtime:** types are erased. Is input from outside validated at runtime, or trusted?
- **Equality:** `===`, `Object.is`, or deep equality? Key order of objects, `Map` and `Set` iteration order.
- **Dates and time zones:** `Date` is mutable and local-time by default.

## Effects in TypeScript

Names: `send` (`postMessage`, `EventEmitter.emit`, `WebSocket`, `MessageChannel`, `.send(`), `spawn` (`Worker`, `child_process`, `cluster`), `io` (`console.`, `fs`, `fetch`, `XMLHttpRequest`, `process.stdout`, `http`), `time` (`Date.now`, `new Date()`, `setTimeout`, `setInterval`, `performance.now`), `random` (`Math.random`, `crypto.randomUUID`, `getRandomValues`), `state` (`let` at module level, `process.env`, `globalThis`, `window.`, `localStorage`). `ets` does not apply. Pass the clock and rng in as arguments to keep the core pure. The scan is a grep heuristic: aliases (`import { readFile as r }`), dynamic `require` and libraries that do I/O internally are not seen.
