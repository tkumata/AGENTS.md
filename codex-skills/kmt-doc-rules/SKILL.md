---
name: kmt-doc-rules
description: brainstorm、brain dump、開発要求を整理し、実装前の active plan と必要な ADR を作成し、実装完了後に docs/current/ を確定する。実装は行わない。
---
# Kmt Doc Rules

ユーザの要求を整理し、開発に必要な要求、仕様、設計、計画、設計判断の文書を整備する。

実装担当が追加の仕様判断をせずに実装でき、将来の人間またはエージェントが現在状態、変更履歴、実行状態を追跡できる状態にする。

## Rules

- ユーザの意図を保存する。
- 未決定事項を勝手に確定しない。
- 例や候補を要求として扱わない。
- 必要な情報だけを調査する。
- リポジトリ全体を網羅的に調査しない。
- `docs/current/` は関連する文書・節だけ読む。
- ADR は関連する判断が存在する場合だけ読む。
- 過去 plan は現在案件に必要な場合だけ読む。
- 内容が変わる文書だけを作成または更新する。
- 同じ説明を複数の文書へ重複して記載しない。
- 文書化中はソースコードを変更しない。
- `docs/current/` を未実装の将来状態へ先行更新しない。

## Documentation

ドキュメントは以下の構成で運用する。

```text
docs/
├── current/
│   ├── REQUIREMENTS.md
│   ├── SPECIFICATIONS.md
│   ├── DESIGN.md
│   └── PRD.md
├── plans/
│   ├── active/
│   └── completed/
└── adr/
```

- `docs/current/` は現在実装済みの要求、仕様、設計、製品要件の正本とする。
- `docs/plans/` は案件ごとの変更計画、承認状態、実行状態、検証結果の履歴とする。
- `docs/adr/` は長期的な設計判断の履歴とする。
- `current/` に変更履歴、一時的な実装手順、作業進捗を記載しない。
- `plans/` を現在仕様の正本として扱わない。
- 長期的な変更コストを持つ重要な設計判断だけ ADR に残す。
- 該当する内容がない文書は作成しない。

### Current Documents

実装完了後、実装済み状態に変更がある文書だけを作成または更新する。

- `REQUIREMENTS.md`: 機能要求、非機能要求、制約、受け入れ条件
- `SPECIFICATIONS.md`: 外部動作、入出力、状態遷移、エラー時動作、境界条件
- `DESIGN.md`: 責務分割、依存方向、外部境界、データ構造、状態管理
- `PRD.md`: 製品背景、対象ユーザ、課題、ゴール、スコープ、ユーザストーリー、成功指標

実装前の変更予定は active plan に記述し、`docs/current/` は変更しない。

### Active Plan

案件ごとの実行計画を `docs/plans/active/YYYY-MM-DD-short-name.md` に作成する。

以下を基本形とし、不要な節は省略する。

```markdown
# <title>

## Status

- Phase: planning
- Last Updated: YYYY-MM-DD
- Next Action:
- Blocked By: none

## Approval

- Status: pending
- Approved Scope: none

## Goal

## Scope

## Non-goals

## Required Behavior

## Design Decisions

## Implementation Tasks

### Task 1: <name>

- Status: pending
- Objective:
- Scope:
- Acceptance Criteria:
- Verification:

## Progress

- [ ] Task 1: <name>

## Verification Status

- Task 1: not-run
- Repository validation: not-run

## Implementation Notes

## Open Questions

## References
```

`Phase` は次のいずれかとする。

- `planning`
- `awaiting_approval`
- `approved`
- `implementing`
- `blocked`
- `verifying`
- `finalizing_docs`
- `completed`

`Approval.Status` は次のいずれかとする。

- `pending`
- `approved`

各 Task は以下を満たすこと。

- 目的が1つ
- 主要な変更が1つ
- 独立して検証可能
- 新しい仕様判断を必要としない

再開時に会話履歴へ依存しないよう、`Status`、`Approval`、`Progress`、`Verification Status`、`Next Action` を常に現在状態へ保つ。

### ADR

長期的な変更コストを持つ重要な設計判断では、1判断につき1つの ADR を作成する。

既存の ADR 構成や命名規則がある場合はそれに従う。ない場合は `docs/adr/NNNN-short-title.md` を使用する。

ADR には必要に応じて以下を記載する。

- Status
- Date
- Context
- Decision
- Alternatives considered
- Consequences
- Related plans
- Supersedes
- Superseded by

既存 ADR の Decision を上書きしない。判断を変更する場合は新しい ADR を作成する。
既存 ADR は、参照関係や Status など履歴を壊さない情報だけを必要に応じて更新する。

## Workflow

### Planning

1. ユーザ要求を Goal / Scope / Non-goals / Requirements / Unknowns に整理する。
2. 変更に直接関係する既存文書とコードだけを確認する。
3. 実装結果を左右する未決定事項を特定する。
4. 必要なら `investigate` の調査結果を利用する。
5. 確定した変更予定を要求、仕様、設計、製品要件、設計判断、実行計画に分類する。
6. 長期的な設計判断がある場合は ADR を作成する。
7. `docs/plans/active/YYYY-MM-DD-short-name.md` を作成する。
8. active plan と ADR の整合性を確認する。
9. Blocking な未決定事項がなく、実装担当が追加判断なしで作業できる状態にする。
10. `Phase: awaiting_approval`、`Approval.Status: pending` として終了する。

Planning では `docs/current/` を変更しない。

### Finalization

実装と必要な検証が完了した後に実施する。

1. active plan の Progress、Verification Status、Implementation Notes を確認する。
2. 実装済みの動作と文書化予定の内容が一致していることを確認する。
3. 必要な `docs/current/` を実装済み状態へ同期する。
4. 必要な ADR の参照関係または Status を更新する。
5. active plan の未解決事項と検証結果を確定する。
6. 完了条件を満たす場合は `Phase: completed` とする。
7. active plan を `docs/plans/completed/` へ移動する。

実装結果が計画と異なる場合は、推測で current 文書を合わせず、必要な再計画または調査を行う。

## Done

### Planning Done

以下を満たせば実装前の文書化を終了する。

- Scope が明確
- 必要な要求と振る舞いが明確
- Blocking な未決定事項がない
- 必要な active plan が作成されている
- 必要な ADR が作成されている
- 各 Task が実装可能な大きさ
- Acceptance Criteria が検証可能
- 文書間に矛盾や不要な重複がない
- `Phase: awaiting_approval`
- `Approval.Status: pending`

### Finalization Done

以下を満たせば案件を完了する。

- 全 Task が完了している
- 必要な検証が成功している
- 必要な `docs/current/` が実装済み状態と一致している
- ADR の履歴が保たれている
- Blocking な未解決事項がない
- active plan が `completed/` へ移動されている
