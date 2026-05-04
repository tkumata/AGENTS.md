#!/usr/bin/env bash
set -euo pipefail

source "$(git rev-parse --show-toplevel)/.agent-hooks/pico_env.sh"

if [ ! -f "${BUILD_DIR}/build.ninja" ]; then
  ./.agent-hooks/configure.sh
fi

cmake --build "${BUILD_DIR}"
