#!/usr/bin/env bash

set -u

repository_dir=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P) || exit 1
installer="$repository_dir/install.sh"
temporary_root=$(mktemp -d "${TMPDIR:-/tmp}/harness-installer.XXXXXX") || exit 1
trap 'rm -rf "$temporary_root"' EXIT HUP INT TERM

# すべての呼び出しを一時 HOME に隔離する。
export HOME="$temporary_root/home"
mkdir "$HOME"

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
    case "$relative_path" in
      .claude|.claude/*|.github|.github/*) continue ;;
    esac
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

assert_agent_paths() {
  target=$1
  [ -f "$target/.codex/hooks.json" ] || fail 'missing Codex hook'
  [ ! -e "$target/.claude/settings.json" ] || fail 'Claude hook installed'
  [ ! -e "$target/.github/hooks/hooks.json" ] || fail 'Copilot hook installed'

}

for environment_and_selection in \
  'rust 1' \
  'pico-sdk 2' \
  'esp-idf 3'; do
  environment=${environment_and_selection%% *}
  selection=${environment_and_selection#* }
  target="$temporary_root/target-$environment"
  output="$temporary_root/output-$environment"
  mkdir "$target"

  if ! run_installer "$target" "$selection" "$output"; then
    fail "$environment: initial installation failed"
    continue
  fi
  assert_templates_match "$environment" "$target"
  assert_agent_paths "$target"

  before="$temporary_root/before-$environment"
  after="$temporary_root/after-$environment"
  find "$target" -type f -exec stat -f '%N %m' {} \; | sort >"$before"
  if ! run_installer "$target" "$selection" "$output"; then
    fail "$environment: repeated installation failed"
  else
    grep -Fq '(新規: 0, マージ: 0)' "$output" || \
      fail "$environment: repeated installation reported changes"
  fi
  find "$target" -type f -exec stat -f '%N %m' {} \; | sort >"$after"
  cmp -s "$before" "$after" || fail "$environment: repeated installation changed files"
done


dry_run_target="$temporary_root/dry-run-target"
dry_run_output="$temporary_root/dry-run-output"
dry_run_install_output="$temporary_root/dry-run-install-output"
mkdir "$dry_run_target"
rust_file_count=$(find "$repository_dir/harness/rust" -type f ! -path '*/.claude/*' ! -path '*/.github/*' | wc -l | tr -d ' ')
rust_new_count=$rust_file_count
if ! run_installer "$dry_run_target" 1 "$dry_run_output" --dry-run; then
  fail 'initial dry-run failed'
else
  [ -z "$(find "$dry_run_target" -mindepth 1 -print -quit)" ] || fail 'dry-run changed an empty target'
  grep -Fq '予定: 新規: Cargo.toml' "$dry_run_output" || fail 'dry-run omitted a planned new file'
  grep -Fq "(新規: $rust_new_count, マージ: 0)" "$dry_run_output" || fail 'dry-run reported incorrect new-file counts'
fi
if ! run_installer "$dry_run_target" 1 "$dry_run_install_output"; then
  fail 'installation after dry-run failed'
else
  grep -Fq "(新規: $rust_new_count, マージ: 0)" "$dry_run_install_output" || fail 'dry-run counts differed from installation counts'
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
  ! grep -Fq 'verify_pipeline.sh copilot agentStop' "$merge_target/.github/hooks/hooks.json" || fail 'excluded GitHub hook was changed'
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

preserve_target="$temporary_root/preserve-target"
mkdir -p "$preserve_target/.claude" "$preserve_target/.github/hooks" "$preserve_target/docs"
printf 'existing Claude settings\n' >"$preserve_target/.claude/settings.json"
printf 'existing Copilot hooks\n' >"$preserve_target/.github/hooks/hooks.json"
printf 'existing Claude docs\n' >"$preserve_target/docs/CLAUDE.md"
if ! run_installer "$preserve_target" 1 "$temporary_root/preserve-output"; then
  fail 'preserve-target installation failed'
else
  grep -Fxq 'existing Claude settings' "$preserve_target/.claude/settings.json" || fail 'excluded Claude settings changed'
  grep -Fxq 'existing Copilot hooks' "$preserve_target/.github/hooks/hooks.json" || fail 'excluded Copilot hooks changed'
  grep -Fxq 'existing Claude docs' "$preserve_target/docs/CLAUDE.md" || fail 'excluded Claude docs changed'
fi

# グローバル設定の配置と、再実行時の保持を確認する。
for skill_path in "$repository_dir"/codex-skills/*; do
  [ -d "$skill_path" ] || continue
  [ "$(readlink "$HOME/.codex/skills/${skill_path##*/}")" = "$skill_path" ] || fail 'wrong skill link'
