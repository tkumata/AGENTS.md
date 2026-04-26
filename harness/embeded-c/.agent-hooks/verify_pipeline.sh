#!/usr/bin/env bash
set -euo pipefail

CLI_NAME="${1:-unknown}"
EVENT_NAME="${2:-unknown}"

STATE=.agent-hooks/state
mkdir -p .agent-hooks

if [ ! -f "$STATE" ]; then
  echo check_pending > "$STATE"
fi

PHASE=$(cat "$STATE")

if [ "$PHASE" = "check_pending" ]; then
  if make check; then
    echo build_pending > "$STATE"
    cat <<EOF
{
  "decision": "block",
  "reason": "make check passed for cli=${CLI_NAME} event=${EVENT_NAME}. Run make build next."
}
EOF
  else
    cat <<EOF
{
  "decision": "block",
  "reason": "make check failed for cli=${CLI_NAME} event=${EVENT_NAME}. Fix issues and continue."
}
EOF
  fi

  exit 0
fi

if [ "$PHASE" = "build_pending" ]; then
  if make build; then
    echo done > "$STATE"
    cat <<EOF
{
  "continue": false,
  "stopReason": "Build passed for cli=${CLI_NAME} event=${EVENT_NAME}. Task complete."
}
EOF
    exit 0
  else
    cat <<EOF
{
  "decision": "block",
  "reason": "make build failed for cli=${CLI_NAME} event=${EVENT_NAME}. Fix build errors and continue."
}
EOF
    exit 0
  fi
fi

if [ "$PHASE" = "done" ]; then
  cat <<EOF
{
  "continue": false,
  "stopReason": "Build passed for cli=${CLI_NAME} event=${EVENT_NAME}. Task complete."
}
EOF
  exit 0
fi

cat <<EOF
{
  "decision": "block",
  "reason": "Unknown pipeline state: $PHASE for cli=${CLI_NAME} event=${EVENT_NAME}"
}
EOF
