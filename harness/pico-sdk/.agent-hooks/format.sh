#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

files="$(git ls-files '*.c' '*.h' '*.cpp' '*.hpp')"

if [ -z "${files}" ]; then
  exit 0
fi

clang-format -i ${files}
