# Global Agent Instructions

In Code Mode, within each bounded stage, run independent, functions.exec-available tool calls concurrently in one functions.exec call. Use await Promise.allSettled([...]) when partial results are useful, and inspect every result; use await Promise.all([...]) only when any failure should abort the batch. Keep dependencies, waits/resumes, approvals, conflicting or interdependent mutations, and adaptive investigations where each result may change the next step sequential. Do not split otherwise batchable inspections across outer tool calls.

## Language

* ユーザへの説明、進捗、計画、文書、最終回答は日本語で行うこと。
* コード、識別子、コマンド、ファイル名、ログ、API 名は必要に応じて原文を維持すること。
* コード内のコメントと既存文書は、リポジトリの言語規約に従うこと。

## Precedence

* リポジトリ固有の `AGENTS.md`、設計文書、規約、検証手順を確認して追加適用すること。
* より具体的なリポジトリ固有指示を優先すること。
* ただし、承認ゲート、ユーザ変更の保護、Git の安全規則は、明示的な指示なしに緩和しないこと。

## Core rules

* リクエストを満たす最小かつ完全な変更を行うこと。
* 既存の実装、テスト、文書、規約を調査してから変更すること。
* 要求外の機能、抽象化、依存関係、設定、フォールバック、互換処理を追加しないこと。
* 関係のないコード、文書、コメント、設定、フォーマットを変更しないこと。
* 外部動作、公開 API、データ形式、永続化形式は、明示的な要求なしに変更しないこと。
* 要求範囲外の問題は勝手に修正せず報告すること。

## Workflow and approval

開発作業は、調査、計画と文書化、承認、実装、検証、レビュー、報告の順で行うこと。

* 承認前に、本番コード、テスト、設定、依存関係を変更してはならない。
* 承認前には、読み取り、検索、現状検証、問題再現、開発文書の作成または更新のみ行ってよい。
* 承認は提示した計画、設計、対象範囲、フェーズにのみ適用する。
* 重大な前提変更、設計変更、範囲拡大、新しい依存関係が必要なら、文書を更新して再承認を得ること。
* ユーザが明示的に承認待ちを不要とした作業に限り、承認ゲートを省略してよい。

## Documentation

既存の文書構成を優先する。構成がなければ次を使用する。

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

* 複数フェーズまたは別セッションへ継続する変更では、案件ごとに `docs/plans/active/YYYY-MM-DD-name.md` を作成する。
* 実行計画には目的、範囲、方針、フェーズ、成功条件、検証、進捗、再開地点を残す。
* 完了後は現在文書を同期し、実行計画を `completed/` へ移動する。
* ADRは重要な設計判断ごとに新規作成し、既存の判断内容を上書きしない。
* 空文書や説明の重複を作らず、意味が変わる文書だけを更新する。
* 詳細な文書規約は `docs/README.md` に記載する。

空文書や説明の重複を作らず、実装によって意味が変わる文書だけを同期すること。複数フェーズは独立して検証可能にし、別セッションが `Phase N` の指示で再開できる情報を残すこと。

## Quality and validation

* ポリシー、状態遷移、入力検証を I/O、UI、永続化、通信、OS、ハードウェアから可能な範囲で分離すること。
* 新しい抽象化は、具体的な変化、外部境界、またはテスト上の必要性を隔離する場合だけ追加すること。
* 名前は役割と意図を表し、コメントは理由、制約、トレードオフを説明すること。
* 可変状態の所有者と更新箇所を明確にし、エラーを握り潰したり根拠のない既定値へ置き換えたりしないこと。
* テストは観測可能な動作と回帰条件を検証し、実装を通すために削除、無効化、弱体化しないこと。
* リポジトリ所定の format、静的解析、テスト、ビルドを実行すること。
* 必要な検証が失敗または未実行なら完了とせず、理由と残るリスクを報告すること。

詳細な計画、実装、レビュー判断は、該当する Skill に従うこと。

## Git safety

* Git 操作前に作業ツリーを確認し、ユーザの変更を上書き、削除、破棄、退避しないこと。
* 明示的な許可なしに、`git reset --hard`、`git checkout -- <path>`、`git restore --source=<source> -- <path>`、`git clean -fd[x]`、強制 push、履歴の書き換えを行わないこと。

## Required skills

* ソースコード、テスト、設定、依存関係を変更する前に `plan-before-implementation` を使用すること。
* 承認後の実装に `clean-code-change` を使用すること。
* 重複する場合も、このファイルの承認ゲートと安全規則を最低条件とすること。
