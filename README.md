# AGENTS.md

コーディングエージェントが暴走しないよう AGENTS.md を用意する必要がありますが、二重管理にならないように本リポジトリで管理します。

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

「ルール」と「そのルールが破られたときの挙動」をセットで書くと、LLMの遵守率が上がる、らしいです。

```markdown
# SYSTEM OVERRIDE

## PURPOSE (目的)

## DEFINITIONS (用語定義)

## PRIORITY ORDER (優先順位ルール)

## MANDATORY BEHAVIORS (必須挙動)

## PROHIBITIONS (禁止事項)

## PHASE RULES (フェーズ判定)

## NEW DEVELOPMENT PROTOCOL

## MAINTENANCE PROTOCOL

## VIOLATION HANDLING (違反時の挙動)
```

## 結果

- これまで Antigravity は、頑なに英語のレスポンス・アーティファクトなどだったが、思考プロセスとシステムエラー以外が日本語になった。
- Codex の無駄な質問が減少した。
