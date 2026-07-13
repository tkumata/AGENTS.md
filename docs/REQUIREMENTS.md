# Harness Installer Merge Requirements

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
- `--override` 指定時は、テンプレートに含まれる異なる内容の既存通常ファイルを
  テンプレートの内容とモードで置換する。
- `--override` 指定時も、テンプレート外の配置先ファイルは変更せず、型の異なる同名パスと
  シンボリックリンクは衝突として扱う。

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

成功時は選択環境、インストール先、新規、マージ、上書きしたファイル数を表示する。失敗時は原因と
パスを標準エラーへ表示し、非ゼロの終了ステータスを返す。

## Non-Functional Requirements

### REQ-8: Dependencies

インストーラは Bash、Python 3、および一般的な Unix 系の標準コマンドで動作する。
追加の Python パッケージや `jq` をインストーラ自身の処理には要求しない。

### REQ-9: Repository Independence

呼び出し時のカレントディレクトリには依存せず、インストーラ自身の位置を基準に
テンプレートとマージスクリプトを解決する。

### REQ-10: Minimal Interaction

利用者へ尋ねる項目はインストール先と環境の2つだけとし、上書き確認や競合解消の
追加対話を設けない。全面置換は明示的な `--override` 指定だけで有効にする。

### REQ-11: Idempotency

同じテンプレートを同じ配置先へ繰り返し適用した場合、2回目以降は内容と更新時刻を
変更しない。
