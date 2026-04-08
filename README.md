# AGENTS.md

エージェントやプロジェクトなどに依存しない最低限のルールを作りました。

## AGENTS.md の使い方

```shell
# setup for Codex (CLI and App)
ln -s "$(pwd)/AGENTS.md" "$HOME/.codex/AGENTS.md"

# setup for Claude Code
ln -s "$(pwd)/AGENTS.md" "$HOME/.claude/CLAUDE.md"

# setup for Copilot CLI
ln -s "$(pwd)/AGENTS.md" "$HOME/.copilot/copilot-instruction.md"
```

† 2026/03/06 Antigravity は `AGENTS.md` もサポートしました。

† 2026/03/18 AG 用に分割しましたが、AG というか AI Pro プランは残念なことになり利用をやめたため検証はしてません。

† 2026/04/04 AG や Gemini を考慮することを諦めました。

### 構造

人間向けではなく機械向けに記述するには以下に注意する必要があります。

- 曖昧語を減らす
- 手続き化
- 優先順位を明示
- フェーズ判定をアルゴリズム化
- 違反時の挙動を定義
- 文書の構造

「ルール」と「そのルールが破られたときの挙動」をセットで書くと、LLM の遵守率が上がる、らしいです。

## おまけ

### GitHub Copilot の日本語化 (1)

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