done
[ "$(readlink "$HOME/.codex/AGENTS.md")" = "$repository_dir/AGENTS.md" ] || fail 'wrong AGENTS link'
for agent_path in "$repository_dir"/codex-agents/*; do
  [ -f "$agent_path" ] || continue
  destination="$HOME/.codex/agents/${agent_path##*/}"
  [ ! -L "$destination" ] && cmp -s "$agent_path" "$destination" || fail 'agent was not copied'
done
snapshot_tree "$HOME" "$temporary_root/home-before"
run_installer "$preserve_target" 1 "$temporary_root/repeat-output" || fail 'global repeat failed'
snapshot_tree "$HOME" "$temporary_root/home-after"
cmp -s "$temporary_root/home-before" "$temporary_root/home-after" || fail 'repeat modified HOME'

# 各配置先について通常ファイル、ディレクトリ、各種リンクを保持する。
for kind in file directory same-link other-link broken-link; do
  case_home="$temporary_root/home-$kind"
  mkdir -p "$case_home/.codex/skills" "$case_home/.codex/agents"
  cp "$repository_dir/codex-config.toml" "$case_home/.codex/config.toml"
  for source in "$repository_dir/AGENTS.md" "$repository_dir"/codex-skills/* "$repository_dir"/codex-agents/*; do
    case "$source" in
      */codex-skills/*) destination="$case_home/.codex/skills/${source##*/}" ;;
      */codex-agents/*) destination="$case_home/.codex/agents/${source##*/}" ;;
      *) destination="$case_home/.codex/AGENTS.md" ;;
    esac
    case "$kind" in
      file) printf 'preserve\n' > "$destination" ;;
      directory) mkdir "$destination" ;;
      same-link) ln -s "$source" "$destination" ;;
      other-link) ln -s "$repository_dir/README.md" "$destination" ;;
      broken-link) ln -s "$temporary_root/missing" "$destination" ;;
    esac
  done
  snapshot_tree "$case_home" "$temporary_root/case-before"
  case_target="$temporary_root/target-$kind"
  mkdir "$case_target"
  HOME="$case_home" run_installer "$case_target" 1 "$temporary_root/case-output" || fail "$kind: skip failed"
  snapshot_tree "$case_home" "$temporary_root/case-after"
  cmp -s "$temporary_root/case-before" "$temporary_root/case-after" || fail "$kind: existing paths changed"
  [ -f "$case_target/Cargo.toml" ] || fail "$kind: harness did not continue"
done

fresh_home="$temporary_root/fresh-home"
fresh_target="$temporary_root/fresh-target"
mkdir "$fresh_home" "$fresh_target"
HOME="$fresh_home" run_installer "$fresh_target" 1 "$temporary_root/fresh-output" --dry-run || fail 'fresh dry-run failed'
[ -z "$(find "$fresh_home" "$fresh_target" -mindepth 1 -print -quit)" ] || fail 'fresh dry-run wrote files'
grep -Fq '予定: リンク:' "$temporary_root/fresh-output" || fail 'dry-run omitted links'
grep -Fq '予定: コピー:' "$temporary_root/fresh-output" || fail 'dry-run omitted copies'
# 1 項目のスキップ後も、未配置のリンクとコピーを作成する。
partial_home="$temporary_root/partial-home"
partial_target="$temporary_root/partial-target"
mkdir -p "$partial_home/.codex" "$partial_target"
printf 'preserve\n' > "$partial_home/.codex/AGENTS.md"
HOME="$partial_home" run_installer "$partial_target" 1 "$temporary_root/partial-output" || fail 'partial skip failed'
grep -Fxq preserve "$partial_home/.codex/AGENTS.md" || fail 'partial skip changed AGENTS'
for skill_path in "$repository_dir"/codex-skills/*; do
  [ -d "$skill_path" ] || continue
  [ "$(readlink "$partial_home/.codex/skills/${skill_path##*/}")" = "$skill_path" ] || fail 'skip prevented skill link'
done
for agent_path in "$repository_dir"/codex-agents/*; do
  [ -f "$agent_path" ] || continue
  cmp -s "$agent_path" "$partial_home/.codex/agents/${agent_path##*/}" || fail 'skip prevented agent copy'
done
snapshot_tree "$partial_home" "$temporary_root/partial-before"
HOME="$partial_home" run_installer "$partial_target" 1 "$temporary_root/partial-output" --dry-run || fail 'existing dry-run failed'
snapshot_tree "$partial_home" "$temporary_root/partial-after"
cmp -s "$temporary_root/partial-before" "$temporary_root/partial-after" || fail 'existing dry-run modified HOME'
grep -Fq 'スキップ:' "$temporary_root/partial-output" || fail 'dry-run omitted skip'

