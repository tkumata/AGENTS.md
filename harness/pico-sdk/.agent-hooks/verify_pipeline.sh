#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
STATE_DIR="${ROOT}/.agent-hooks/state"
STATE_FILE="${STATE_DIR}/pipeline_state"
LOG_DIR="${STATE_DIR}/logs"

mkdir -p "${LOG_DIR}"

if [ ! -f "${STATE_FILE}" ]; then
  echo "check_pending" > "${STATE_FILE}"
fi

PHASE="$(cat "${STATE_FILE}")"

run_and_log() {
  local name="$1"
  local cmd="$2"
  local log="${LOG_DIR}/${name}.log"

  {
    echo "\$ ${cmd}"
    echo
    bash -lc "${cmd}"
  } >"${log}" 2>&1
}

json_block() {
  local msg="$1"
  jq -nc --arg msg "${msg}" '{decision:"block", reason:$msg}'
}

json_continue_false() {
  local msg="$1"
  jq -nc --arg msg "${msg}" '{continue:false, stopReason:$msg, systemMessage:$msg}'
}

# Copilot CLI / Codex CLI の JSON 契約差を完全には吸収しきれないため、
# 標準出力 JSON は最小限にする。
block_with_message() {
  local msg="$1"
  local agent="${AGENT_KIND:-generic}"

  case "${agent}" in
    codex)
      json_continue_false "${msg}"
      ;;
    copilot)
      json_block "${msg}"
      ;;
    *)
      json_block "${msg}"
      ;;
  esac
}

cd "${ROOT}"

case "${PHASE}" in
  check_pending)
    if run_and_log check "./.agent-hooks/check.sh"; then
      echo "done" > "${STATE_FILE}"
      block_with_message "Pico validation succeeded. Review git diff and summarize the result before stopping."
    else
      echo "check_pending" > "${STATE_FILE}"
      block_with_message "Pico validation failed. Read .agent-hooks/state/logs/check.log, fix the root cause, then continue. Do not suppress warnings or bypass the build."
    fi
    ;;

  done)
    rm -f "${STATE_FILE}"
    block_with_message "Pico validation already passed. You may stop after summarizing the changes."
    ;;

  *)
    echo "check_pending" > "${STATE_FILE}"
    block_with_message "Unknown harness phase was reset to check_pending. Continue and run validation again."
    ;;
esac
