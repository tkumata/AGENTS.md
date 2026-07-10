#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
STATE_DIR="${ROOT}/.agent-hooks/state"
STATE_FILE="${STATE_DIR}/check-state"
LOG_DIR="${STATE_DIR}/logs"

json_copilot_block() {
  local msg="$1"
  jq -nc --arg msg "${msg}" '{decision:"block", reason:$msg}'
}

json_codex_continue() {
  local msg="$1"
  jq -nc --arg msg "${msg}" '{continue:true, stopReason:$msg, systemMessage:$msg}'
}

report_failure() {
  local msg="$1"

  case "${AGENT_KIND:-generic}" in
    copilot)
      json_copilot_block "${msg}"
      ;;
    *)
      json_codex_continue "${msg}"
      ;;
  esac
}

verify_static() {
  jq empty .codex/hooks.json
  jq empty .github/hooks/hooks.json

  local script
  for script in .agent-hooks/*.sh; do
    bash -n "${script}"
  done

  jq -e '
    .hooks.PreToolUse[0].matcher == "Bash" and
    .hooks.PreToolUse[0].hooks[0].command == "AGENT_KIND=codex ./.agent-hooks/pre_tool_guard.sh" and
    .hooks.Stop[0].hooks[0].command == "AGENT_KIND=codex ./.agent-hooks/verify_pipeline.sh"
  ' .codex/hooks.json >/dev/null
  jq -e '
    .version == 1 and
    .hooks.preToolUse[0].bash == "AGENT_KIND=copilot ./.agent-hooks/pre_tool_guard.sh" and
    .hooks.agentStop[0].bash == "AGENT_KIND=copilot ./.agent-hooks/verify_pipeline.sh"
  ' .github/hooks/hooks.json >/dev/null

  git diff --check
}

is_relevant_path() {
  case "$1" in
    CMakeLists.txt|pico_sdk_import.cmake|.clang-format|.codex/hooks.json|.github/hooks/hooks.json|cmake/*|src/*|tests/*|assets/*|.agent-hooks/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

sha256_file() {
  openssl dgst -sha256 "$1" | awk '{print $NF}'
}

sha256_stdin() {
  openssl dgst -sha256 | awk '{print $NF}'
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

check_fingerprint() {
  local paths
  paths="$(changed_relevant_paths)"

  if [ -z "${paths}" ]; then
    printf '%s\n' "no-relevant-changes"
    return
  fi

  while IFS= read -r path; do
    if [ -f "${path}" ]; then
      printf '%s  %s\n' "${path}" "$(sha256_file "${path}")"
    else
      printf 'deleted  %s\n' "${path}"
    fi
  done <<<"${paths}" | sha256_stdin
}

read_cached_state() {
  CACHED_STATUS=""
  CACHED_FINGERPRINT=""

  if [ -f "${STATE_FILE}" ]; then
    read -r CACHED_STATUS CACHED_FINGERPRINT < "${STATE_FILE}" || true
  fi
}

write_cached_state() {
  local status="$1"
  local fingerprint="$2"
  local temporary

  mkdir -p "${STATE_DIR}"
  temporary="$(mktemp "${STATE_DIR}/check-state.XXXXXX")"
  printf '%s %s\n' "${status}" "${fingerprint}" > "${temporary}"
  mv "${temporary}" "${STATE_FILE}"
}

run_full_check() {
  local fingerprint="$1"
  local log="${LOG_DIR}/check-${fingerprint}.log"

  mkdir -p "${LOG_DIR}"
  if ./.agent-hooks/check.sh > "${log}" 2>&1; then
    write_cached_state "success" "${fingerprint}"
    return 0
  fi

  write_cached_state "failure" "${fingerprint}"
  report_failure "Full harness check failed. Read ${log}, fix the root cause, then continue."
}

cd "${ROOT}"

if ! verify_static; then
  report_failure "Harness static verification failed. Read the hook JSON, shell syntax, and git diff errors, fix the root cause, then continue."
  exit 0
fi

fingerprint="$(check_fingerprint)"
read_cached_state

if [ "${fingerprint}" = "no-relevant-changes" ]; then
  exit 0
fi

if [ "${fingerprint}" = "${CACHED_FINGERPRINT}" ]; then
  if [ "${CACHED_STATUS}" = "failure" ]; then
    report_failure "Full harness check is still failing for the current change set. Read ${LOG_DIR}/check-${fingerprint}.log, fix the root cause, then continue."
  fi
  exit 0
fi

run_full_check "${fingerprint}"
