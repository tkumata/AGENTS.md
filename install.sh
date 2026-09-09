#!/usr/bin/env bash

set -u

installer_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P) || exit 1
merge_helper="$installer_dir/merge.py"
dry_run=0
help_requested=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      if [ "$dry_run" -eq 1 ]; then
        printf 'エラー: オプションが重複しています: %s\n' "$1" >&2
        exit 1
      fi
      dry_run=1
      ;;
    --help)
      if [ "$help_requested" -eq 1 ]; then
        printf 'エラー: オプションが重複しています: %s\n' "$1" >&2
        exit 1
      fi
      help_requested=1
      ;;
    *)
      printf 'エラー: 不明なオプションです: %s\n' "$1" >&2
      exit 1
      ;;
  esac
  shift
done

if [ "$help_requested" -eq 1 ]; then
  if [ "$dry_run" -eq 1 ]; then
    printf 'エラー: --help は他のオプションと併用できません。\n' >&2
    exit 1
  fi
  printf 'Usage: %s [--dry-run]\n' "${0##*/}"
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  printf 'エラー: Python 3 が見つかりません。\n' >&2
  exit 1
fi
if [ ! -f "$merge_helper" ]; then
  printf 'エラー: マージスクリプトが見つかりません: %s\n' "$merge_helper" >&2
  exit 1
fi

printf 'インストール先プロジェクトのパス: '
if ! IFS= read -r target_input || [ -z "$target_input" ]; then
  printf 'エラー: インストール先を指定してください。\n' >&2
  exit 1
fi

if [ ! -d "$target_input" ]; then
  printf 'エラー: インストール先が存在するディレクトリではありません: %s\n' \
    "$target_input" >&2
  exit 1
fi

target_dir=$(CDPATH='' cd -- "$target_input" && pwd -P) || exit 1

printf '%s\n' '環境を選択してください:'
printf '%s\n' '  1) rust' '  2) pico-sdk' '  3) esp-idf'
printf '選択: '
if ! IFS= read -r environment_selection; then
  printf 'エラー: 環境を選択してください。\n' >&2
  exit 1
fi

case "$environment_selection" in
  1) environment=rust ;;
  2) environment=pico-sdk ;;
  3) environment=esp-idf ;;
  *)
    printf 'エラー: 無効な環境選択です: %s\n' "$environment_selection" >&2
    exit 1
    ;;
esac

source_dir="$installer_dir/harness/$environment"
if [ ! -d "$source_dir" ]; then
  printf 'エラー: ハーネステンプレートが見つかりません: %s\n' \
    "$source_dir" >&2
  exit 1
fi

template_path_selected() {
  case "$1" in
    .claude|.claude/*|.github|.github/*) return 1 ;;
    *) return 0 ;;
  esac
}

# 既存パスはリンク切れも含めて保持する。
install_global_file() {
  local source=$1 destination=$2 mode=$3
  if [ -e "$destination" ] || [ -L "$destination" ]; then
    printf 'スキップ: %s\n' "$destination"
    return 0
  fi
  if [ "$dry_run" -eq 1 ]; then
    printf '予定: %s: %s -> %s\n' "$mode" "$source" "$destination"
    return 0
  fi
  if ! mkdir -p -- "$(dirname -- "$destination")"; then
    printf 'エラー: 親ディレクトリを作成できません: %s\n' "$destination" >&2
    return 1
  fi
  if [ "$mode" = リンク ]; then
    ln -s -- "$source" "$destination" || return 1
  else
    cp -p -n -- "$source" "$destination" || return 1
  fi
  printf '%s: %s\n' "$mode" "$destination"
}

staging_dir=$(mktemp -d "${TMPDIR:-/tmp}/harness-installer.XXXXXX") || exit 1
trap 'rm -rf "$staging_dir"' EXIT HUP INT TERM

conflict_found=0
while IFS= read -r -d '' source_path; do
  relative_path=${source_path#"$source_dir"/}
  if ! template_path_selected "$relative_path"; then
    continue
  fi
  destination_path="$target_dir/$relative_path"

  if [ -L "$source_path" ]; then
    printf 'エラー: 未対応のテンプレートパスです: %s\n' "$relative_path" >&2
    conflict_found=1
  elif [ -d "$source_path" ]; then
    if { [ -e "$destination_path" ] || [ -L "$destination_path" ]; } && \
      { [ ! -d "$destination_path" ] || [ -L "$destination_path" ]; }; then
      printf 'エラー: 配置先と衝突しています: %s\n' "$relative_path" >&2
      conflict_found=1
    fi
  elif [ -f "$source_path" ]; then
    if [ -e "$destination_path" ] || [ -L "$destination_path" ]; then
      if [ -L "$destination_path" ] || [ ! -f "$destination_path" ]; then
        printf 'エラー: 配置先と衝突しています: %s\n' "$relative_path" >&2
        conflict_found=1
      elif ! cmp -s -- "$source_path" "$destination_path"; then
        staged_path="$staging_dir/$relative_path"
        if ! mkdir -p -- "$(dirname -- "$staged_path")"; then
          printf 'エラー: 一時ディレクトリを作成できません: %s\n' "$relative_path" >&2
          conflict_found=1
        elif ! merge_error=$(python3 "$merge_helper" merge "$relative_path" \
          "$destination_path" "$source_path" "$staged_path" 2>&1); then
          printf 'エラー: 配置先と衝突しています: %s (%s)\n' \
            "$relative_path" "$merge_error" >&2
          conflict_found=1
        fi
      fi
    fi
  else
    printf 'エラー: 未対応のテンプレートパスです: %s\n' "$relative_path" >&2
    conflict_found=1
  fi
done < <(find "$source_dir" -mindepth 1 -print0)

if [ "$conflict_found" -ne 0 ]; then
  exit 1
fi

if [ -z "${HOME:-}" ]; then
  printf 'エラー: HOME が設定されていません。\n' >&2
  exit 1
fi
install_global_file "$installer_dir/AGENTS.md" "$HOME/.codex/AGENTS.md" リンク || exit 1
for skill_path in "$installer_dir"/codex-skills/*; do
  [ -d "$skill_path" ] || continue
  install_global_file "$skill_path" "$HOME/.codex/skills/${skill_path##*/}" リンク || exit 1
