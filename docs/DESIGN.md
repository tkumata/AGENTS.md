# Harness Installer Design

## Overview

対話とファイル配置を担当する Bash スクリプトと、形式別マージを担当する Python 3
スクリプトで構成する。テンプレートのディレクトリ構造を配置対象の定義として使用し、
対応形式だけを明示的にマージする。

## Processing Flow

```text
start
  -> resolve installer and merge helper
  -> parse normal, dry-run, or help mode
  -> read and validate target and environment
  -> create staging directory
  -> enumerate all template paths
  -> preflight every destination
     -> new file: record copy operation
     -> identical file: skip
     -> supported file: generate merged file in staging
     -> conflict: report and exit without destination changes
  -> dry-run: report planned file operations and exit
  -> create missing directories
  -> copy new files preserving template mode
  -> replace changed merged files preserving destination mode
  -> report counts and success
```

## Responsibilities

### `install.sh`

- 対話入力、固定候補からの環境決定、パス型検査を行う。
- `--dry-run` を解釈し、Preflight 後の配置処理を抑止する。
- 空白や改行以外の特殊文字を含むパスを安全に列挙する。
- マージヘルパーの終了結果を Preflight の成否へ反映する。
- 全論理検査が成功するまで配置先を変更しない。
- 新規ファイルとマージファイルのモードをそれぞれ保持する。
- dry-run では staging と配置先の状態から予定操作を分類し、相対パスと件数を表示する。

### `merge.py`

- 相対パスから許可されたマージ方式を選択する。
- 既存ファイルとテンプレートを読み、完成内容を指定出力へ書く。
- 既存定義を保持し、不足定義だけを追加する。
- 値違い、構文不正、未対応形式をエラーとして返す。
- 配置先へ直接書き込まない。

## Conflict Model

マージ可能性とマージ結果をコピー開始前に確定する。既存設定とテンプレート設定の
優先順位は設けない。同じ識別子が異なる定義を持つ場合は判断不能な競合とする。

シンボリックリンクと特殊ファイルは、リンク先の暗黙変更やデバイスアクセスを避けるため
未対応とする。

## Idempotency

各形式の重複判定は安定した識別子を使用する。マージ結果が配置先と同一の場合、ファイルを
置換しない。これにより再実行時の内容と更新時刻を保持する。

## Failure Boundaries

入力、パス型、形式構文、意味的競合は Preflight で検出するため、これらによる部分更新は
発生しない。配置開始後の容量不足、権限変更、デバイス障害などに対する完全なロールバックは
保証しない。

## Dry-run Boundary

dry-run は通常実行と同じ staging 完了後に分岐し、配置先へ書き込む処理へ到達させない。
予定操作は新規ファイルと、staging の完成内容が既存内容と異なるファイルから導出する。
これにより競合判定と変更件数を実配置と共有する。

## Rust Stop-time Review

`harness/rust/.agent-hooks/verify_pipeline.sh` は、Rust 関連差分の fingerprint と
`check_pending`、`build_pending`、`done` の状態を管理する。既存の検証済み fingerprint を
レビュー要求後の再入防止にも利用し、レビュー専用の状態ファイルや承認入力は追加しない。

build 成功後は検証済み fingerprint を保存し、フック出力のメッセージとして自然言語の
レビュー指示を返す。同じエージェントが現在の未コミット変更をレビューし、修正した場合は
次の Stop で fingerprint の差により検証が再開される。修正がない場合は、次の Stop を
レビュー完了の意思表示として扱い、同一 fingerprint の検証を繰り返さない。

レビュー指示本文はエージェント共通とし、Codex、Copilot、将来の Claude Code、Gemini の
違いは、フック設定と継続要求の出力形式に限定する。

## ESP-IDF Stop-time Verification and Review

`.codex/hooks.json` と `.github/hooks/hooks.json` は Stop 時に
`verify_pipeline.sh` だけを起動する。パイプラインは関連パスを列挙してファイル内容の
fingerprint を生成し、検証済み fingerprint と一致する場合は無言で終了する。

新しい fingerprint では既存の `check_build.sh` と `check_size.sh` を直列実行する。成功 JSON は
パイプライン内で消費し、失敗時だけ既存スクリプトの JSON をフックへ返す。両方の成功後は
自然言語レビュー指示を返し、fingerprint を `.agent-hooks/state/` に保存する。レビュー修正で
fingerprint が変われば同じ経路を再実行する。これによりレビュー専用スクリプトや承認ファイルを
追加しない。

生成ログと状態は `.gitignore` の対象とし、検証自身が fingerprint を変えないようにする。
Codex と GitHub Copilot の違いは継続要求 JSON の外形だけに限定する。

## Implementation Constraints

- macOS 付属の古い Bash でも利用できる構文を使用する。
- Python は標準ライブラリだけを使用する。
- GNU 固有オプションに依存しない。
- マージ対象をファイル名または固定相対パスのホワイトリストで決定する。
- テンプレート、既存設定、未対応ファイルを削除しない。
