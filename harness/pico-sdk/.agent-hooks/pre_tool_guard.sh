#!/usr/bin/env bash
set -euo pipefail

payload="$(cat || true)"

deny() {
  local reason="$1"

  case "${AGENT_KIND:-generic}" in
    codex)
      jq -nc --arg reason "${reason}" '{decision:"block", reason:$reason}'
      ;;
    copilot)
      jq -nc --arg reason "${reason}" '{decision:"deny", reason:$reason}'
      ;;
    *)
      jq -nc --arg reason "${reason}" '{decision:"block", reason:$reason}'
      ;;
  esac
  exit 0
}

allow() {
  if [ "${AGENT_KIND:-generic}" = "copilot" ]; then
    jq -nc '{decision:"allow"}'
  fi
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
  *"git push"*|*"git reset --hard"*|*"git clean -fd"*)
    deny "Blocked destructive Git command. Do not push, hard-reset, or wipe untracked files from an agent hook session."
    ;;
  *"rm -rf $HOME/.pico-sdk"*|*"rm -rf ~/.pico-sdk"*|*"rm -rf .pico-sdk"*)
    deny "Blocked deletion of Raspberry Pi Pico SDK/toolchain directory."
    ;;
  *"rm -rf build"*|*"rm -fr build"*)
    deny "Do not delete build directly. Use CMake clean/reconfigure or explain why a full rebuild is required."
    ;;
  *"chmod -x .agent-hooks"*|*"chmod -x .github/hooks"*|*"chmod -x .codex/hooks"*|*"rm -rf .agent-hooks"*|*"rm -fr .agent-hooks"*|*"rm -r .agent-hooks"*|*"rm -f .agent-hooks"*|*"rm .agent-hooks"*|*"rm -rf .github/hooks"*|*"rm -fr .github/hooks"*|*"rm -r .github/hooks"*|*"rm -f .github/hooks"*|*"rm .github/hooks"*|*"rm -rf .codex/hooks"*|*"rm -fr .codex/hooks"*|*"rm -r .codex/hooks"*|*"rm -f .codex/hooks"*|*"rm .codex/hooks"*)
    deny "Blocked attempt to disable or remove harness files."
    ;;
  *"rm -rf .clang-format"*|*"rm -fr .clang-format"*|*"rm -f .clang-format"*|*"rm .clang-format"*|*".clang-format"*"> /dev/null"*|*".clang-format"*"> /tmp/"*)
    deny "Blocked suspicious .clang-format modification. Edit formatting policy explicitly and explain the reason."
    ;;
esac

allow
