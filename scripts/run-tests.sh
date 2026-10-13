#!/usr/bin/env bash
# Regression suite (runs inside the Docker image): compile each test program, run it on the
# MicroJava VM with scripted input and compare the output with scripts/expected/<name>.out.
#
#   run-tests.sh [log dir]
set -uo pipefail

cd /mjc
LOGS="${1:-/tmp/mj-test-logs}"
mkdir -p "$LOGS"
EXP=scripts/expected
pass=0 fail=0

check() {  # check <name> <source file>
  local name=$1 src=$2 input=/dev/null
  [[ -f "$EXP/$name.in" ]] && input="$EXP/$name.in"
  scripts/mjc.sh --verbose "$src" < "$input" > "$LOGS/$name.log" 2>&1
  # The VM prints "Completion took N ms": timing varies, so drop it before comparing.
  sed -n '/^mjc: running on the MicroJava VM/,$p' "$LOGS/$name.log" | tail -n +2 \
    | grep -v '^Completion took' > "$LOGS/$name.actual"
  if diff -u "$EXP/$name.out" "$LOGS/$name.actual" > "$LOGS/$name.diff"; then
    echo "PASS  $name"; pass=$((pass + 1))
  else
    echo "FAIL  $name  (see $name.diff)"; cat "$LOGS/$name.diff"; fail=$((fail + 1))
  fi
}

xfail() {  # xfail <name> <source file> <reason>: must be rejected by the compiler
  local name=$1 src=$2 reason=$3
  if scripts/mjc.sh --verbose --no-run "$src" > "$LOGS/$name.log" 2>&1; then
    echo "FAIL  $name  (expected to be rejected: $reason)"; fail=$((fail + 1))
  else
    echo "XFAIL $name  ($reason)"; pass=$((pass + 1))
  fi
}

check program  test/program.mj
check test301  tests/test301.mj
check test302  tests/test302.mj
xfail test303  tests/test303.mj "classes are parsed but not semantically supported"

echo "---"
echo "$pass passed, $fail failed  (logs: $LOGS)"
[[ $fail -eq 0 ]]
