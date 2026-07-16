# Rust Stop-time Code Review Plan

## Goal

Rust 関連変更の検証成功後、特定の AI エージェントに依存しない自然言語でコードレビューを
要求する。

## Success Criteria

- Rust 関連変更がない場合は検証とレビューを要求しない。
- 既存の Rust 対象パス、fingerprint、`make check`、`make build` の順序を維持する。
- build 成功後は、現在の未コミット変更をレビューするよう自然言語で要求する。
- レビュー指示は特定の AI エージェント名、専用コマンド、レビュー結果 JSON に依存しない。
- レビュー中に Rust 関連ファイルが変わった場合は `make check` から再検証する。
- 同一 fingerprint の検証を繰り返さない。
- リポジトリで定義した検証がすべて成功する。

## Phases

### Phase 1: Review Contract

Status: Completed

- 自然言語レビューの発火条件、対象、再検証条件を全 DOCUMENT へ反映する。
- 旧 ADR を退避し、Stop 時レビューを採用する ADR を作成する。

完了条件は、要件、仕様、設計、ADR のレビュー規則が一致することである。

### Phase 2: Review Request Implementation

Status: Completed

- `verify_pipeline.sh` にエージェント中立なレビュー指示を定義する。
- build 成功と fingerprint の不変を確認した後、検証済み状態を保存してレビューを要求する。

完了条件は、build 成功後に Stop が継続され、同じエージェントがコードレビューへ進むことである。

### Phase 3: Verification Coverage

Status: Completed

- Shell 構文、ShellCheck、差分の空白エラーを検査する。
- Rust 関連変更なし、check 成功、build 成功、レビュー修正後の fingerprint 変化を確認する。
- インストーラの既存回帰テストを実行する。

完了条件は、追加シナリオと既存シナリオがすべて成功することである。

### Phase 4: Documentation Synchronization

Status: Completed

- 実装結果と検証結果に合わせて README と全 DOCUMENT を同期する。
- 検証コマンドと結果を記録する。

完了条件は、README、要件、仕様、設計、実装、テストが一致することである。

## Out of Scope

- Claude Code または Gemini 用フック設定の追加
- エージェント固有のレビューコマンドやレビュー結果 JSON の導入
- レビュー完了を示す追加ファイルまたは追加スクリプト
- Rust 関連変更がない場合のコードレビュー

## Verification

- `bash -n harness/rust/.agent-hooks/*.sh install.sh tests/install_test.sh`
- `PYTHONPYCACHEPREFIX=/tmp/agents-md-pycache python3 -m py_compile merge.py`
- `shellcheck harness/rust/.agent-hooks/verify_pipeline.sh install.sh tests/install_test.sh`
- 一時 Git リポジトリで Rust Stop フックの状態遷移を確認
- `tests/install_test.sh`
- `git diff --check`

上記は 2026-07-16 にすべて成功した。一時 Git リポジトリでは Codex と Copilot のレビュー要求、
同一 fingerprint での終了、レビュー修正後の `make check` 再実行、Rust 関連変更なしの終了を
確認した。

参考として `shellcheck harness/rust/.agent-hooks/*.sh install.sh tests/install_test.sh` は、
未変更の `pre_tool_guard.sh` にある既存の SC2034 と SC2016 により失敗する。今回の変更範囲には
含めず、`verify_pipeline.sh` の ShellCheck 成功を完了条件とした。
