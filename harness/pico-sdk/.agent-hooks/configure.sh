#!/usr/bin/env bash
set -euo pipefail

source "$(git rev-parse --show-toplevel)/.agent-hooks/pico_env.sh"

if [ -f "${BUILD_DIR}/CMakeCache.txt" ]; then
  existing_board="$(grep '^PICO_BOARD:' "${BUILD_DIR}/CMakeCache.txt" 2>/dev/null | head -n 1 | cut -d= -f2 || true)"
  if [ -n "${existing_board}" ] && [ "${existing_board}" != "${PICO_BOARD}" ]; then
    echo "ERROR: ${BUILD_DIR} targets ${existing_board}, not ${PICO_BOARD}. Choose a matching BUILD_DIR or clean it explicitly." >&2
    exit 1
  fi
fi

cmake -S . -B "${BUILD_DIR}" \
  -G Ninja \
  -DPICO_BOARD="${PICO_BOARD}" \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
