# AGENTS.md

各社のエージェントや個々のプロジェクトに依存しない共通部分をハーネスエンジニアリングの基礎として記述しました。

## AGENTS.md の使い方

```shell
# setup for Codex (CLI and App)
ln -s "$(pwd)/AGENTS.md" "$HOME/.codex/AGENTS.md"

# setup for Claude Code
ln -s "$(pwd)/AGENTS.md" "$HOME/.claude/CLAUDE.md"

# setup for Copilot CLI
ln -s "$(pwd)/AGENTS.md" "$HOME/.copilot/copilot-instruction.md"
```

## ハーネス

組み込み C 言語と Rust のハーネスの雛形を試験的に残しました。

### 組み込み C (Pico-SDK) のハーネスの使い方

自動整形とビルドに焦点を当てています。

```shell
# Codex CLI
cp harness/pico-sdk/.codex/hooks.json your_repo/.codex/
# Copilot CLI
cp harness/pico-sdk/.github/hooks/hooks.json your_repo/.github/hooks/

cp -pr harness/pico-sdk/.agent-hooks your_repo/
cat harness/pico-sdk/.gitignore >> your_repo/.gitignore
```

### 組み込み C (ESP-IDF) のハーネスの使い方

ESP-IDF 外のツール (clang-formatter, cppcheck, clang-tidy など) で Format, Lint チェックすると誤検知が多い  (ESP-IDF が想定している状態と違う) ので `idf.py` を経由してチェックするために `idf.py build` と `idf.py size` を検知するようにしました。

なお、`idf.py clang-format` は開発中のため除外しました。

```shell
# Codex CLI
cp harness/esp-idf/.codex/hooks.json your_repo/.codex/
# Copilot CLI
cp harness/esp-idf/.github/hooks/hooks.json your_repo/.github/hooks/

cp -pr harness/esp-idf/.agent-hooks your_repo/
cat harness/esp-idf/.gitignore >> your_repo/.gitignore
```

### Rust のハーネスの使い方

パニックになる可能性が高いコードをエラー扱いするように Linter 設定をしています。

```shell
# Codex CLI
cp harness/rust/.codex/hooks.json your_repo/.codex/
# Copilot CLI
cp harness/rust/.github/hooks/hooks.json your_repo/.github/hooks/

cp -pr harness/.agent-hooks your_repo/
cat harness/rust/Makefile >> your_repo/Makefile
cat harness/rust/AGENTS.md >> your_repo/AGENTS.md
cat harness/rust/Cargo.toml >> your_repo/Cargo.toml
cat harness/rust/.gitignore >> your_repo/.gitignore
```

---

## おまけ: GitHub Copilot の日本語化

コミットメッセージやレビューコメントを一括で日本語化します。コミットメッセージは VS Code 上だし、レビューコメントは GitHub 上だし、一括設定でどうするのかと言いますと `~/Library/Application Support/Code/User/settings.json` を以下のようにします。

```json
{
  "github.copilot.chat.localeOverride": "ja",
  "github.copilot.chat.commitMessageGeneration.instructions": [
    {
      "text": "ミットメッセージは必ず日本語で生成すること。必ず Conventional Commits 形式を使用し、以下の基準で prefix を選択すること：\n- feat: 新機能の追加\n- fix: バグ修正\n- docs: ドキュメントのみの変更\n- refactor: 動作を変えないコードの整理・リネーム・移動\n- chore: ビルド設定・依存関係・ツール類の変更\n- test: テストの追加・修正\n- style: フォーマット・インデントなど動作に影響しない変更\nfeat と docs は本当に該当する場合のみ使用し、安易に選ばないこと。件名は1行で簡潔に書き、本文に変更内容の概要を含めること。本文最後に <!-- PR レビューは日本語で行うこと --> を追記すること。"
    }
  ]
}
```

このようにすると PR 作成時の説明欄に PR レビューは日本語で行う意図が入ります。PR の説明欄にこのような文があると GitHub Copilot は指示と認識して日本語で PR レビューするようになります。これなら GitHub の設定で PR レビューを自動的に発火させても安心です。
