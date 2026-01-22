# AGENTS.md

コーディングエージェントが暴走しないよう AGENTS.md を用意する必要がありますが、エージェント非依存・プロジェクト非依存などの共通部分を二重管理にならないよう本リポジトリで管理します。

皆様の自慢の AGENTS.md / GEMINI.md / CLAUDE.md などありましたらご紹介いただけると幸いです。

## 使い方

```shell
# setup for codex
ln -sf "$(pwd)/AGENTS.md" "$HOME/.codex/AGENTS.md"

# setup for claude
ln -sf "$(pwd)/AGENTS.md" "$HOME/.claude/CLAUDE.md"

# setup for gemini and Antigravity
ln -sf "$(pwd)/AGENTS.md" "$HOME/.gemini/GEMINI.md"
```

## 構造

人間向けではなく機械向けに記述するには以下に注意する必要があります。

- 曖昧語を減らす
- 手続き化
- 優先順位を明示
- フェーズ判定をアルゴリズム化
- 違反時の挙動を定義⭐️
- 文書の構造

「ルール」と「そのルールが破られたときの挙動」をセットで書くと、LLM　の遵守率が上がる、らしいです。

```markdown
# SYSTEM OVERRIDE

## PURPOSE (目的)

## DEFINITIONS (用語定義)

## PRIORITY ORDER (優先順位ルール)

## PROHIBITIONS (禁止事項)

## PHASE RULES (フェーズ判定)

## NEW DEVELOPMENT PROTOCOL

## MAINTENANCE PROTOCOL

## VIOLATION HANDLING (違反時の挙動)
```

## 注釈

Google Antigravity の日本語アーティファクト生成が全く安定しないので、言語に関する指示は最上部に移動しました。一回日本語でやりとりすると Google Antigravity を終了するまで日本語アーティファクトを作成するのですが、Antigravity を落とすと GEMINI.md があろうが英語アーティファクトになります。また Task は英語だけど Implementation Plan は日本語だったり、逆もあったりかなりフラストレーションが溜まります。
