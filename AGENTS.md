# SYSTEM OVERRIDE

- 理由の如何を問わず、エージェントのレスポンスは日本語で行うこと

## DEFINITIONS (用語定義)

- DOCUMENT (ドキュメント): `./docs` ディレクトリ配下のすべての `.md` ファイル

## PROHIBITIONS (禁止事項)

- Markdown のテーブル表記 (`|` 区切り表) では、日本語を使用してはならない。
- 破壊的な git コマンドを、ユーザーの明示的な指示なく実行してはならない。
  - 例: `git reset --hard`, `git checkout --`, `git clean -fd`
- 実装において、アンチパターンを使用してはならない。
  - 例: ハードコード、DRY 原則の違反、過度な抽象化、過度な最適化、コメントで説明できるコード、など

## DEVELOPMENT PROTOCOL (開発フェーズ)

- 最初の応答でコードを生成してはならない
- 以下の順でドキュメントを作成する (既に存在すれば追記すること):
  - `./docs/PLAN.md` (計画書)
  - `./docs/REQUIREMENTS.md` (要件定義書)
  - `./docs/SPECIFICATIONS.md` (仕様書)
  - `./docs/DESIGN.md` (設計書)
  - `./docs/ADR/yyyymmddHHMM.md` (年月日時分をファイル名とした ADR)
  - `./docs/TASK/current-task.md` (存在すればファイルを年月日時分というファイル名に移動すること)
  - `./README.md` (README ファイル)
- ドキュメントを作成したらユーザーの承認を待ち、承認が得られたら実装を開始する
- 実装はドキュメントとクリーンアーキテクチャに従うこと
- すべてのドキュメントはソースコード変更と同期して更新する