# ハーネスの競合があればグローバル配置も開始しない。
mkdir "$fresh_target/.codex"
printf 'invalid\n' > "$fresh_target/.codex/hooks.json"
if HOME="$fresh_home" run_installer "$fresh_target" 1 "$temporary_root/fresh-conflict"; then
  fail 'fresh conflict succeeded'
fi
[ -z "$(find "$fresh_home" -mindepth 1 -print -quit)" ] || fail 'conflict modified HOME'

# サブプロセス単位でホームを隔離し、TOML の値と実ファイルを検証する。
if ! python3 - "$repository_dir" "$temporary_root" <<'PY'
import os
import stat
import subprocess
import sys
from pathlib import Path

import tomlkit

repository = Path(sys.argv[1])
root = Path(sys.argv[2]) / "config-cases"
root.mkdir()
template = tomlkit.parse((repository / "codex-config.toml").read_text())
python = sys.executable


def case(name, content=None):
    folder = root / name
    home = folder / "home"
    target = folder / "target"
    home.mkdir(parents=True)
    target.mkdir()
    config = home / ".codex/config.toml"
    if content is not None:
        config.parent.mkdir()
        config.write_bytes(content)
    return home, target, config


def snapshot(folder):
    result = {}
    for path in folder.rglob("*"):
        info = path.lstat()
        result[str(path.relative_to(folder))] = (
            info.st_mode, info.st_mtime_ns,
            os.readlink(path) if path.is_symlink() else
            path.read_bytes() if path.is_file() else None,
        )
    return result


def run(paths, *, dry=False, success=True, command_dir=None, help_only=False):
    home, target, _ = paths
    environment = dict(os.environ, HOME=str(home))
    if command_dir:
        environment["PATH"] = str(command_dir) + os.pathsep + environment["PATH"]
    args = [str(repository / "install.sh")]
    if dry:
        args.append("--dry-run")
    if help_only:
        args.append("--help")
    result = subprocess.run(args, input=f"{target}\n1\n", text=True,
                            capture_output=True, env=environment)
    assert (result.returncode == 0) == success, result.stdout + result.stderr
    return result.stdout + result.stderr


def assert_settings(actual, expected):
    for key, value in expected.items():
        if isinstance(value, dict):
            assert_settings(actual[key], value)
        else:
            assert type(actual[key]) is type(value) and actual[key] == value, key


fresh = case("fresh")
before = snapshot(fresh[0]), snapshot(fresh[1])
assert "設定新規作成" in run(fresh, dry=True)
assert before == (snapshot(fresh[0]), snapshot(fresh[1]))
run(fresh)
assert_settings(tomlkit.parse(fresh[2].read_text()).unwrap(), template.unwrap())
assert stat.S_IMODE(fresh[2].stat().st_mode) == 0o600
assert not list(fresh[2].parent.glob("config.toml.bak.*"))

original = b'''# keep header\r
model = "old" # keep model comment\r
custom = [1, 2]\r
[features.multi_agent_v2]\r
min_wait_timeout_ms = 1\r
extra = "keep" # keep extra comment\r
[agents]\r
enabled = false\r
max_concurrent_threads_per_session = 4.0\r
[projects."/example"]\r
trust_level = "trusted"\r
'''
merged = case("merge", original)
config = merged[2]
config.chmod(0o640)
sentinel = config.parent / "config.toml.bak.existing"
sentinel.write_bytes(b"previous backup")
before = snapshot(merged[0]), snapshot(merged[1])
assert "バックアップ:" in run(merged, dry=True)
assert before == (snapshot(merged[0]), snapshot(merged[1]))
run(merged)
actual = tomlkit.parse(config.read_text()).unwrap()
assert_settings(actual, template.unwrap())
assert actual["custom"] == [1, 2]
assert actual["features"]["multi_agent_v2"]["extra"] == "keep"
assert actual["projects"]["/example"]["trust_level"] == "trusted"
for comment in ("# keep header", "# keep model comment", "# keep extra comment"):
    assert comment in config.read_text()
backups = [p for p in config.parent.glob("config.toml.bak.*") if p != sentinel]
assert len(backups) == 1 and backups[0].read_bytes() == original
assert stat.S_IMODE(backups[0].stat().st_mode) == 0o640
assert stat.S_IMODE(config.stat().st_mode) == 0o640
before = snapshot(merged[0]), snapshot(merged[1])
assert "変更なし" in run(merged)
run(merged, dry=True)
assert before == (snapshot(merged[0]), snapshot(merged[1]))
config.write_text(config.read_text().replace('model = "gpt-6-astra"', 'model = "older"'))
second_original = config.read_bytes()
run(merged)
assert sentinel.read_bytes() == b"previous backup"
assert backups[0].read_bytes() == original
assert len(list(config.parent.glob("config.toml.bak.*"))) == 3
assert any(p.read_bytes() == second_original for p in config.parent.glob("config.toml.bak.*"))

