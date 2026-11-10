---
name: behest-python
description: "Python specifics for the behest-contract-first workflow: pytest and Hypothesis contract files, effect declarations, a Hypothesis-based disagreement check, mypy in the check chain, and the questions that are usually open in Python code. Use together with behest-contract-first in a Python project."
---

# Behest for Python

Follow `behest-contract-first` for the workflow. This skill covers the Python details.

## Setup

```sh
pip install pytest hypothesis mypy
```

Add `.hypothesis/`, `.pytest_cache/` and `.mypy_cache/` to `.gitignore`. In `pytest.ini` set `pythonpath = .` (or your `src` directory) so tests can import the module.

## Contract file

One file per module: `tests/test_<name>_contract.py`. Start from `templates/contract_test.py`.

- Examples are plain `assert` tests; use `pytest.raises` for invalid input.
- Properties use Hypothesis `@given`. Hypothesis shrinks failures and remembers them in `.hypothesis/`, so a counterexample found once is replayed.
- The first line is the effects declaration: `# behest-effects: none`.
- Examples in docstrings must be run (`python -m pytest --doctest-modules`) or left out.
- Assert **result types** where they matter: `type(median([1, 2, 3])) is float`. Python's `0 == 0.0` and `True == 1` hide type differences, so compare `type(x)` as well as the value.

Run:

```sh
python -m pytest
mypy --strict <package or module>
scripts/effects.sh --declared tests/test_<name>_contract.py <name>.py
```

(`scripts/` is in the `behest-contract-first` skill directory.) Scan the implementation files, not the tests.

## Disagreement check

Copy `templates/disagree_test.py` to `tests/test_disagree_scratch.py`, write the alternative in it, and run `python -m pytest tests/test_disagree_scratch.py`. Hypothesis prints a minimal failing input and both answers; each one is a missing example. The template compares `(type(a), a)` so that `0` vs `0.0` counts as a disagreement. Delete the file and `.hypothesis/` when done. The alternative must pass the approved contract first.

## Hypothesis finds a lot by itself

Unlike some other generators, `st.floats(allow_nan=False, allow_infinity=False)` includes huge values and shrinks to a tiny example, so overflow bugs surface without an explicit boundary example. Still write the boundary example: it documents the decision for the human.

## Questions that are usually open in Python code

- **Failure convention:** raise (which exception class, and is it a subclass of a builtin such as `ValueError`?), return `None`, or return a default?
- **Result types:** `int` or `float`? A list or a generator? A tuple or a list? Must the type be stable whatever the input type?
- **`None` and falsy values:** `if not xs` treats `[]`, `None`, `0` and `""` alike. Is `None` accepted?
- **Mutation:** may the function modify its argument, or must it copy? Watch for mutable default arguments (`def f(x, acc=[])`) and in-place `sort()`.
- **Numbers:** NaN, infinities, overflow to `inf` (floats do not raise), exact vs tolerance comparison (`math.isclose`), `Decimal` or `Fraction`.
- **Duck typing:** any iterable, or only `list`? Sequences vs generators (a generator can be consumed once).
- **Ordering and hashing:** dict and set iteration order; stable sort; unhashable inputs.
- **Concurrency and async:** thread safety, `async def` vs plain, cancellation.
- **Type hints:** are they part of the contract (checked by `mypy --strict`) or advisory?

## Effects in Python

Names: `send` (`queue`, `socket`, `.send()`/`.recv()`), `spawn` (`threading`, `multiprocessing`, `subprocess`, `concurrent.futures`, `asyncio.create_task`), `io` (`print`, `open`, `os.`, `sys.`, `pathlib`, `requests`, `logging`), `time` (`time.time`, `sleep`, `datetime.now`), `random` (`random.`, `secrets`, `uuid4`), `state` (`global`, module-level `[]`/`{}`, mutable default arguments, `lru_cache`, `os.environ`). `ets` does not apply. Pass the clock and rng in as arguments to keep the core pure. The scan is a grep heuristic and weaker in Python than in compiled languages: dynamic imports, aliases (`import os as o`) and library calls that do I/O internally are not seen.
