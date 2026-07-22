# ESP-IDF Stop Hook Gating and Review Plan

## Goal

ESP-IDF 関連差分がある場合だけ build と size を検証し、成功後に自然言語でコードレビューを
要求する。質問や Markdown のみの変更では Stop フックを無言で終了する。

## Success Criteria

- ESP-IDF 関連差分がない場合は stdout を出さず、build、size、レビューを実行しない。
- 関連差分がある場合は build、size、コードレビューの順で実行する。
- build または size の失敗時はレビューせず、既存の失敗情報を返す。
- レビュー修正で関連差分が変わった場合は build から再検証する。
- 同一の検証済み fingerprint では処理を繰り返さない。
- Codex と GitHub Copilot へ同じ自然言語レビュー指示を返す。

## Phases

### Phase 1: Trigger and Fingerprint

Status: Completed

- C/C++、assembly、ESP-IDF ビルド設定、ハーネス設定を関連パスとして定義する。
- HEAD との差分と未追跡ファイルから fingerprint を生成する。
- 無関係差分と検証済み fingerprint を無言で終了する。

### Phase 2: Verification and Review

Status: Completed

- 既存の `check_build.sh` と `check_size.sh` を順番に実行する。
- 両方の成功後だけ、エージェント中立な自然言語でコードレビューを要求する。
- 検証中またはレビュー中の関連差分変更を次回の再検証へ接続する。

### Phase 3: Documentation and Verification

Status: Completed

- README と全 DOCUMENT を実装に同期する。
- 無関係差分、成功順序、cache hit、変更後の再検証、build 失敗を実行確認する。
- Shell、JSON、インストーラ、空白エラーを検証する。

## Out of Scope

- ESP-IDF が提供していない formatter、linter の追加
- エージェント固有のレビューコマンドまたはレビュー結果 JSON
- Markdown や一般的な質問に対するコードレビュー
- 既存 build、size 判定ロジックの変更

## Verification

- `bash -n harness/esp-idf/.agent-hooks/*.sh tests/esp_idf_hook_test.sh`
- `jq -e . harness/esp-idf/.codex/hooks.json harness/esp-idf/.github/hooks/hooks.json`
- `shellcheck harness/esp-idf/.agent-hooks/verify_pipeline.sh tests/esp_idf_hook_test.sh`
- `tests/esp_idf_hook_test.sh`
- `tests/install_test.sh`
- `git diff --check`

上記は 2026-07-21 にすべて成功した。fixture では無関係差分の stdout が 0 byte であること、
build、size、レビューの順序、Codex と GitHub Copilot のレビュー出力、同一 fingerprint の
無処理、変更後の再検証、build と size の各失敗経路を確認した。

実際の `idf.py build` と `idf.py size` は対象ファームウェアを持たないテンプレートリポジトリでは
実行せず、既存スクリプトを stub に置き換えた fixture でパイプラインの契約を検証した。
