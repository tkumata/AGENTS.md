#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
STATE_DIR="${ROOT}/.agent-hooks/state"
STATE_FILE="${STATE_DIR}/esp-idf-pipeline-state"
REVIEW_INSTRUCTION="ESP-IDF build and size verification passed. Before stopping, review the current uncommitted changes for correctness, regressions, security, test coverage, and documentation consistency. Fix every actionable finding within the requested scope. If you change ESP-IDF-related files, finish the fixes and let the Stop hook rerun build and size verification before claiming completion. If there are no findings, report that explicitly and stop."

request_continuation() {
  local message="$1"

  case "${AGENT_KIND:-codex}" in
    copilot)
      printf '%s' "${message}" | python3 -c \
        'import json, sys; print(json.dumps({"continue": False, "message": sys.stdin.read()}))'
      ;;
    *)
      printf '%s' "${message}" | python3 -c \
        'import json, sys; print(json.dumps({"decision": "block", "reason": sys.stdin.read()}))'
      ;;
  esac
}

is_relevant_path() {
  case "$1" in
    *.c|*.h|*.cc|*.cpp|*.cxx|*.hh|*.hpp|*.hxx|*.s|*.S|*.ld|*.ld.in|*.cmake|CMakeLists.txt|*/CMakeLists.txt|Kconfig|Kconfig.*|*/Kconfig|*/Kconfig.*|sdkconfig|sdkconfig.*|*/sdkconfig|*/sdkconfig.*|dependencies.lock|*/dependencies.lock|idf_component.yml|idf_component.yaml|*/idf_component.yml|*/idf_component.yaml|partitions*.csv|*/partitions*.csv|.agent-hooks/*|.codex/hooks.json|.github/hooks/hooks.json)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

changed_relevant_paths() {
  {
    git diff --name-only --no-renames HEAD
    git ls-files --others --exclude-standard
  } | while IFS= read -r path; do
    if is_relevant_path "${path}"; then
      printf '%s\n' "${path}"
    fi
  done | LC_ALL=C sort -u
}

fingerprint() {
  local paths
  paths="$(changed_relevant_paths)"

  if [ -z "${paths}" ]; then
    return 1
  fi

  while IFS= read -r path; do
    if [ -f "${path}" ]; then
      printf '%s  %s\n' "${path}" "$(git hash-object -- "${path}")"
    else
      printf 'deleted  %s\n' "${path}"
    fi
  done <<<"${paths}" | shasum -a 256 | awk '{print $1}'
}

run_check() {
  local script="$1"
  local output

  if output="$("${script}")"; then
    return 0
  fi

  printf '%s\n' "${output}"
  return 1
}

cd "${ROOT}"

if ! current_fingerprint="$(fingerprint)"; then
  exit 0
fi

if [ -f "${STATE_FILE}" ] && [ "$(cat "${STATE_FILE}")" = "${current_fingerprint}" ]; then
  exit 0
fi

run_check ./.agent-hooks/check_build.sh || exit 0
run_check ./.agent-hooks/check_size.sh || exit 0

if [ "$(fingerprint)" != "${current_fingerprint}" ]; then
  request_continuation "ESP-IDF-related changes changed during verification. Rerun build and size verification before stopping."
  exit 0
fi

mkdir -p "${STATE_DIR}"
request_continuation "${REVIEW_INSTRUCTION}"
printf '%s\n' "${current_fingerprint}" > "${STATE_FILE}"