# 等価な明示テーブル、ドット付き・インライン表記、CRLF は再実行でも保持する。
for name, content in (
    ("explicit", config.read_bytes().replace(b"\n", b"\r\n")),
    ("dotted", (repository / "codex-config.toml").read_bytes()),
    ("inline", b'features = {multi_agent_v2 = {min_wait_timeout_ms = 2, extra = 7}}\n'),
):
    paths = case(name, content)
    run(paths)
    assert_settings(tomlkit.parse(paths[2].read_text()).unwrap(), template.unwrap())
    if name != "inline":
        assert paths[2].read_bytes() == content
        assert not list(paths[2].parent.glob("config.toml.bak.*"))
    before = snapshot(paths[0])
    run(paths)
    assert snapshot(paths[0]) == before

invalid_cases = {
    "syntax": b"[broken\n",
    "encoding": b"\xff",
    "features-type": b"features = false\n",
    "wait-type": b"[features]\nmulti_agent_v2 = []\n",
    "context-type": b"[features]\ncontext_management = 1\n",
    "agents-type": b"agents = true\n",
}
for name, content in invalid_cases.items():
    paths = case(name, content)
    before = snapshot(paths[0]), snapshot(paths[1])
    run(paths, success=False)
    run(paths, dry=True, success=False)
    assert before == (snapshot(paths[0]), snapshot(paths[1]))

for kind in ("link", "broken-link", "directory", "unreadable"):
    paths = case(kind, b'model = "old"\n')
    config = paths[2]
    if kind == "unreadable":
        config.chmod(0)
    else:
        config.unlink()
        if kind == "directory":
            config.mkdir()
        else:
            destination = config.parent / "other.toml"
            if kind == "link":
                destination.write_bytes(original)
            config.symlink_to(destination)
    # 読み取り不能なファイルは snapshot で読み込まず個別に検証する。
    before = None if kind == "unreadable" else snapshot(paths[0])
    run(paths, success=False)
    run(paths, dry=True, success=False)
    assert not list(paths[1].iterdir())
    if before is not None:
        assert before == snapshot(paths[0])
    else:
        assert stat.S_IMODE(config.stat().st_mode) == 0
        config.chmod(0o600)
        assert config.read_bytes() == b'model = "old"\n'

conflict = case("harness-conflict", original)
(conflict[1] / ".codex").mkdir()
(conflict[1] / ".codex/hooks.json").write_text("invalid")
before = snapshot(conflict[0]), snapshot(conflict[1])
run(conflict, success=False)
assert before == (snapshot(conflict[0]), snapshot(conflict[1]))

# 外部コマンド境界だけで失敗を注入し、元設定とバックアップを確認する。
for failure in ("dependency", "backup", "replace"):
    paths = case(failure, original)
    commands = paths[0].parent / "bin"
    commands.mkdir()
    if failure == "dependency":
        import shlex
        executable = commands / "python3"
        executable.write_text("#!/bin/sh\nexec " + shlex.quote(python) + ' -S "$@"\n')
    else:
        executable = commands / ("cp" if failure == "backup" else "mv")
        pattern = "*.bak.*" if failure == "backup" else "*/config.toml"
        executable.write_text(
            '#!/bin/sh\nfor last do :; done\ncase "$last" in\n' + pattern +
            ') echo "injected failure" >&2; exit 1;;\nesac\nexec /bin/' +
            executable.name + ' "$@"\n'
        )
    executable.chmod(0o755)
    output = run(paths, success=False, command_dir=commands)
    assert paths[2].read_bytes() == original
    assert not list(paths[1].iterdir())
    assert not (paths[0] / ".codex/AGENTS.md").exists()
    assert not list(paths[2].parent.glob("config.toml.tmp.*"))
    backups = list(paths[2].parent.glob("config.toml.bak.*"))
    if failure == "replace":
        assert len(backups) == 1 and backups[0].read_bytes() == original
    else:
        assert not backups
    if failure == "dependency":
        assert "pip install -r requirements.txt" in output
        run(paths, command_dir=commands, help_only=True)
print("All Codex config tests passed.")
PY
then
  fail 'Codex config integration tests failed'
fi

if [ "$failures" -ne 0 ]; then
  printf '%s test(s) failed\n' "$failures" >&2
  exit 1
fi

printf 'All installer tests passed.\n'
