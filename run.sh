#!/usr/bin/env bash
# One-command entry point. Needs only Docker.
#
#   ./run.sh                 compile + run the main demo (tests/test302.mj)
#   ./run.sh 301|302|program compile + run another bundled test program
#   ./run.sh path/to/x.mj    compile + run your own MicroJava program (interactive read())
#   ./run.sh test            run the regression suite
#   ./run.sh shell           shell inside the toolchain container
#
#   Options before the program: --verbose (tokens, syntax tree, symbol table), --disasm (bytecode)
set -euo pipefail
cd "$(dirname "$0")"

IMAGE=pp1-mjc
echo "Building the compiler image (first run takes a minute)..." >&2
docker build -q -t "$IMAGE" . >/dev/null

tty_flags=(-i)
[[ -t 0 && -t 1 ]] && tty_flags=(-it)

opts=()
while [[ $# -gt 0 && "$1" == --* ]]; do opts+=("$1"); shift; done
target="${1:-302}"

demo() {  # demo <test name> <stdin for the program>
  local file=$1 input=$2
  echo "== tests/$file.mj  (program input: $(printf '%b' "$input" | tr '\n' ' '))" >&2
  printf '%b' "$input" | docker run --rm -i "$IMAGE" ${opts[@]+"${opts[@]}"} "tests/$file.mj"
  echo
}

case "$target" in
  301|test301) demo test301 '7\n' ;;
  302|test302) demo test302 '1\n2\n3\n' ;;
  303|test303)
    echo "Note: test303 uses classes, which this compiler does not support yet; it is expected to fail." >&2
    demo test303 '2\n' ;;
  program)
    docker run --rm -i "$IMAGE" ${opts[@]+"${opts[@]}"} test/program.mj </dev/null; echo ;;
  test)
    mkdir -p test-logs
    docker run --rm -v "$PWD/test-logs:/mjc/test-logs" --entrypoint /mjc/scripts/run-tests.sh "$IMAGE" test-logs ;;
  shell)
    docker run --rm "${tty_flags[@]}" --entrypoint bash "$IMAGE" ;;
  *.mj)
    [[ -f "$target" ]] || { echo "run.sh: no such file: $target" >&2; exit 1; }
    dir=$(cd "$(dirname "$target")" && pwd)
    docker run --rm "${tty_flags[@]}" -v "$dir:/input:ro" "$IMAGE" ${opts[@]+"${opts[@]}"} "/input/$(basename "$target")"; echo ;;
  *)
    sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
