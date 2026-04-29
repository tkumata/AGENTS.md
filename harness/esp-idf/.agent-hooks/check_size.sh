#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LATEST_LOG="$LOG_DIR/latest-size.log"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
RUN_LOG="$LOG_DIR/size-$TIMESTAMP.log"

EXPORT_SCRIPT="$HOME/.espressif/v6.0/export.sh"
SIZE_LIMIT_BYTES=$((6 * 1024 * 1024))

mkdir -p "$LOG_DIR"

json_string() {
  python3 -c 'import json, sys; print(json.dumps(sys.stdin.read()))'
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

emit_failure_json() {
  local reason="$1"
  local message
  local json_message

  message="$(
    printf 'ESP-IDF size check failed.\n'
    printf 'Reason: %s\n' "$reason"
    printf 'Limit: %s bytes\n' "$SIZE_LIMIT_BYTES"
    printf 'Log: %s\n\n' "$RUN_LOG"
    printf 'Error summary:\n'
    summarize_log "$RUN_LOG"
    printf '\nFix the ESP-IDF size issue above, then rerun the check until it stays at or below 6 MB.\n'
  )"
  json_message="$(printf '%s' "$message" | json_string)"

  printf '{"continue":false,"stopReason":%s,"systemMessage":%s,"hookSpecificOutput":{"hookEventName":"Stop","decision":"block","reason":%s}}\n' \
    "$json_message" "$json_message" "$json_message"
}

report_failure() {
  local exit_code="$1"
  local reason="$2"

  {
    printf '\nESP-IDF size check failed.\n'
    printf 'Reason: %s\n' "$reason"
    printf 'Exit code: %s\n' "$exit_code"
    printf 'Limit: %s bytes\n' "$SIZE_LIMIT_BYTES"
    printf 'Log: %s\n\n' "$RUN_LOG"
    printf 'Error summary:\n'
    summarize_log "$RUN_LOG"
    printf '\nInstruction for the agent:\n'
    printf 'Fix the ESP-IDF size issue above, then rerun the check until it stays at or below 6 MB.\n'
  } >&2
  emit_failure_json "$reason"
}

extract_total_image_size() {
  awk '
    /^Total image size:/ {
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^[0-9]+$/) {
          print $i
          exit
        }
      }
    }
  ' "$RUN_LOG"
}

: > "$RUN_LOG"
ln -sf "$(basename "$RUN_LOG")" "$LATEST_LOG"

if [ ! -f "$EXPORT_SCRIPT" ]; then
  {
    printf 'ESP-IDF export script not found: %s\n' "$EXPORT_SCRIPT"
    printf 'Expected the ESP-IDF v6.0 export script under $HOME/.espressif/v6.0/export.sh.\n'
  } >> "$RUN_LOG"
  report_failure 1 "ESP-IDF environment resolution failed"
  exit 1
fi

(
  cd "$REPO_ROOT" || exit 1
  # shellcheck disable=SC1090
  source "$EXPORT_SCRIPT"
  idf.py size
) >> "$RUN_LOG" 2>&1

SIZE_EXIT=$?

if [ "$SIZE_EXIT" -ne 0 ]; then
  report_failure 2 "idf.py size failed"
  exit 2
fi

TOTAL_IMAGE_SIZE="$(extract_total_image_size)"

if [ -z "$TOTAL_IMAGE_SIZE" ]; then
  report_failure 3 "Total image size was not reported by idf.py size"
  exit 3
fi

if [ "$TOTAL_IMAGE_SIZE" -le "$SIZE_LIMIT_BYTES" ]; then
  printf '{"continue":true,"systemMessage":"ESP-IDF size check succeeded. Total image size: %s bytes (limit: %s bytes). Log: %s"}\n' \
    "$TOTAL_IMAGE_SIZE" "$SIZE_LIMIT_BYTES" "$RUN_LOG"
  exit 0
fi

{
  printf 'Total image size exceeded the limit.\n'
  printf 'Total image size: %s bytes\n' "$TOTAL_IMAGE_SIZE"
  printf 'Limit: %s bytes\n' "$SIZE_LIMIT_BYTES"
} >> "$RUN_LOG"
report_failure 4 "Total image size exceeded 6 MB"
exit 4
