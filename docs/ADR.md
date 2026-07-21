# ADR: ESP-IDF Verification Before Code Review

## Status

Accepted

## Context

ESP-IDF ハーネスは Stop ごとに build と size を実行するため、質問や Markdown の作成でも
時間とエージェントの処理を消費する。また、検証成功後の差分コードレビューがない。

## Decision

ESP-IDF 関連差分の fingerprint が新しい場合だけ、build、size、自然言語コードレビューの順で
実行する。関連差分がない場合と同一の検証済み fingerprint では、stdout を出さず終了する。
レビュー修正で fingerprint が変わった場合は、次の Stop で build から再検証する。

関連差分には C/C++、assembly、ESP-IDF ビルド設定、component manifest、partition table、
ハーネス設定を含め、Markdown は含めない。

## Rationale

- build と size の成功後にレビューすることで、コンパイル不能または容量超過の差分に
  レビュー時間を使わない。
- レビュー修正後の再検証により、レビュー後の成果物も build と size の条件を満たす。
- 一つのパイプラインで順序と fingerprint を管理できる。
- 既存の build と size スクリプトを再利用できる。

## Consequences

- 新しい関連差分の Stop は build と size の合計時間を必要とする。
- build または size が失敗した場合、レビューは成功後の Stop まで延期される。
- ビルドへ埋め込まれる任意拡張子の asset は、明示した関連パスに該当しない限り発火しない。

## Rejected Alternatives

### Review Before Build

ビルド不能な差分もレビュー対象となり、レビュー修正後にも build が必要なため採用しない。

### Independent Stop Hooks

build、size、review 間で fingerprint と成功状態を重複管理する必要があるため採用しない。

### Review-specific Script

自然言語メッセージだけで足り、追加の実行経路と状態同期が不要なため採用しない。
