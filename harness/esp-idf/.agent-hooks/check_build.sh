#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LATEST_LOG="$LOG_DIR/latest.log"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
RUN_LOG="$LOG_DIR/build-$TIMESTAMP.log"

mkdir -p "$LOG_DIR"

IDF_ROOT="${IDF_PATH:-$HOME/.espressif/v6.0/esp-idf}"
EXPORT_SCRIPT="$IDF_ROOT/export.sh"
IDF_PYTHON_COMMAND=""

resolve_python_env() {
  local cache_file="$REPO_ROOT/build/CMakeCache.txt"
  local cached_python
  local cached_env
  local repo_env="$REPO_ROOT/.idf-python-env"

  if [ -n "${IDF_PYTHON_ENV_PATH:-}" ]; then
    return
  fi

  if [ -f "$cache_file" ]; then
    cached_python="$(sed -n 's/^PYTHON:[^=]*=//p' "$cache_file" | head -n 1)"
    if [ -n "$cached_python" ] && [ -x "$cached_python" ]; then
      cached_env="$(cd "$(dirname "$cached_python")/.." && pwd)"
      export IDF_PYTHON_ENV_PATH="$cached_env"
      IDF_PYTHON_COMMAND="$cached_python"
      return
    fi
  fi

  if [ -x "$repo_env/bin/python" ] || [ -x "$repo_env/bin/python3" ]; then
    export IDF_PYTHON_ENV_PATH="$repo_env"
  fi
}

summarize_log() {
  local log_file="$1"
  local summary

  summary="$(
    grep -Ei "(error:|ERROR|FAILED:|CMake Error|ninja failed|undefined reference|No such file or directory|currently active in the environment|configured with|Run 'idf.py fullclean')" "$log_file" \
      | tail -n 80
  )"

  if [ -z "$summary" ]; then
    summary="$(tail -n 80 "$log_file")"
  fi

  printf '%s\n' "$summary"
}

json_string() {
  python3 -c 'import json, sys; print(json.dumps(sys.stdin.read()))'
}

emit_failure_json() {
  local reason="$1"
  local message
  local json_message

  message="$(
    printf 'ESP-IDF build hook failed.\n'
    printf 'Reason: %s\n' "$reason"
    printf 'Log: %s\n\n' "$RUN_LOG"
    printf 'Error summary:\n'
    summarize_log "$RUN_LOG"
    printf '\nFix the ESP-IDF build errors above, then rerun the ESP-IDF build until it succeeds without errors.\n'
  )"
  json_message="$(printf '%s' "$message" | json_string)"

  printf '{"continue":false,"stopReason":%s,"systemMessage":%s,"hookSpecificOutput":{"hookEventName":"Stop","decision":"block","reason":%s}}\n' \
    "$json_message" "$json_message" "$json_message"
}

report_failure() {
  local exit_code="$1"
  local reason="$2"

  {
    printf '\nESP-IDF build hook failed.\n'
    printf 'Reason: %s\n' "$reason"
    printf 'Exit code: %s\n' "$exit_code"
    printf 'Log: %s\n\n' "$RUN_LOG"
    printf 'Error summary:\n'
    summarize_log "$RUN_LOG"
    printf '\nInstruction for the agent:\n'
    printf 'Fix the ESP-IDF build errors above, then rerun the ESP-IDF build until it succeeds without errors.\n'
  } >&2
  emit_failure_json "$reason"
}

: > "$RUN_LOG"
ln -sf "$(basename "$RUN_LOG")" "$LATEST_LOG"

if [ ! -f "$EXPORT_SCRIPT" ]; then
  {
    printf 'ESP-IDF export script not found: %s\n' "$EXPORT_SCRIPT"
    printf 'Set IDF_PATH or install ESP-IDF v6.0 under $HOME/.espressif/v6.0/esp-idf.\n'
  } >> "$RUN_LOG"
  report_failure 1 "ESP-IDF environment resolution failed"
  exit 1
fi

resolve_python_env

(
  cd "$REPO_ROOT" || exit 1
  # shellcheck disable=SC1090
  source "$EXPORT_SCRIPT"
  if [ -n "$IDF_PYTHON_COMMAND" ]; then
    "$IDF_PYTHON_COMMAND" "$IDF_ROOT/tools/idf.py" build
  else
    idf.py build
  fi
) >> "$RUN_LOG" 2>&1

BUILD_EXIT=$?

if [ "$BUILD_EXIT" -ne 0 ]; then
  report_failure 2 "idf.py build failed"
  exit 2
fi

printf '{"continue":true,"systemMessage":"ESP-IDF build hook succeeded. Log: %s"}\n' "$RUN_LOG"
