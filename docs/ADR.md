# ADR: Silent Stop Hook When Rust Verification Is Unnecessary

## Status

Accepted

## Context

Stop フックは Rust 関連差分がない場合も `systemMessage` を含む JSON を返していた。検証やレビューを
実行しなくても、この応答がエージェントへの不要なプロンプトとなり使用量を消費する。

## Decision

Rust 関連差分がない場合と同一の検証済み fingerprint の場合は、状態だけを保存して標準出力へ
何も出さず終了する。Rust 関連差分がある場合だけ `make check`、`make build`、Rust 関連差分の
レビュー要求を順番に実行する。

## Rationale

- 処理不要の Stop でエージェントを再起動しない。
- 既存の差分判定と状態遷移を変更せず、不要な出力の削除だけで実現できる。
- エージェントの使用量を Rust 検証が必要な場合だけに限定できる。

## Consequences

- Rust 関連差分がない Stop では進捗メッセージも返さない。
- 同一の検証済み fingerprint ではレビュー要求を繰り返さない。
- check、build、レビュー、失敗時の修正要求は従来どおり出力する。

## Rejected Alternative

### Return a No-op Message

処理不要であることを伝えるだけでもプロンプト投入と使用量が発生するため採用しない。
