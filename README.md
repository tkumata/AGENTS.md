# AGENTS.md

生成 AI の性能が驚くような速度で進歩している状況でも、「開発」は「何を解決するのか」「誰に届けるのか」「開発者の入れ替えで進捗速度が左右されない」など原始的かつ根本的な部分は変わらないと考えてます。そこで、AI 時代でも開発に必要な以下の事柄を雛形として運用できるのではないかと考えました。

- ドキュメントの管理・運用
- ソースコードの品質 (可読性や保守性)

本プロジェクトには、グローバル AGENTS.md、スキル、ハーネスを残しています。グローバル AGENTS.md は、AI プロバイダや各々のプロジェクトに依存しないような汎用的なルールで、ドキュメント、ソースコード品質を定めています。

スキルやハーネスはソースコード品質やテストや検証を決定論的に実行するので見逃しがなくなり、結果的に製品の質が上がると考えています。

最終的に brain dump を AI に渡すだけで、ドキュメンテーション・実装・検証まで完了することを目指してます。現状は、ドキュメンテーションまで完了し人間の確認・承認を待つようにしています。

## AGENTS.md の導入方法

```shell
# setup for Codex (CLI and App)
ln -s "$(pwd)/AGENTS.md" "$HOME/.codex/AGENTS.md"

# setup for Claude Code
ln -s "$(pwd)/AGENTS.md" "$HOME/.claude/CLAUDE.md"

# setup for Copilot CLI
ln -s "$(pwd)/AGENTS.md" "$HOME/.copilot/copilot-instruction.md"
```

## SKILL の導入方法

```sh
# setup for Codex (CLI and App)
ln -s "$(pwd)/Skills/clean-code-change" "$HOME/.codex/skills/clean-code-change"
ln -s "$(pwd)/Skills/plan-before-implementation" "$HOME/.codex/skills/plan-before-implementation"

# setup for Claude Code
ln -s "$(pwd)/Skills/clean-code-change" "$HOME/.claude/skills/clean-code-change"
ln -s "$(pwd)/Skills/plan-before-implementation" "$HOME/.claude/skills/plan-before-implementation"

# setup for Copilot CLI
ln -s "$(pwd)/Skills/clean-code-change" "$HOME/.copilot/skills/clean-code-change"
ln -s "$(pwd)/Skills/plan-before-implementation" "$HOME/.copilot/skills/plan-before-implementation"
```

## Codex サブエージェントの導入方法

`./install.sh` は `agents/*.toml` を `$HOME/.codex/agents/` へ絶対パスのシンボリックリンクとして配置します。同名の既存パスは内容や種類にかかわらず変更しません。リポジトリを移動または削除するとリンク切れになるため、必要に応じて再インストールしてください。プロジェクト側の事前検査が失敗した場合、エージェント設定ファイルを配置しません。

`--dry-run` では未配置のエージェント設定ファイルも表示しますが、`$HOME/.codex` は変更しません。

## ハーネスの導入方法

リポジトリ直下で対話式インストーラを実行します。

```sh
./install.sh
# 変更予定だけを確認する場合
./install.sh --dry-run
```

インストール先プロジェクトのパスを入力し、環境を `rust`、`pico-sdk`、`esp-idf` から番号で1つ選択します。質問はこの2項目だけです。選択した `harness/<environment>/` の隠しファイルとサブディレクトリを含む全内容が配置されます。

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

## おまけ: GitHub Copilot の日本語化

最近分かったのですが、下記を記述してると「Generate Commit Message」ボタンが機能しなくなる場合があります。一度機能しなくなると数日間機能しなくなります。

コミットメッセージやレビューコメントを一括で日本語化します。コミットメッセージは VS Code 上だし、レビューコメントは GitHub 上だし、一括設定でどうするのかと言いますと `~/Library/Application Support/Code/User/settings.json` を以下のようにします。

```json
{
  "github.copilot.chat.localeOverride": "ja",
  "github.copilot.chat.commitMessageGeneration.instructions": [
    {
      "text": "ミットメッセージは必ず日本語で生成すること。必ず Conventional Commits 形式を使用し、以下の基準で prefix を選択すること：\n- feat: 新機能の追加\n- fix: バグ修正\n- docs: ドキュメントのみの変更\n- refactor: 動作を変えないコードの整理・リネーム・移動\n- chore: ビルド設定・依存関係・ツール類の変更\n- test: テストの追加・修正\n- style: フォーマット・インデントなど動作に影響しない変更\nfeat と docs は本当に該当する場合のみ使用し、安易に選ばないこと。件名は1行で簡潔に書き、本文に変更内容の概要を含めること。本文最後に <!-- PR レビューは日本語で行うこと --> を追記すること。"
    }
  ]
}
```

このようにすると PR 作成時の説明欄に PR レビューは日本語で行う意図が入ります。PR の説明欄にこのような文があると GitHub Copilot は指示と認識して日本語で PR レビューするようになります。これなら GitHub の設定で PR レビューを自動的に発火させても安心です。
