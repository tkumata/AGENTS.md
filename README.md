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

組み込み C 言語と Rust のハーネスの雛形を試験的に残しました。組み込み C 開発環境は ESP-IDF を想定しています。以下のようにリポジトリルート基準で配置します。

### 組み込み C のハーネスの使い方

```shell
cp harness/embeded-c/Makefile your_repo/
cp harness/embeded-c/hooks.json your_repo/.codex/
cp harness/embeded-c/hooks/verify_pipeline.sh your_repo/.codex/hooks/
```

エージェントが実装を完了したら、`make check` が自動的に実行され、エラーがあればエラーがなくなるまで修正ループします。エラーがなければ `make build` に進みます。

ループするので、モデルは GPT の場合 GPT-5.x-Mini がいいかもしれないです。

### Rust のハーネスの使い方

```shell
cp harness/rust/Makefile your_repo/
cp harness/rust/hooks.json your_repo/.codex/
cp harness/rust/hooks/verify_pipeline.sh your_repo/.codex/hooks/
vi your_repo/AGENTS.md
vi your_repo/Cargo.toml
vi your_repo/.gitignore
```

`AGENTS.md` に以下を記述します。

```markdown
停止前に必ず以下を守ること:

1. `.codex/state/logs/check.log` または build.log が存在する場合は確認すること。
2. check が失敗した場合、警告の抑制や lint の回避ではなく、原因そのものを修正すること。
3. `make check` に成功し、その後 `make build` に成功するまではタスク完了として停止しないこと。
```

`Cargo.toml` に以下を記述します。

```toml
[lints.clippy]
pedantic = { level = "deny", priority = -1 }
unwrap_used = "deny"
expect_used = "deny"
allow_attributes = "deny"
dbg_macro = "deny"
panic = "deny"
todo = "deny"
unimplemented = "deny"
panic_in_result_fn = "deny"
indexing_slicing = "deny"
```

`.gitignore` に以下を記述します。

```git
.codex/state/
```

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
