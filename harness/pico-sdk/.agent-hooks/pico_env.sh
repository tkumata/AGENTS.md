#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
PICO_HOME="${PICO_HOME:-$HOME/.pico-sdk}"

if [ ! -d "${PICO_HOME}" ]; then
  echo "ERROR: ${PICO_HOME} not found. Install or initialize the Raspberry Pi Pico VS Code extension first." >&2
  exit 1
fi

# Pico SDK
if [ -d "${PICO_HOME}/sdk" ]; then
  export PICO_SDK_PATH="${PICO_SDK_PATH:-${PICO_HOME}/sdk}"
fi

# Prefer tools installed by Raspberry Pi Pico VS Code extension.
prepend_bin_if_exists() {
  local dir="$1"
  if [ -d "${dir}" ]; then
    export PATH="${dir}:${PATH}"
  fi
}

# Common layouts under ~/.pico-sdk
prepend_bin_if_exists "${PICO_HOME}/cmake/bin"
prepend_bin_if_exists "${PICO_HOME}/ninja"
prepend_bin_if_exists "${PICO_HOME}/ninja/bin"
prepend_bin_if_exists "${PICO_HOME}/toolchain/bin"
prepend_bin_if_exists "${PICO_HOME}/tools/bin"

# Fallback: discover nested bin dirs.
while IFS= read -r bin_dir; do
  export PATH="${bin_dir}:${PATH}"
done < <(find "${PICO_HOME}" -maxdepth 3 -type d -name bin 2>/dev/null)

export PICO_BOARD="${PICO_BOARD:-pico2_w}"
export BUILD_DIR="${BUILD_DIR:-${ROOT}/build}"

cd "${ROOT}"
