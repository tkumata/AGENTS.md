---
name: kmt-doc-rules
description: brain dump を一回の文書化パスで整理・清書し、文書だけを作成する。実装は行わない。
---
# Kmt Doc Rules

ユーザの brain dump から意図を保ったまま実装可能な文書へ一度の整理・清書する。文書化後は承認待ちで停止し、実装後の再計画や Finalization はこのスキルで行わない。

## Rules

- ユーザの意図を保存する。
- 未決定事項、例、候補を要求や決定として扱わない。
- 重複、口語、順序の乱れを整理し、意味を変えずに清書する。
- 仮定を置く場合は仮定として明示し、実装結果を左右する不明点は Open Questions に残す。
- 実装に直接関係する既存文書とコードだけを確認する。
- リポジトリ全体、無関係な履歴、過去の計画を網羅的に調査しない。
- 内容が変わる文書だけを作成または更新する。
- 同じ説明を複数の文書へ重複して記載しない。
- 文書化中はソースコードを変更しない。
- 一回の bounded pass で成果物を作成し、追加の自動調査、再計画、整合性ループを開始しない。

## Artifact

- `docs/current/REQUIREMENTS.md`: 機能要求、非機能要求、制約、受け入れ条件が変わる場合
- `docs/current/SPECIFICATIONS.md`: 外部動作、入出力、状態遷移、エラー、境界条件が変わる場合
- `docs/current/DESIGN.md`: 責務分割、依存方向、外部境界、データ構造が変わる場合
- `docs/current/PRD.md`: 製品背景、対象ユーザ、ゴール、スコープ、成功指標が変わる場合
- `docs/adr/NNNN-short-title.md`: 長期的な変更コストを持つ設計判断がある場合
- `docs/plans/active/YYYY-MM-DD-short-name.md`: 複数ファイル、複数フェーズ、別セッションでの継続、またはユーザが計画を求めた場合

単一ファイルの明白な小変更や、計画を必要としない清書では active plan を作成しない。ADR の判断内容は上書きせず、判断を変更する場合は新しい ADR を作成する。

文書は下記の構成で管理・運用すること。

```text
docs/
├── current/                    # 現在有効な要求・仕様・設計
│   ├── DESIGN.md
│   ├── REQUIREMENTS.md
│   ├── PRD.md
│   └── SPECIFICATIONS.md
├── plans/
│   ├── active/                 # 進行中の実行計画
│   │   ├─ plan-2026-08-05.md
│   │   └─ plan-2026-08-06.md
│   └── completed/              # 完了した実行計画
│       ├─ plan-2026-07-30.md
│       └─ plan-2026-07-31.md
└── adr/                        # 1判断1ファイルの ADR
    ├─ 001-use-graphql.md
    └─ 002-use-rest-api.md
```

## One-pass Workflow

1. ユーザの brain dump から Goal / Scope / Non-goals / Requirements / Open Questions を抽出する。
2. 実装に直接関係する既存文書とコードだけを確認する。
3. 要求、仕様、設計、PRD、ADR、active plan を成果物とする。
4. 選んだ成果物を一度に作成または更新し、重複と矛盾を整理する。
5. 実装担当が判断できない未決定事項を Open Questions に残す。
6. 成果物、未決定事項、対象外、次の承認対象を短く報告して停止する。

## Active Plan

active plan を作成する場合は、次の最小構成を使う。不要な節は省略する。

```markdown
# <title>

## Status

- Phase: awaiting_approval
- Approval: pending

## Goal

## Scope

## Non-goals

## Required Behavior

## Tasks

### Task 1: <name>

- Objective:
- Scope:
- Acceptance Criteria:
- Verification:

### Task 2: <name>

- Objective:
- Scope:
- Acceptance Criteria:
- Verification:

## Open Questions

## References
```

各 Task は目的が 1 つで、主要な変更が 1 つであり、独立して検証可能でなければならない。Acceptance Criteria と Verification は観測可能な内容にする。

## Done

以下を満たしたら文書化を終了する。

- brain dump が重複なく清書されている
- Scope と Non-goals が明確である
- 必要な要求と振る舞いが文書化されている
- 未決定事項が Open Questions に残っている
- 成果物だけが作成または更新されている
- Acceptance Criteria と Verification が検証可能である
- active plan を作成した場合は `Phase: awaiting_approval`、`Approval: pending` である
- ソースコードを変更していない
