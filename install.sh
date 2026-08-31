#!/usr/bin/env bash

set -u

installer_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P) || exit 1
merge_helper="$installer_dir/merge.py"
docs_agents_source="$installer_dir/docs-AGENTS.md"
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
if [ ! -f "$docs_agents_source" ]; then
  printf 'エラー: docs-AGENTS.md が見つかりません: %s\n' "$docs_agents_source" >&2
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

printf '%s\n' 'エージェントを選択してください:'
printf '%s\n' '  1) Codex' '  2) Claude Code' '  3) Copilot CLI'
printf '選択: '
if ! IFS= read -r agent_selection; then
  printf 'エラー: エージェントを選択してください。\n' >&2
  exit 1
fi

case "$agent_selection" in
  1)
    agent_kind=codex
    docs_instruction_name=AGENTS.md
    ;;
  2)
    agent_kind=claude
    docs_instruction_name=CLAUDE.md
    ;;
  3)
    agent_kind=copilot
    docs_instruction_name=AGENTS.md
    ;;
  *)
    printf 'エラー: 無効なエージェント選択です: %s\n' "$agent_selection" >&2
    exit 1
    ;;
esac

source_dir="$installer_dir/harness/$environment"
if [ ! -d "$source_dir" ]; then
  printf 'エラー: ハーネステンプレートが見つかりません: %s\n' \
    "$source_dir" >&2
  exit 1
fi

docs_directory="$target_dir/docs"
docs_agents_destination="$docs_directory/$docs_instruction_name"
docs_relative_path="docs/$docs_instruction_name"
docs_link_needed=1
if [ -e "$docs_directory" ] || [ -L "$docs_directory" ]; then
  if [ ! -d "$docs_directory" ] || [ -L "$docs_directory" ]; then
    printf 'エラー: 配置先と衝突しています: docs\n' >&2
    exit 1
  fi
fi
if [ -L "$docs_agents_destination" ]; then
  if [ "$(readlink "$docs_agents_destination")" = "$docs_agents_source" ]; then
    docs_link_needed=0
  else
    printf 'エラー: 配置先と衝突しています: %s\n' "$docs_relative_path" >&2
    exit 1
  fi
elif [ -e "$docs_agents_destination" ]; then
  printf 'エラー: 配置先と衝突しています: %s\n' "$docs_relative_path" >&2
  exit 1
fi

template_path_selected() {
  case "$1" in
    .codex|.codex/*)
      [ "$agent_kind" = codex ]
      ;;
    .claude|.claude/*)
      [ "$agent_kind" = claude ]
      ;;
    .github|.github/*)
      [ "$agent_kind" = copilot ]
      ;;
    *)
      return 0
      ;;
  esac
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

if [ "$dry_run" -eq 1 ]; then
  copied_count=0
  merged_count=0
  if [ "$docs_link_needed" -eq 1 ]; then
    printf '予定: 新規: %s\n' "$docs_relative_path"
    copied_count=$((copied_count + 1))
  fi
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

if [ "$docs_link_needed" -eq 1 ] && [ ! -d "$docs_directory" ]; then
  if ! mkdir -- "$docs_directory"; then
    printf 'エラー: ディレクトリを作成できません: docs\n' >&2
    exit 1
  fi
fi

copied_count=0
merged_count=0
if [ "$docs_link_needed" -eq 1 ]; then
  if ! ln -s "$docs_agents_source" "$docs_agents_destination"; then
    printf 'エラー: symlink を配置できません: %s\n' "$docs_relative_path" >&2
    exit 1
  fi
  copied_count=$((copied_count + 1))
fi
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
