#!/usr/bin/env bash
set -u

repository_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P) || exit 1
temporary_root=$(mktemp -d "${TMPDIR:-/tmp}/esp-idf-hook.XXXXXX") || exit 1
trap 'rm -rf "$temporary_root"' EXIT HUP INT TERM

fixture="$temporary_root/fixture"
mkdir -p "$fixture/.agent-hooks"
cp "$repository_dir/harness/esp-idf/.agent-hooks/verify_pipeline.sh" "$fixture/.agent-hooks/"

# shellcheck disable=SC2016
printf '%s\n' '#!/usr/bin/env bash' 'printf "build\\n" >> .agent-hooks/calls' '[ -z "${FAIL_BUILD:-}" ] || { printf '\''{"continue":false,"stopReason":"build failed"}\\n'\''; exit 1; }' 'printf '\''{"continue":true}\\n'\''' > "$fixture/.agent-hooks/check_build.sh"
# shellcheck disable=SC2016
printf '%s\n' '#!/usr/bin/env bash' 'printf "size\\n" >> .agent-hooks/calls' '[ -z "${FAIL_SIZE:-}" ] || { printf '\''{"continue":false,"stopReason":"size failed"}\\n'\''; exit 1; }' 'printf '\''{"continue":true}\\n'\''' > "$fixture/.agent-hooks/check_size.sh"
chmod +x "$fixture/.agent-hooks/"*.sh

git -C "$fixture" init -q
git -C "$fixture" config user.name test
git -C "$fixture" config user.email test@example.com
printf 'fixture\n' > "$fixture/README.md"
printf '%s\n' '.agent-hooks/calls' '.agent-hooks/state/' > "$fixture/.gitignore"
git -C "$fixture" add .
git -C "$fixture" commit -qm initial

run_hook() {
  (cd "$fixture" && ./.agent-hooks/verify_pipeline.sh)
}

output="$(run_hook)"
[ -z "$output" ] || { printf 'FAIL: clean tree produced output\n' >&2; exit 1; }
[ ! -e "$fixture/.agent-hooks/calls" ] || { printf 'FAIL: clean tree ran checks\n' >&2; exit 1; }

mkdir "$fixture/docs"
printf 'docs only\n' > "$fixture/docs/note.md"
output="$(run_hook)"
[ -z "$output" ] || { printf 'FAIL: documentation change produced output\n' >&2; exit 1; }
[ ! -e "$fixture/.agent-hooks/calls" ] || { printf 'FAIL: documentation change ran checks\n' >&2; exit 1; }

printf 'int main(void) { return 0; }\n' > "$fixture/main.c"
output="$(run_hook)"
printf '%s' "$output" | grep -Fq 'review the current uncommitted changes' || { printf 'FAIL: review was not requested\n' >&2; exit 1; }
printf '%s' "$output" | jq -e '.decision == "block" and (.reason | contains("review the current uncommitted changes"))' >/dev/null || { printf 'FAIL: Codex review response was invalid\n' >&2; exit 1; }
[ "$(sed -n '1p' "$fixture/.agent-hooks/calls")" = build ] || { printf 'FAIL: build did not run first\n' >&2; exit 1; }
[ "$(sed -n '2p' "$fixture/.agent-hooks/calls")" = size ] || { printf 'FAIL: size did not run second\n' >&2; exit 1; }

before="$(wc -l < "$fixture/.agent-hooks/calls")"
output="$(run_hook)"
after="$(wc -l < "$fixture/.agent-hooks/calls")"
[ -z "$output" ] || { printf 'FAIL: validated fingerprint produced output\n' >&2; exit 1; }
[ "$before" = "$after" ] || { printf 'FAIL: validated fingerprint reran checks\n' >&2; exit 1; }

printf 'int main(void) { return 1; }\n' > "$fixture/main.c"
output="$(run_hook)"
printf '%s' "$output" | grep -Fq 'review the current uncommitted changes' || { printf 'FAIL: changed fingerprint was not reviewed\n' >&2; exit 1; }
[ "$(tail -n 2 "$fixture/.agent-hooks/calls" | tr '\n' ' ')" = 'build size ' ] || { printf 'FAIL: changed fingerprint did not rerun build and size\n' >&2; exit 1; }

printf 'int main(void) { return 2; }\n' > "$fixture/main.c"
output="$(cd "$fixture" && AGENT_KIND=copilot ./.agent-hooks/verify_pipeline.sh)"
printf '%s' "$output" | jq -e '.continue == false and (.message | contains("review the current uncommitted changes"))' >/dev/null || { printf 'FAIL: Copilot review response was invalid\n' >&2; exit 1; }

printf 'int main(void) { return 3; }\n' > "$fixture/main.c"
output="$(cd "$fixture" && FAIL_BUILD=1 ./.agent-hooks/verify_pipeline.sh)"
printf '%s' "$output" | grep -Fq 'build failed' || { printf 'FAIL: build failure was not returned\n' >&2; exit 1; }
[ "$(tail -n 1 "$fixture/.agent-hooks/calls")" = build ] || { printf 'FAIL: size ran after build failure\n' >&2; exit 1; }

printf 'int main(void) { return 4; }\n' > "$fixture/main.c"
output="$(cd "$fixture" && FAIL_SIZE=1 ./.agent-hooks/verify_pipeline.sh)"
printf '%s' "$output" | grep -Fq 'size failed' || { printf 'FAIL: size failure was not returned\n' >&2; exit 1; }
[ "$(tail -n 2 "$fixture/.agent-hooks/calls" | tr '\n' ' ')" = 'build size ' ] || { printf 'FAIL: size failure did not follow build\n' >&2; exit 1; }

printf 'PASS: ESP-IDF Stop hook gating and review flow\n'
