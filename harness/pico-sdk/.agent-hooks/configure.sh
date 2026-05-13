#!/usr/bin/env bash
set -euo pipefail

source "$(git rev-parse --show-toplevel)/.agent-hooks/pico_env.sh"

cmake -S . -B "${BUILD_DIR}" \
  -G Ninja \
  -DPICO_BOARD="${PICO_BOARD}" \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
