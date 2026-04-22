# AGENTS.md

各社のエージェントや個々のプロジェクトに依存しない共通部分をハーネスエンジニアリングの基礎として記述しました。このような書き方をすることで各サブエージェントが協業しました。Codex と Copilot で確認してます。

ハーネスエンジニアリングの核心部分はプロジェクトに依存するため、本プロジェクトでは割愛します。一応 harness ディレクトリに組み込み C で利用できそうな記述や設定方法を残しています。

Codex の Plus プランの場合、5時間制限をあっという間に使い切るので注意が必要です。

## AGENTS.md の使い方

```shell
# setup for Codex (CLI and App)
ln -s "$(pwd)/AGENTS.md" "$HOME/.codex/AGENTS.md"

# setup for Claude Code
ln -s "$(pwd)/AGENTS.md" "$HOME/.claude/CLAUDE.md"

# setup for Copilot CLI
ln -s "$(pwd)/AGENTS.md" "$HOME/.copilot/copilot-instruction.md"
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
