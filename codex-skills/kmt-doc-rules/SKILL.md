---
name: kmt-doc-rules
description: brain dump の整理・清書、または依頼された開発文書の作成・更新を行う。相談や方針確認だけの依頼は対象外。
---
# Kmt Doc Rules

ユーザが brain dump の整理・清書または開発文書化を求めた場合に、意図を保ったまま必要な文書へ一度だけ整理する。相談や方針確認だけの依頼では文書を生成しない。清書だけの依頼は実装承認待ちを作らずに完了する。このスキルで実装計画を文書化する場合は文書化の完了を報告し、承認されていない実装を開始しない。実装後の再計画や Finalization はこのスキルで行わない。

## Rules

- 未決定事項、例、候補を要求や決定として扱わない。
- 仮定を置く場合は仮定として明示し、実装結果を左右する不明点は Open Questions に残す。
- 不明点が残っていても、確定した要求、制約、判断は文書化する。
- 実装に直接関係する既存文書とコードだけを確認する。
- リポジトリ全体、無関係な履歴、過去の計画を網羅的に調査しない。
- 内容が変わる文書だけを作成または更新する。
- 同じ説明を複数の文書へ重複して記載しない。
- 文書化中はソースコードを変更しない。
- 文書化工程では、一回の bounded pass を完了したら、追加の自動調査、再計画、整合性ループを開始しない。

## Artifact

成果物は依頼の変更内容に該当するものだけを選ぶ。リポジトリに正本文書の名称、配置、テンプレート、承認状態の規約がある場合はそれを優先し、以下のパスは規約がない場合の既定例として扱う。承認は合意済みの範囲単位で扱い、新規・既存を問わず承認済み範囲を pending に戻さない。再承認が必要な変更部分は未承認として区別し、ユーザ承認なしに承認済みとして記録しない。

- `docs/current/REQUIREMENTS.md`: 機能要求、非機能要求、制約、受け入れ条件が変わる場合
- `docs/current/SPECIFICATIONS.md`: 外部動作、入出力、状態遷移、エラー、境界条件が変わる場合
- `docs/current/DESIGN.md`: 責務分割、依存方向、外部境界、データ構造が変わる場合
- `docs/current/PRD.md`: 製品背景、対象ユーザ、ゴール、スコープ、成功指標が変わる場合
- `docs/adr/NNNN-short-title.md`: 長期的な変更コストを持つ設計判断がある場合
- `docs/plans/active/YYYY-MM-DD-short-name.md`: 複数フェーズ、別セッションでの継続、承認範囲の管理、またはユーザが計画を求めた場合。複数ファイルだけを理由に必須としない。

単一ファイルの明白な小変更や、計画を必要としない清書では active plan を作成しない。active plan が完了した後の `completed` への移動や記録は実装後の完了処理であり、このスキルの成果物に含めない。ADR の判断内容は上書きせず、判断を変更する場合は新しい ADR を作成する。

## Workflow

1. 必要確認: Goal / Scope / Non-goals / Requirements / Open Questions を抽出し、実装に直接関係する既存文書とコードだけを確認する。
2. 整理・清書: 確定部分を必要な成果物へ反映し、仮定と実装担当が判断できない未決定事項を明示する。
3. 成果物確認: 選択した成果物だけを確認する。確認中に見つかった明白な誤記や矛盾は修正してよいが、新しい要件判断、追加調査、再計画は開始しない。
4. 報告: 文書化工程が終了したら、成果物、未決定事項、対象外、次の承認対象を短く報告する。文書化だけの依頼ではここで停止し、実装を含む依頼では依頼範囲と承認状態に従って後続作業を扱う。未承認の実装は開始せず承認待ちで停止する。清書だけの場合は実装承認待ちを報告しない。

### Active Plan Template

未承認の active plan を新規作成する場合は、次の最小構成を使う。不要な節は省略する。

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

### Task NN: <name>

- Objective:
- Scope:
- Acceptance Criteria:
- Verification:

## Open Questions

## References
```

各 Task は目的が 1 つで、主要な変更が 1 つであり、観測可能な完了条件（Acceptance Criteria）と検証方法（Verification）を記載する。検証が他の Task に依存する場合は、前提 Task や結合検証段階を明記する。

## Done

以下を満たしたら文書化を終了する。

- brain dump が重複なく清書されている
- Scope と Non-goals が明確である
- 成果物だけが作成または更新されている
- 計画など該当する成果物に Acceptance Criteria と Verification がある場合は、検証可能な内容である
- active plan を作成または更新した場合は、Artifact の承認保護原則に従って承認状態が記録されていることを確認する
- ソースコードを変更していない
