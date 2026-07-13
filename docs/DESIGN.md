# Harness Installer Merge Design

## Overview

対話とファイル配置を担当する Bash スクリプトと、形式別マージを担当する Python 3
スクリプトで構成する。テンプレートのディレクトリ構造を配置対象の定義として使用し、
対応形式だけを明示的にマージする。

## Processing Flow

```text
start
  -> resolve installer and merge helper
  -> parse normal, override, or help mode
  -> read and validate target and environment
  -> create staging directory
  -> enumerate all template paths
  -> preflight every destination
     -> new file: record copy operation
     -> identical file: skip
     -> supported file: generate merged file in staging
     -> override mode regular file: stage the template file
     -> conflict: report and exit without destination changes
  -> create missing directories
  -> copy new files preserving template mode
  -> replace changed merged files preserving destination mode
  -> replace override files using template mode
  -> report counts and success
```

## Responsibilities

### `install.sh`

- 対話入力、固定候補からの環境決定、パス型検査を行う。
- `--override` を解釈し、通常の意味的マージと明示的な全面置換を切り替える。
- 空白や改行以外の特殊文字を含むパスを安全に列挙する。
- マージヘルパーの終了結果を Preflight の成否へ反映する。
- 全論理検査が成功するまで配置先を変更しない。
- 新規ファイルとマージファイルのモードをそれぞれ保持する。

### `merge.py`

- 相対パスから許可されたマージ方式を選択する。
- 既存ファイルとテンプレートを読み、完成内容を指定出力へ書く。
- 既存定義を保持し、不足定義だけを追加する。
- 値違い、構文不正、未対応形式をエラーとして返す。
- 配置先へ直接書き込まない。

## Conflict Model

マージ可能性とマージ結果をコピー開始前に確定する。既存設定とテンプレート設定の
優先順位は設けない。同じ識別子が異なる定義を持つ場合は判断不能な競合とする。
ただし、利用者が `--override` を明示した場合に限り、テンプレート通常ファイルを優先する。

シンボリックリンクと特殊ファイルは、リンク先の暗黙変更やデバイスアクセスを避けるため
未対応とする。

## Idempotency

各形式の重複判定は安定した識別子を使用する。マージ結果が配置先と同一の場合、ファイルを
置換しない。これにより再実行時の内容と更新時刻を保持する。

## Failure Boundaries

入力、パス型、形式構文、意味的競合は Preflight で検出するため、これらによる部分更新は
発生しない。配置開始後の容量不足、権限変更、デバイス障害などに対する完全なロールバックは
保証しない。

## Implementation Constraints

- macOS 付属の古い Bash でも利用できる構文を使用する。
- Python は標準ライブラリだけを使用する。
- GNU 固有オプションに依存しない。
- マージ対象をファイル名または固定相対パスのホワイトリストで決定する。
- テンプレート、既存設定、未対応ファイルを削除しない。
