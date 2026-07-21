# Harness Installer Requirements

## Functional Requirements

### REQ-1: Installation Target

インストーラは、最初の対話入力としてインストール先プロジェクトのパスを受け取る。
相対パスと絶対パスを受け付け、存在するディレクトリだけを有効とする。

### REQ-2: Environment Selection

インストーラは `rust`、`pico-sdk`、`esp-idf` のいずれか1つを対話で選択させる。

### REQ-3: Complete Template Installation

選択した `harness/<environment>/` 直下の全内容を、隠しファイルとサブディレクトリを
含めてインストール先の直下へ配置する。

### REQ-4: Existing Files

- 同一内容の通常ファイルは変更しない。
- 対応形式の異なる通常ファイルは REQ-5 の規則でマージする。
- 未対応形式、マージ競合、型の異なる同名パスは衝突として扱う。
- 衝突を1件でも検出した場合は、配置先を一切変更せず失敗終了する。

### REQ-5: Supported Merges

- `.gitignore`: 既存行を保持し、不足する無視パターンだけを追加する。
- `.codex/hooks.json`: イベントと matcher が同じグループへ、不足する command を追加する。
- `.github/hooks/hooks.json`: 同じイベントへ、不足する bash command を追加する。
- `.vscode/settings.json`: 不足キーを再帰的に追加する。
- `Cargo.toml`: `[lints.clippy]` の不足キーを追加する。
- `Makefile`: 不足ターゲットを追加する。

同じ識別子の値または定義が異なる場合は、既存値を変更せず競合とする。

### REQ-6: File Metadata

新規ファイルはテンプレート側の実行権限を保持する。マージする既存ファイルは
配置先のファイルモードを保持する。

### REQ-7: Result Reporting

成功時は選択環境、インストール先、新規配置、マージしたファイル数を表示する。失敗時は原因と
パスを標準エラーへ表示し、非ゼロの終了ステータスを返す。

dry-run 成功時は、新規配置またはマージする予定の各相対パスと件数を表示し、通常実行と
区別できる完了メッセージを表示する。

## Non-Functional Requirements

### REQ-8: Dependencies

インストーラは Bash、Python 3、および一般的な Unix 系の標準コマンドで動作する。
追加の Python パッケージや `jq` をインストーラ自身の処理には要求しない。

### REQ-9: Repository Independence

呼び出し時のカレントディレクトリには依存せず、インストーラ自身の位置を基準に
テンプレートとマージスクリプトを解決する。

### REQ-10: Minimal Interaction

利用者へ尋ねる項目はインストール先と環境の2つだけとし、上書き確認や競合解消の
追加対話を設けない。

### REQ-11: Idempotency

同じテンプレートを同じ配置先へ繰り返し適用した場合、2回目以降は内容と更新時刻を
変更しない。

### REQ-12: Dry-run

`--dry-run` 指定時は通常実行と同じ入力検証、Preflight、マージ生成を行い、配置先の内容、
モード、更新時刻、ディレクトリ構造を一切変更せずに正常終了する。競合時は通常実行と
同じ規則で失敗する。

### REQ-13: Rust Stop-time Code Review

Rust ハーネスは Rust 関連変更に対する `make check` と `make build` の成功後、現在の
未コミット変更を正しさ、回帰、セキュリティ、テスト、ドキュメント整合性の観点でレビューする
よう自然言語でエージェントへ要求する。指示は特定の AI エージェント名、専用コマンド、
レビュー結果 JSON に依存してはならない。レビューで Rust 関連ファイルが変更された場合は、
次の Stop で検証をやり直す。

### REQ-14: ESP-IDF Stop-time Verification and Code Review

ESP-IDF ハーネスは C/C++、assembly、ESP-IDF ビルド設定、ハーネス設定に未コミット変更が
ある場合だけ build と size を順番に検証する。両方の成功後、現在の未コミット変更を正しさ、
回帰、セキュリティ、テスト、ドキュメント整合性の観点でレビューするよう自然言語で
エージェントへ要求する。

関連変更がない場合と同一の検証済み fingerprint の場合は、コマンド実行もフック出力も
行わない。レビューで関連ファイルが変更された場合は、次の Stop で build から再検証する。
