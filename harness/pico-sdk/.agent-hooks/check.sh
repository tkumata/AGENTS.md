#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

./.agent-hooks/format.sh
./.agent-hooks/build.sh

if [ ! -f "build/compile_commands.json" ]; then
  echo "ERROR: build/compile_commands.json was not generated." >&2
  exit 1
fi
