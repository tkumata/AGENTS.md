#!/usr/bin/env bash
set -euo pipefail

STATE=.codex/state
mkdir -p .codex

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
  "reason": "make check passed. Run make build next."
}
EOF
  else
    cat <<EOF
{
  "decision": "block",
  "reason": "make check failed. Fix issues and continue."
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
  "stopReason": "Build passed. Task complete."
}
EOF
  else
    cat <<EOF
{
  "decision": "block",
  "reason": "make build failed. Fix build errors and continue."
}
EOF
  fi
fi
