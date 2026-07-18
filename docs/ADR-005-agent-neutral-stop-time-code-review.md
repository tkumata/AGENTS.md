# ADR-005: Agent-neutral Stop-time Code Review

Superseded by `ADR.md`

## Status

Accepted

## Context

Rust ハーネスは Rust 関連差分に対して `make check` と `make build` を実行するが、検証成功後に
コードレビューを要求しない。レビュー結果を専用コマンドや JSON で受け取る方式は、対応する
AI エージェントごとの実装を増やし、将来の Claude Code や Gemini への展開を妨げる。

## Decision

Rust の build 成功後、現在の未コミット変更をコードレビューするよう自然言語でエージェントへ
要求する。レビュー指示は正しさ、回帰、セキュリティ、テスト、ドキュメント整合性を対象とし、
特定の AI エージェント名、専用コマンド、レビュー結果 JSON を含めない。

build 成功時の fingerprint を検証済みとして保存する。レビューで Rust 関連ファイルが変われば
次の Stop で検証を再実行し、変わらなければ同一 fingerprint の検証を繰り返さない。

## Rationale

- 自然言語の指示本文を各エージェントで共有できる。
- 既存の fingerprint がレビュー修正後の再検証も保証する。
- レビュー専用状態、承認ファイル、追加スクリプトを不要にできる。
- 製品差をフック設定と継続要求の出力形式へ限定できる。

## Consequences

- build 成功後にエージェントの処理が1回継続する。
- レビュー完了は、エージェントが指示に従い再度 Stop することで表現される。
- 将来のエージェント追加時には、その製品のフック接続と応答形式を別途定義する必要がある。

## Rejected Alternatives

### Review Result JSON

レビュー判断を機械的に記録できるが、エージェントごとの呼び出し方法と入力契約が必要になるため
採用しない。

### Dedicated Review Script

既存の Stop フックとは別の実行経路と状態同期が必要になり、構成が複雑になるため採用しない。

### Agent-specific Review Commands

対応製品の追加ごとにレビュー実装を作り直す必要があるため採用しない。
