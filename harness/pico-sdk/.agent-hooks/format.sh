#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

files=()
while IFS= read -r -d '' file; do
  files+=("${file}")
done < <(git ls-files -z '*.c' '*.h' '*.cpp' '*.hpp')

if [ "${#files[@]}" -eq 0 ]; then
  exit 0
fi

clang-format --dry-run -Werror "${files[@]}"
