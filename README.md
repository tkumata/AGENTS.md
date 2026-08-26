# AGENTS.md

生成 AI の性能が驚くような速度で進歩している状況でも、「開発」は「何を解決するのか」「誰に届けるのか」「開発者の入れ替えで進捗速度が左右されない」など原始的かつ根本的な部分は変わらないと思っています。そこで、AI 時代でも開発に必要な以下の事柄を雛形として運用することで効率的に開発できるのではないかと考えました。

- ドキュメントの管理・運用
- ソースコードの品質 (可読性や保守性)

本プロジェクトには、グローバル AGENTS.md、スキル、ハーネスを残しています。グローバル AGENTS.md は、AI プロバイダや各々のプロジェクトに依存しない汎用的なルールで、ドキュメント・ソースコード品質を定めています。

スキルやハーネスはソースコード品質やテストや検証を決定論的に実行するので見逃しがなくなり、結果的に製品の質が上がると考えています。

最終的に brain dump を AI に渡すだけで、ドキュメンテーション・実装・検証まで完了することを目指してます。現状は、ドキュメンテーションまで完了し人間の確認・承認を待つようにしています。

## AGENTS.md の導入方法

```Shell
# setup for Codex (CLI and App)
ln -s "$(pwd)/AGENTS.md" "$HOME/.codex/AGENTS.md"

# setup for Claude Code
ln -s "$(pwd)/AGENTS.md" "$HOME/.claude/CLAUDE.md"

# setup for Copilot CLI
ln -s "$(pwd)/AGENTS.md" "$HOME/.copilot/copilot-instructions.md"
```

## ハーネスの導入方法

本リポジトリ直下で対話式インストーラを実行します。ハーネスと docs-AGENTS.md を所定の場所にインストールします。

```Shell
./install.sh

# 変更予定だけを確認する場合
./install.sh --dry-run
```

インストール先プロジェクトのパス、環境（`rust`、`pico-sdk`、`esp-idf`）、エージェント（Codex、Claude Code、Copilot CLI）を番号で1つずつ選択します。選択した環境の共通ハーネスと、選択したエージェント用の設定だけが配置されます。

| エージェント | docs 用指示 | hook 設定 |
| ---------- | ----------------- | --------------------------- |
| Codex | `docs/AGENTS.md` | `.codex/hooks.json` |
| Claude Code | `docs/CLAUDE.md` | `.claude/settings.json` |
| Copilot CLI | `docs/AGENTS.md` | `.github/hooks/hooks.json` |

docs 用指示ファイルは、リポジトリ直下の `docs-AGENTS.md` への絶対 symlink です。`docs/` がなければ作成し、同じ symlink が既にあれば変更しません。選択外の設定は新規作成せず、既に存在しても変更しません。

同一内容の既存ファイルは変更されません。`.gitignore`、フック JSON、VS Code 設定、`Cargo.toml`、`Makefile` は既存設定を保持して不足項目だけをマージします。同じ設定の値が異なる場合、未対応ファイルの内容が異なる場合、または型の異なる同名パスがある場合は、配置を開始せずエラー終了します。実行には Bash、Python 3、標準的な Unix コマンドが必要です。

`--dry-run` を指定すると、通常実行と同じ競合検査を行い、新規配置またはマージする予定のファイルと件数を表示します。インストール先は変更しません。

### Pico-SDK の場合

`.h`, `.c`, `.cpp`, `.hpp`, `.cmake` などソースコードファイルの fingerprint を見て、違いがあればフォーマットチェックとビルドを行い、結果をエージェントに返します。これにより、多純な質問などではハーネスが発火せずソースコードなどを編集した時だけハーネスが発火します。

### ESP-IDF の場合

外部ツール (clang-formatter, cppcheck, clang-tidy など) で Format, Lint チェックすると誤検知が多い (ESP-IDF が想定している記述と違うっぽい) ので `idf.py` を経由してチェックするために `idf.py build` と `idf.py size` を実施するようにしました。

C/C++、assembly、ESP-IDF のビルド設定、component manifest、partition table、ハーネス設定に変更がある場合だけ、`Stop hook` は build と size を順番に実行します。両方の成功後、現在の未コミット変更を正しさ、回帰、セキュリティ、テスト、ドキュメント整合性の観点でコードレビューするよう自然言語で指示します。質問や Markdown のみの変更、および同一の検証済み差分では何も出力しません。レビューで関連ファイルを変更した場合は、次の `Stop hook` で build から再検証します。

なお、`idf.py clang-format` は開発中のため除外しました。

### Rust の場合

パニックになる可能性のあるコードをエラー扱いするように Linter を設定しました。

Rust 関連ファイルに変更がある場合、`Stop hook` は fingerprint の変化に応じて `make check` と `make build` を実行します。検証成功後は、現在の未コミット変更を正しさ、回帰、セキュリティ、テスト、ドキュメント整合性の観点でコードレビューするよう自然言語でエージェントへ指示します。

レビューで Rust 関連ファイルを変更した場合は、次の `Stop hook` で検証をやり直します。
