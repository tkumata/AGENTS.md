#!/usr/bin/env bash
set -euo pipefail

payload="$(cat || true)"

deny() {
  local reason="$1"
  jq -nc --arg reason "${reason}" '{decision:"deny", reason:$reason}'
  exit 0
}

allow() {
  jq -nc '{decision:"allow"}'
  exit 0
}

# Try to extract command-like text from common hook payloads.
cmd="$(printf '%s' "${payload}" | jq -r '
  .command? //
  .tool_input.command? //
  .toolInput.command? //
  .input.command? //
  .args.command? //
  empty
' 2>/dev/null || true)"

[ -z "${cmd}" ] && allow

case "${cmd}" in
  *"git push"*|*"git reset --hard"*|*"git clean -fdx"*)
    deny "Blocked destructive Git command. Do not push, hard-reset, or wipe untracked files from an agent hook session."
    ;;
  *"rm -rf $HOME/.pico-sdk"*|*"rm -rf ~/.pico-sdk"*|*"rm -rf .pico-sdk"*)
    deny "Blocked deletion of Raspberry Pi Pico SDK/toolchain directory."
    ;;
  *"rm -rf build"*|*"rm -fr build"*)
    deny "Do not delete build directly. Use CMake clean/reconfigure or explain why a full rebuild is required."
    ;;
  *".agent-harness"*chmod*" -x"*|*"hooks.json"*rm*|*".github/hooks"*rm*|*".codex/hooks"*rm*)
    deny "Blocked attempt to disable or remove harness files."
    ;;
  *".clang-format"*rm*|*".clang-format"*"> /dev/null"*|*".clang-format"*"> /tmp/"*)
    deny "Blocked suspicious .clang-format modification. Edit formatting policy explicitly and explain the reason."
    ;;
esac

allow
