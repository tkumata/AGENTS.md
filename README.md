# AGENTS.md

コーディングエージェントが暴走しないよう私なりの `AGENTS.md` を公開します。しかし、各社のエージェントやプロジェクトなどに依存させないようにするため、本リポジトリで一元管理するようにしました。

## AGENTS.md の使い方

```shell
# setup for Codex
ln -s "$(pwd)/AGENTS.md" "$HOME/.codex/AGENTS.md"

# setup for Claude Code
ln -s "$(pwd)/AGENTS.md" "$HOME/.claude/CLAUDE.md"

# setup for Gemini and Antigravity
ln -s "$(pwd)/AGENTS.md" "$HOME/.gemini/GEMINI.md"
```

† 2026/03/06 Antigravity は `AGENTS.md` もサポートしました。

† 2026/03/18 AG 用に分割しましたが、AG というか AI Pro プランは残念なことになり利用をやめたため検証はしてません。

### 構造

人間向けではなく機械向けに記述するには以下に注意する必要があります。

- 曖昧語を減らす
- 手続き化
- 優先順位を明示
- フェーズ判定をアルゴリズム化
- 違反時の挙動を定義
- 文書の構造

「ルール」と「そのルールが破られたときの挙動」をセットで書くと、LLM の遵守率が上がる、らしいです。

### 注釈

Google Antigravity の日本語アーティファクト生成が全く安定しないので、言語に関する指示は最上部に移動しました。また、禁止事項にもアーティファクトについての記述を追加しました。

## おまけ

### GitHub Copilot を一括で日本語化する

コミットメッセージや PR レビューのコメントを一括で日本語化します。コミットメッセージは VS Code 上だし、PR レビューは GitHub 上だし、一括設定でどうするのかと言いますと `~/Library/Application Support/Code/User/settings.json` を以下のようにします。

```json
{
  "github.copilot.chat.localeOverride": "ja",
  "github.copilot.chat.commitMessageGeneration.instructions": [
    {
      "text": "コミットメッセージは必ず日本語で生成する。Conventional Commits 形式（feat, fix, chore, refactor, docs など）を使用する。件名は1行で簡潔に書くが、どんなに小さな変更でも必ず本文を追加すること。本文には必ず以下を含める：(1) PRタイトル (2) 変更内容の概要 (3) 「<!-- PRレビューは日本語で行うこと -->」というコメント"
    }
  ]
}
```

このようにすると PR 作成時の説明欄に PR レビューは日本語で行う意図が入ります。PR の説明欄にこのような文があると GitHub Copilot は指示と認識して日本語で PR レビューするようになります。これなら GitHub の設定で PR レビューを自動的に発火させても安心です。
