#!/usr/bin/env bash
set -euo pipefail

CLI_NAME="${1:-}"
EVENT_NAME="${2:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

normalize() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

CLI="$(normalize "$CLI_NAME")"
EVENT="$(normalize "$EVENT_NAME")"

case "${CLI}:${EVENT}" in
  codex:pretooluse|copilot:pretooluse)
    exec "$SCRIPT_DIR/verify_pipeline.sh" "$CLI_NAME" "$EVENT_NAME"
    ;;
  codex:stop|copilot:agentstop)
    cat <<'EOF'
{
  "continue": true,
  "stopReason": "Stop hook acknowledged."
}
EOF
    ;;
  *)
    cat <<EOF
{
  "continue": true,
  "reason": "No action for cli=${CLI_NAME:-unknown} event=${EVENT_NAME:-unknown}."
}
EOF
    ;;
esac
