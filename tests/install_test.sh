#!/usr/bin/env bash

set -u

repository_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P) || exit 1
installer="$repository_dir/install.sh"
temporary_root=$(mktemp -d "${TMPDIR:-/tmp}/harness-installer.XXXXXX") || exit 1
trap 'rm -rf "$temporary_root"' EXIT HUP INT TERM

failures=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

run_installer() {
  target=$1
  selection=$2
  output_file=$3
  shift 3
  printf '%s\n%s\n' "$target" "$selection" | "$installer" "$@" >"$output_file" 2>&1
}

snapshot_tree() {
  target=$1
  output_file=$2
  {
    find "$target" -exec stat -f '%N %HT %Lp %m %z' {} \;
    find "$target" -type f -exec cksum {} \;
  } | sort >"$output_file"
}

assert_templates_match() {
  environment=$1
  target=$2
  source_dir="$repository_dir/harness/$environment"

  while IFS= read -r -d '' source_path; do
    relative_path=${source_path#"$source_dir"/}
    destination_path="$target/$relative_path"
    if [ -d "$source_path" ]; then
      [ -d "$destination_path" ] || fail "$environment: missing directory $relative_path"
    elif [ -f "$source_path" ]; then
      if [ ! -f "$destination_path" ]; then
        fail "$environment: missing file $relative_path"
      elif ! cmp -s -- "$source_path" "$destination_path"; then
        fail "$environment: content differs for $relative_path"
      fi
    fi
  done < <(find "$source_dir" -mindepth 1 -print0)
}

for environment_and_selection in 'rust 1' 'pico-sdk 2' 'esp-idf 3'; do
  environment=${environment_and_selection% *}
  selection=${environment_and_selection#* }
  target="$temporary_root/target-$environment"
  output="$temporary_root/output-$environment"
  mkdir "$target"

  if ! run_installer "$target" "$selection" "$output"; then
    fail "$environment: initial installation failed"
    continue
  fi
  assert_templates_match "$environment" "$target"

  before="$temporary_root/before-$environment"
  after="$temporary_root/after-$environment"
  find "$target" -type f -exec stat -f '%N %m' {} \; | sort >"$before"
  if ! run_installer "$target" "$selection" "$output"; then
    fail "$environment: repeated installation failed"
  fi
  find "$target" -type f -exec stat -f '%N %m' {} \; | sort >"$after"
  cmp -s "$before" "$after" || fail "$environment: repeated installation changed files"
done

dry_run_target="$temporary_root/dry-run-target"
dry_run_output="$temporary_root/dry-run-output"
dry_run_install_output="$temporary_root/dry-run-install-output"
mkdir "$dry_run_target"
rust_file_count=$(find "$repository_dir/harness/rust" -type f | wc -l | tr -d ' ')
if ! run_installer "$dry_run_target" 1 "$dry_run_output" --dry-run; then
  fail 'initial dry-run failed'
else
  [ -z "$(find "$dry_run_target" -mindepth 1 -print -quit)" ] || fail 'dry-run changed an empty target'
  grep -Fq '予定: 新規: Cargo.toml' "$dry_run_output" || fail 'dry-run omitted a planned new file'
  grep -Fq "(新規: $rust_file_count, マージ: 0)" "$dry_run_output" || fail 'dry-run reported incorrect new-file counts'
fi
if ! run_installer "$dry_run_target" 1 "$dry_run_install_output"; then
  fail 'installation after dry-run failed'
else
  grep -Fq "(新規: $rust_file_count, マージ: 0)" "$dry_run_install_output" || fail 'dry-run counts differed from installation counts'
fi

dry_run_before="$temporary_root/dry-run-before"
dry_run_after="$temporary_root/dry-run-after"
snapshot_tree "$dry_run_target" "$dry_run_before"
if ! run_installer "$dry_run_target" 1 "$dry_run_output" --dry-run; then
  fail 'no-change dry-run failed'
fi
snapshot_tree "$dry_run_target" "$dry_run_after"
cmp -s "$dry_run_before" "$dry_run_after" || fail 'no-change dry-run modified the target'
grep -Fq '(新規: 0, マージ: 0)' "$dry_run_output" || fail 'no-change dry-run reported changes'

permission_target="$temporary_root/permission-target"
mkdir "$permission_target"
if run_installer "$permission_target" 2 "$temporary_root/permission-output"; then
  [ -x "$permission_target/.agent-hooks/build.sh" ] || fail 'executable permission was not preserved'
else
  fail 'permission installation failed'
fi

conflict_target="$temporary_root/conflict-target"
mkdir -p "$conflict_target/.codex"
printf 'existing\n' >"$conflict_target/.codex/hooks.json"
if run_installer "$conflict_target" 1 "$temporary_root/conflict-output"; then
  fail 'conflicting installation succeeded'
fi
[ "$(cat "$conflict_target/.codex/hooks.json")" = existing ] || fail 'conflicting file was changed'
[ ! -e "$conflict_target/Cargo.toml" ] || fail 'preflight allowed a partial installation'
if run_installer "$conflict_target" 1 "$temporary_root/conflict-dry-run-output" --dry-run; then
  fail 'conflicting dry-run succeeded'
fi
[ "$(cat "$conflict_target/.codex/hooks.json")" = existing ] || fail 'conflicting dry-run changed a file'
[ ! -e "$conflict_target/Cargo.toml" ] || fail 'conflicting dry-run allowed a partial installation'

merge_target="$temporary_root/merge-target"
mkdir -p "$merge_target/.codex" "$merge_target/.github/hooks" "$merge_target/.vscode"
printf 'target/\n' >"$merge_target/.gitignore"
printf '%s\n' \
  '{' \
  '  "hooks": {' \
  '    "Stop": [' \
  '      {' \
  '        "hooks": [' \
  '          {"type": "command", "command": "./existing.sh"}' \
  '        ]' \
  '      }' \
  '    ]' \
  '  }' \
  '}' >"$merge_target/.codex/hooks.json"
printf '%s\n' \
  '{' \
  '  "version": 1,' \
  '  "hooks": {' \
  '    "agentStop": [' \
  '      {"type": "command", "bash": "./existing.sh", "cwd": "."}' \
  '    ]' \
  '  }' \
  '}' >"$merge_target/.github/hooks/hooks.json"
printf '%s\n' \
  '{' \
  '  "files.trimTrailingWhitespace": true' \
  '}' >"$merge_target/.vscode/settings.json"
printf '%s\n' \
  '[package]' \
  'name = "existing"' \
  'version = "0.1.0"' \
  '' \
  '[lints.clippy]' \
  'unwrap_used = "deny"' >"$merge_target/Cargo.toml"
chmod 640 "$merge_target/Cargo.toml"
printf '%s\n' \
  'custom:' \
  '	@echo custom' >"$merge_target/Makefile"

merge_dry_run_before="$temporary_root/merge-dry-run-before"
merge_dry_run_after="$temporary_root/merge-dry-run-after"
snapshot_tree "$merge_target" "$merge_dry_run_before"
if ! run_installer "$merge_target" 1 "$temporary_root/merge-dry-run-output" --dry-run; then
  fail 'supported file merge dry-run failed'
else
  grep -Fq '予定: マージ: .gitignore' "$temporary_root/merge-dry-run-output" || fail 'merge dry-run omitted a planned merge'
fi
snapshot_tree "$merge_target" "$merge_dry_run_after"
cmp -s "$merge_dry_run_before" "$merge_dry_run_after" || fail 'merge dry-run modified the target'
[ ! -e "$merge_target/.agent-hooks" ] || fail 'merge dry-run created a directory'

if ! run_installer "$merge_target" 1 "$temporary_root/merge-output"; then
  fail 'supported file merge failed'
else
  grep -Fxq '.agent-hooks/state/' "$merge_target/.gitignore" || fail '.gitignore pattern was not merged'
  grep -Fq './existing.sh' "$merge_target/.codex/hooks.json" || fail 'existing Codex hook was lost'
  grep -Fq 'verify_pipeline.sh codex Stop' "$merge_target/.codex/hooks.json" || fail 'Codex hook was not merged'
  grep -Fq './existing.sh' "$merge_target/.github/hooks/hooks.json" || fail 'existing GitHub hook was lost'
  grep -Fq 'verify_pipeline.sh copilot agentStop' "$merge_target/.github/hooks/hooks.json" || fail 'GitHub hook was not merged'
  grep -Fq '"files.trimTrailingWhitespace": true' "$merge_target/.vscode/settings.json" || fail 'existing VS Code setting was lost'
  grep -Fq '"rust-analyzer.check.command": "clippy"' "$merge_target/.vscode/settings.json" || fail 'VS Code setting was not merged'
  grep -Fxq 'unwrap_used = "deny"' "$merge_target/Cargo.toml" || fail 'existing Cargo lint was lost'
  grep -Fxq 'panic = "deny"' "$merge_target/Cargo.toml" || fail 'Cargo lint was not merged'
  [ "$(stat -f '%Lp' "$merge_target/Cargo.toml")" = 640 ] || fail 'merged file permission was not preserved'
  grep -Fxq 'custom:' "$merge_target/Makefile" || fail 'existing Makefile target was lost'
  grep -Fxq 'check: fmt-check lint test' "$merge_target/Makefile" || fail 'Makefile target was not merged'

  merge_before="$temporary_root/merge-before"
  merge_after="$temporary_root/merge-after"
  find "$merge_target" -type f -exec stat -f '%N %m' {} \; | sort >"$merge_before"
  if ! run_installer "$merge_target" 1 "$temporary_root/merge-repeat-output"; then
    fail 'repeated merged installation failed'
  fi
  find "$merge_target" -type f -exec stat -f '%N %m' {} \; | sort >"$merge_after"
  cmp -s "$merge_before" "$merge_after" || fail 'repeated merged installation changed files'
fi

value_conflict_target="$temporary_root/value-conflict-target"
mkdir -p "$value_conflict_target/.vscode"
printf '%s\n' '{"editor.fontLigatures": true}' >"$value_conflict_target/.vscode/settings.json"
if run_installer "$value_conflict_target" 1 "$temporary_root/value-conflict-output"; then
  fail 'different existing setting was overwritten'
fi
grep -Fq '"editor.fontLigatures": true' "$value_conflict_target/.vscode/settings.json" || fail 'conflicting setting was changed'
[ ! -e "$value_conflict_target/.agent-hooks" ] || fail 'merge conflict allowed a partial installation'

unsupported_target="$temporary_root/unsupported-target"
mkdir -p "$unsupported_target/.agent-hooks"
printf 'existing\n' >"$unsupported_target/.agent-hooks/pre_tool_guard.sh"
if run_installer "$unsupported_target" 1 "$temporary_root/unsupported-output"; then
  fail 'unsupported file merge succeeded'
fi
[ "$(cat "$unsupported_target/.agent-hooks/pre_tool_guard.sh")" = existing ] || fail 'unsupported file was changed'
[ ! -e "$unsupported_target/Cargo.toml" ] || fail 'unsupported conflict allowed a partial installation'

toml_conflict_target="$temporary_root/toml-conflict-target"
mkdir "$toml_conflict_target"
printf '%s\n' '[lints.clippy]' 'invalid definition' >"$toml_conflict_target/Cargo.toml"
if run_installer "$toml_conflict_target" 1 "$temporary_root/toml-conflict-output"; then
  fail 'invalid Cargo.toml merge succeeded'
fi
[ ! -e "$toml_conflict_target/.agent-hooks" ] || fail 'invalid Cargo.toml allowed a partial installation'

make_conflict_target="$temporary_root/make-conflict-target"
mkdir "$make_conflict_target"
printf '%s\n' 'check:' '	@echo existing' >"$make_conflict_target/Makefile"
if run_installer "$make_conflict_target" 1 "$temporary_root/make-conflict-output"; then
  fail 'different Makefile target merge succeeded'
fi
grep -Fxq '	@echo existing' "$make_conflict_target/Makefile" || fail 'conflicting Makefile was changed'
[ ! -e "$make_conflict_target/.agent-hooks" ] || fail 'Makefile conflict allowed a partial installation'

if ! "$installer" --help >"$temporary_root/help-output" 2>&1; then
  fail '--help failed'
fi
grep -Fq -- '--dry-run' "$temporary_root/help-output" || fail '--help omitted --dry-run'

if "$installer" --override >"$temporary_root/override-output" 2>&1; then
  fail 'removed --override option succeeded'
fi

if "$installer" --dry-run --dry-run >"$temporary_root/duplicate-output" 2>&1; then
  fail 'duplicate option succeeded'
fi

if "$installer" --help --dry-run >"$temporary_root/help-combination-output" 2>&1; then
  fail '--help combination succeeded'
fi

if "$installer" --unknown >"$temporary_root/unknown-output" 2>&1; then
  fail 'unknown option succeeded'
fi

invalid_target="$temporary_root/does-not-exist"
if run_installer "$invalid_target" 1 "$temporary_root/invalid-target-output"; then
  fail 'nonexistent target succeeded'
fi

selection_target="$temporary_root/selection-target"
mkdir "$selection_target"
if run_installer "$selection_target" 4 "$temporary_root/invalid-selection-output"; then
  fail 'invalid environment selection succeeded'
fi

if [ "$failures" -ne 0 ]; then
  printf '%s test(s) failed\n' "$failures" >&2
  exit 1
fi

printf 'All installer tests passed.\n'
