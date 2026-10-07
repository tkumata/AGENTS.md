---
name: issue-workflow
description: ユーザが明示的に起動したとき、GitHub Issue を文書化し、承認後に実装するワークフロー。
---
# Issue Workflow

ユーザが `issue-workflow` を明示的に指定した場合のみ使用する。
Codex CLI / Codex App の既存セッション内で実行する。Codex を新規起動しない。

## Workflow

1. **Issue を特定する。** 非対話型 CLI の `gh-issues-triage next <owner/repo> --format json` で開発候補を取得する。`<owner/repo>` は基本的にユーザが指定するが、ない場合は現在のプロジェクトから入手する。
2. **Issue を取得する。** 取得した JSON から、タイトル、本文を抽出する。JSON を取得できない場合は終了する。
3. **文書化する。** 取得したタイトルと本文を `brain-dump-docs` スキルを使用して文書化する。
4. **承認を得る。** 作成・更新した文書、実装範囲、受け入れ条件、未決定事項を報告し、ユーザの承認を待つ。承認済み範囲の変更や不明点は既存のグローバル `AGENTS.md` の規則に従う。
5. **実装する。** 承認済み文書を参照して、現在の Codex セッションで実装する。独立した `codex exec` や新規セッションを起動しない。コード品質はグローバル `AGENTS.md` に従う。

## Boundaries

- `gh-issues-triage` は Issue の選定・取得を担当し、Codex やスキルを起動しない。
- `brain-dump-docs` は開発文書の作成・更新を担当し、ソースコードを変更しない。
- `issue-workflow` は処理順序と承認境界だけを担当する。既存スキルと Stop hook の処理を重複実装しない。
- 未決定事項を補完して実装判断しない。文書承認なしに実装を始めない。
