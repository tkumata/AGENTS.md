# Rust Review Scope Plan

## Goal

Rust 関連差分がある場合だけ `make check`、`make build`、Rust 関連差分のレビューを順番に実行し、
対象差分がない場合はエージェントへ何も返さない。

## Success Criteria

- Rust 関連差分がない場合は検証、レビュー、メッセージ出力を行わない。
- Rust 関連差分がある場合は既存の `make check`、`make build` の順序を維持する。
- build 成功後のレビュー対象を Rust 関連差分だけに限定する。
- Markdown など無関係な差分をレビュー対象にしない。
- 既存の fingerprint と再検証処理を変更しない。
- 同一の検証済み fingerprint ではメッセージを出力しない。
- リポジトリで定義した検証がすべて成功する。

## Phases

### Phase 1: Contract Synchronization

Status: Completed

- 要件、仕様、設計、ADR、README のレビュー対象を Rust 関連差分へ限定する。

### Phase 2: Minimal Implementation

Status: Completed

- `verify_pipeline.sh` のレビュー指示を限定し、処理不要の分岐を無出力にする。
- Rust 差分判定と状態遷移は変更しない。

### Phase 3: Verification

Status: Completed

- Shell 構文と ShellCheck を実行する。
- 一時 Git リポジトリで Markdown のみ、Rust のみ、Rust と Markdown の混在、検証済み fingerprint を確認する。
- インストーラの既存回帰テストと `git diff --check` を実行する。

## Out of Scope

- Rust 関連パスの追加または削除
- fingerprint と状態ファイル形式の変更
- レビュー専用スクリプトまたは結果 JSON の追加

## Verification

- `bash -n harness/rust/.agent-hooks/*.sh install.sh tests/install_test.sh`
- `shellcheck harness/rust/.agent-hooks/verify_pipeline.sh install.sh tests/install_test.sh`
- 一時 Git リポジトリで Rust Stop フックの対象範囲を確認
- `tests/install_test.sh`
- `git diff --check`

上記は 2026-07-18 にすべて成功した。一時 Git リポジトリでは Rust 関連差分がない場合と
同一の検証済み fingerprint で標準出力が空になること、Rust 関連差分がある場合だけ
`make check`、`make build`、Rust 関連差分のレビューの順で進むことを確認した。
