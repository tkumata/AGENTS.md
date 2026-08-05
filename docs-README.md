# Documentation

リポジトリ内の文書を、次の3種類に分けて管理すること。

1. 現在有効な要求・仕様・設計
2. 開発案件ごとの実行計画と作業記録
3. 長期的な設計判断の履歴

既存の文書構成がある場合は、その構成と命名規則を優先すること。既存構成がない場合は、以下を標準とする。

```text
docs/
├── README.md
├── current/
│   ├── REQUIREMENTS.md
│   ├── SPECIFICATIONS.md
│   ├── DESIGN.md
│   └── PRD.md
├── plans/
│   ├── active/
│   └── completed/
└── adr/
    └── README.md
```

## Current documentation

`docs/current/` には、現在有効なシステム状態だけを記述する。

* `REQUIREMENTS.md`: システムが満たすべき機能要求、非機能要求、制約、受け入れ条件
* `SPECIFICATIONS.md`: 外部動作、入出力、状態遷移、エラー時動作、境界条件
* `DESIGN.md`: 責務分割、依存方向、外部境界、データ構造、状態管理
* `PRD.md`: 製品背景、対象ユーザー、課題、ゴール、スコープ、ユーザーストーリー、成功指標

これらの文書は、実装完了後の現在状態と一致するように更新すること。

変更履歴や一時的な実装手順を記載しないこと。該当する内容がない文書は作成しないこと。

## Execution plans

複数ファイルにまたがる変更、複数フェーズの変更、設計判断を伴う変更、または別セッションで継続する可能性がある変更では、案件ごとに実行計画を新規作成すること。

配置:

```text
docs/plans/active/YYYY-MM-DD-short-name.md
```

実行計画には、必要に応じて以下を記載すること。

* Status
* Objective
* Current state
* Scope
* Out of scope
* Approach
* Affected files
* Phases
* Success criteria
* Validation
* Risks
* Progress
* Decisions
* Outcome

各フェーズは独立して検証可能にすること。

別セッションで再開できるように、`Progress` に以下を残すこと。

* 完了したフェーズ
* 次に実行するフェーズ
* 変更済みのファイル
* 未解決事項
* 実行済みの検証
* 次に必要な検証

実装と検証が完了したら、StatusとOutcomeを更新し、文書を以下へ移動すること。

```text
docs/plans/completed/
```

完了済み実行計画は作業履歴として扱い、現在仕様の正本として使用しないこと。

単一ファイル内の明白な小変更など、継続用の作業記録が不要な場合は、実行計画を作成しなくてよい。

## Architecture Decision Records

長期的な変更コストを持つ重要な設計判断を行う場合は、ADRを1判断につき1ファイル作成すること。

配置:

```text
docs/adr/NNNN-short-title.md
```

ADRには以下を記載すること。

* Status
* Date
* Context
* Decision
* Alternatives considered
* Consequences
* Related plans
* Supersedes
* Superseded by

既存ADRの判断内容を上書きしないこと。

決定を変更する場合は新しいADRを作成し、以前のADRを `Superseded` に変更して相互参照を追加すること。

`docs/adr/README.md` に、ADR番号、題名、状態、日付の索引を維持すること。

## Synchronization rules

実装によって意味が変わる文書だけを更新すること。

同じ説明を複数の文書へ複製しないこと。必要な場合は正本となる文書を1つ決め、他の文書から参照すること。

空文書、将来利用するかもしれないだけの文書、実装内容をそのまま説明しただけの文書を作成しないこと。

文書と実装が矛盾する場合は、矛盾を明示し、どちらかを推測で正しいものとして扱わないこと。

作業完了前に以下を確認すること。

* 実行計画の成功条件を満たしている
* 必要な検証を実行している
* 現在有効な要求、仕様、設計を更新している
* 必要なADRを追加している
* 実行計画にOutcomeと再開不要な最終状態を記録している
* 実行計画を `completed` へ移動している
