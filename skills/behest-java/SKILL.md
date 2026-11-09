---
name: behest-java
description: "Java specifics for the behest-contract-first workflow: JUnit 5 contract files with seeded random-input properties (jqwik optional), effect declarations, a disagreement-check template with a small shrinker, and the questions that are usually open in Java code. Use together with behest-contract-first in a Maven or Gradle project."
---

# Behest for Java

Follow `behest-contract-first` for the workflow. This skill covers the Java details.

## Setup

The contract needs only JUnit 5 (Jupiter), which a Maven or Gradle project already has:

```xml
<dependency>
  <groupId>org.junit.jupiter</groupId>
  <artifactId>junit-jupiter</artifactId>
  <version>5.11.4</version>   <!-- use a current version -->
  <scope>test</scope>
</dependency>
```

Properties are a seeded random loop, so there is no library to install. [jqwik](https://jqwik.net) is a good optional upgrade (`@Property`, `@ForAll`, automatic shrinking) if the project already uses it; the examples and the workflow do not change.

## Contract file

One test class per class under test: `src/test/java/<pkg>/<Name>ContractTest.java`. Start from `templates/ContractTest.java`.

- Examples are `@Test` methods with `assertEquals`; use `assertThrows` for invalid input.
- Properties are `@Test` methods looping over inputs from `new Random(<fixed seed>)`, so a failure can be replayed. Put the input in the assertion message.
- The first line is the effects declaration: `// behest-effects: none`.
- Boundary cases are explicit examples (`Double.MAX_VALUE`, `Integer.MIN_VALUE`, empty, one element). Random generators rarely reach them: in the example, two huge doubles overflowing in the mean survived 2000 random inputs.

Run:

```sh
mvn test            # or: gradle test
scripts/effects.sh --declared src/test/java/<pkg>/<Name>ContractTest.java src/main/java/<pkg>/<Name>.java
```

(`scripts/` is in the `behest-contract-first` skill directory.) Scan the implementation files, not the tests.

## Disagreement check

Copy `templates/DisagreeScratchTest.java` into the test directory, write the alternative in it, and run the tests. On a disagreement it fails with the smallest input it found and both answers; each one is a missing example. The shrinker drops one or two elements and zeroes values; adjust `randomInput` and `shrink` for other input types. An exception counts as an answer, so "throws" vs "returns" is caught. The alternative must pass the approved contract first. Delete the file when done.

## Questions that are usually open in Java code

- **Failure convention:** throw (which exception, checked or unchecked), return `Optional<T>`, or return `null`?
- **`null`:** are `null` arguments, elements or results allowed? (`List.of(...)` rejects `null`; `Arrays.asList` does not.)
- **Integer overflow:** `int` and `long` wrap silently. Use `Math.addExact` and friends, or is wrapping intended? Same for `Math.abs(Integer.MIN_VALUE)`, which is negative.
- **Floating point:** NaN, infinities, `-0.0`, `==` vs `Double.compare` vs a tolerance; `equals` on `Double` treats NaN as equal to itself.
- **Mutation:** may the method modify its argument? `List.of` is immutable, `Arrays.asList` is a fixed-size view.
- **Collections:** which `List`/`Set`/`Map` types in and out; iteration order of `HashMap`/`HashSet`; stable sort.
- **`equals` and `hashCode`:** needed for map keys and for tests that compare objects.
- **Thread safety:** immutable, synchronized, or single-threaded? Who owns shared state?
- **Generics:** `List<Double>` vs `List<? extends Number>` vs `double[]`; boxing cost and `null` elements.
- **Strings:** charset, `Locale` in case conversion and formatting.

## Effects in Java

Names: `send` (queues such as `BlockingQueue`, sockets), `spawn` (`Thread`, `ExecutorService`, `CompletableFuture`, parallel streams, `ProcessBuilder`), `io` (`System.out`, `java.io`, `java.nio.file`, `java.net`, `Files`), `time` (`System.currentTimeMillis`, `Instant.now()`, `Thread.sleep`), `random` (`Math.random`, `new Random()`, `ThreadLocalRandom`, `UUID.randomUUID`), `state` (non-final `static` fields, `Atomic*`, `volatile`, `synchronized`, `ThreadLocal`). `static final` constants of simple types are not counted. `ets` does not apply. Pass a `Clock` or a `Random` in as an argument to keep the core pure. The scan is a grep heuristic: it matches names, so static imports, reflection and library calls that do I/O inside are not seen, and any `import java.io...` is flagged even if only an exception type is used.
