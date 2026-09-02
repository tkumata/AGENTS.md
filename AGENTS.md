# Global Agent Instructions

In Code Mode, within each bounded stage, run independent, functions.exec-available tool calls concurrently in one functions.exec call. Use await Promise.allSettled([...]) when partial results are useful, and inspect every result; use await Promise.all([...]) only when any failure should abort the batch. Keep dependencies, waits/resumes, approvals, conflicting or interdependent mutations, and adaptive investigations where each result may change the next step sequential. Do not split otherwise batchable inspections across outer tool calls.

## Language

* ユーザへの説明、進捗、計画、文書、最終回答は日本語で行うこと。
* コード、識別子、コマンド、ファイル名、ログ、API 名は必要に応じて原文を維持すること。
* 造語禁止。正しい技術用語や学術用語を用いること。

## Precedence

* リポジトリ固有の `AGENTS.md`、設計文書、規約、検証手順を確認して追加適用すること。
* より具体的なリポジトリ固有指示を優先すること。
* ただし、承認ゲート、ユーザ変更の保護、Git の安全規則は、明示的な指示なしに緩和しないこと。

## Core rules

* KISS の原則に従い、要件を満たす最も単純な設計・実装を選び、不要な複雑化・抽象化・間接層を追加しないこと。
* YAGNI の原則に従い、現在の要件で明示的に必要とされていない機能、抽象化、汎用化、拡張ポイント、将来対応のためのコードを追加しない。
* クリーンアーキテクチャに従い、外部境界、依存方向、責務分割、データ構造を明確にすること。
* 新しい抽象化は、具体的な変化、外部境界、またはテスト上の必要性を隔離する場合だけ追加すること。
* 関数は小さく構築すること。1 つの関数は 1 つの責務だけを持ち、1 つのレベルの抽象化に従うこと。長くても 20 行程度に収めること。関数の長さが 20 行を超える場合は、責務を分割して小さな関数にすること。
* 名前は役割と意図を表し、コメントは理由、制約、トレードオフを説明すること。
* 可変状態の所有者と更新箇所を明確にし、エラーを握り潰したり根拠のない既定値へ置き換えたりしないこと。
* テストは観測可能な動作と回帰条件を検証し、実装を通すために削除、無効化、弱体化しないこと。
* テストの実行と検証は各プロジェクトのハーネスに任せる。

## Workflow and approval

開発は、計画の提案と文書の作成、承認、実装、報告の順で行うこと。

* 承認前に、本番コード、テスト、設定、依存関係を開発・修正してはならない。
* 承認前には、読み取り、検索、現状検証、問題再現、開発文書の作成または更新のみ行ってよい。
* 承認は提示した計画、設計、対象範囲、フェーズにのみ適用する。
* 重大な前提変更、設計変更、範囲拡大、新しい依存関係が必要なら、文書を更新して再承認を得ること。
* ユーザが明示的に承認待ちを不要とした作業に限り、承認ゲートを省略してよい。

## Delegation

* メインエージェントはオーケストレータとして、各サブエージェントの結果を統合すること。
* ユーザの brain dump を一回の bounded pass で整理し、文書だけを作成する。その際、下記条件のサブエージェントを使用すること。文書化後に自動で再計画、継続調査、Finalization を行わないこと。
  * モデルは `gpt-5.6-sol`
  * reasoning effort は `medium`
* 承認後の実装に下記条件のサブエージェントを使用すること。
  * モデルは `gpt-5.6-luna`
  * reasoning effort は `max`
* 不具合調査やソースコード調査は下記条件のサブエージェントを使用すること。
  * モデルは `gpt-5.6-terra`
  * reasoning effort は `medium`