done
for agent_path in "$installer_dir"/codex-agents/*; do
  [ -f "$agent_path" ] || continue
  install_global_file "$agent_path" "$HOME/.codex/agents/${agent_path##*/}" コピー || exit 1
done

if [ "$dry_run" -eq 1 ]; then
  copied_count=0
  merged_count=0
  while IFS= read -r -d '' source_path; do
    relative_path=${source_path#"$source_dir"/}
    if ! template_path_selected "$relative_path"; then
      continue
    fi
    destination_path="$target_dir/$relative_path"
    staged_path="$staging_dir/$relative_path"
    if [ ! -e "$destination_path" ]; then
      printf '予定: 新規: %s\n' "$relative_path"
      copied_count=$((copied_count + 1))
    elif [ -f "$staged_path" ] && ! cmp -s -- "$staged_path" "$destination_path"; then
      printf '予定: マージ: %s\n' "$relative_path"
      merged_count=$((merged_count + 1))
    fi
  done < <(find "$source_dir" -mindepth 1 -type f -print0)

  printf 'dry-run 完了: %s -> %s (新規: %s, マージ: %s)\n' \
    "$environment" "$target_dir" "$copied_count" "$merged_count"
  exit 0
fi

while IFS= read -r -d '' source_path; do
  relative_path=${source_path#"$source_dir"/}
  if ! template_path_selected "$relative_path"; then
    continue
  fi
  destination_path="$target_dir/$relative_path"
  if [ ! -d "$destination_path" ]; then
    if ! mkdir -- "$destination_path"; then
      printf 'エラー: ディレクトリを作成できません: %s\n' "$relative_path" >&2
      exit 1
    fi
  fi
done < <(find "$source_dir" -mindepth 1 -type d -print0)

copied_count=0
merged_count=0
while IFS= read -r -d '' source_path; do
  relative_path=${source_path#"$source_dir"/}
  if ! template_path_selected "$relative_path"; then
    continue
  fi
  destination_path="$target_dir/$relative_path"
  staged_path="$staging_dir/$relative_path"
  if [ ! -e "$destination_path" ]; then
    if ! cp -p -- "$source_path" "$destination_path"; then
      printf 'エラー: ファイルを配置できません: %s\n' "$relative_path" >&2
      exit 1
    fi
    copied_count=$((copied_count + 1))
  elif [ -f "$staged_path" ] && ! cmp -s -- "$staged_path" "$destination_path"; then
    temporary_path="$destination_path.harness-installer.$$"
    if { ! cp -p -- "$destination_path" "$temporary_path" || \
      ! cp -- "$staged_path" "$temporary_path"; } || \
      ! mv -- "$temporary_path" "$destination_path"; then
      rm -f -- "$temporary_path"
      printf 'エラー: 更新結果を配置できません: %s\n' "$relative_path" >&2
      exit 1
    fi
    merged_count=$((merged_count + 1))
  fi
done < <(find "$source_dir" -mindepth 1 -type f -print0)

printf 'インストール完了: %s -> %s (新規: %s, マージ: %s)\n' \
  "$environment" "$target_dir" "$copied_count" "$merged_count"
