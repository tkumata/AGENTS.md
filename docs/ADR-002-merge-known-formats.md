# ADR: Merge Known Harness Configuration Formats

## Status

Superseded by `ADR.md`

## Context

コピー専用インストーラは既存設定を保護できる一方、一般的な既存プロジェクトにある
`Cargo.toml`、`Makefile`、`.gitignore`、JSON 設定と衝突し、導入前の手作業を必要とする。
任意テキストの自動マージは構文破損や既存動作の変更を安全に判定できない。

## Decision

既知の設定ファイルだけをホワイトリスト方式で意味的にマージする。既存設定を保持し、
不足する項目だけを追加する。同じ識別子の定義が異なる場合、未対応形式の場合、または
構文を解釈できない場合は競合として全体を変更前に停止する。

マージ処理は Python 3 の標準ライブラリを使用する専用スクリプトへ分離する。
`install.sh` は対話、パス検証、Preflight、配置を担当する。マージ結果は Preflight 中に
一時ディレクトリへ生成し、すべて成功した後にだけ配置する。

## Rationale

- ホワイトリスト方式なら、安全性をファイル形式ごとに定義しテストできる。
- 既存値を暗黙に優先または上書きせず、判断不能な差異を利用者へ返せる。
- Python 標準ライブラリにより、外部パッケージなしで JSON を正しく処理できる。
- マージ生成をコピー処理から分離すれば、Bash の責務と分岐を限定できる。

## Consequences

- 実行環境に Python 3 が必要になる。
- マージ後の JSON は標準形式へ整形される。
- 対応していないファイルや値違いは引き続き事前調整が必要になる。
- 過去のテンプレートを基準とする三者間マージには対応しない。

## Rejected Alternatives

### Generic Text Concatenation

JSON や TOML を破損させ、Makefile の同名ターゲットを意図せず再定義するため採用しない。

### Existing Values Always Win

ハーネスに必要な安全設定が無効なまま成功扱いになるため採用しない。

### Template Values Always Win

利用者の既存設定を暗黙に変更するため採用しない。

### Three-way Merge in This Phase

前回適用したテンプレートの保存形式と更新ポリシーが別途必要になるため、今回の範囲から
除外する。
