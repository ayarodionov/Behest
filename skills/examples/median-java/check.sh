#!/usr/bin/env bash
# Runs the whole check chain for this example: the same checks the skill asks Claude to run.
# Needs a JDK (17+) and the JUnit 5 console launcher jar. On Debian/Ubuntu:
#     apt install junit5        # provides /usr/share/java/junit-platform-console-standalone.jar
# Elsewhere, set JUNIT_CONSOLE to a junit-platform-console-standalone jar.
# (Under Maven or Gradle the same test class runs with the junit-jupiter dependency.)
set -euo pipefail
cd "$(dirname "$0")"
S=../../behest-contract-first/scripts
JUNIT="${JUNIT_CONSOLE:-/usr/share/java/junit-platform-console-standalone.jar}"
[ -f "$JUNIT" ] || { echo "JUnit console jar not found: $JUNIT (set JUNIT_CONSOLE)" >&2; exit 2; }
OUT=_build_example

echo "--- open items";     "$S/check_open.sh"
echo "--- approved files"; "$S/approved.sh" check
echo "--- compile"
rm -rf "$OUT" && mkdir -p "$OUT"
javac -Xlint:all -d "$OUT" -cp "$JUNIT" $(find src -name '*.java') 2>&1 | grep -v '^Picked up' && true
echo ok
echo "--- contract"
java -jar "$JUNIT" execute --class-path "$OUT" --scan-class-path --disable-banner --details=summary 2>&1 \
  | grep -v '^Picked up' | grep -E "tests (successful|failed)|MethodSource|=>|Caused" || true
java -jar "$JUNIT" execute --class-path "$OUT" --scan-class-path --disable-banner --details=none >/dev/null 2>&1
echo "--- effects"
"$S/effects.sh" --declared src/test/java/example/MedianContractTest.java src/main/java/example/Median.java
echo "all checks passed"
