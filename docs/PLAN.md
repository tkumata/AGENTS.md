# Harness Installer Override Plan

## Goal

通常の安全なマージ動作を維持しつつ、明示的な `--override` 指定時にテンプレートの
既存通常ファイルを全面置換できるようにする。

## Success Criteria

- 新規パスと同一内容の既存ファイルは従来どおり安全に処理できる。
- 通常モードは既存のマージ・競合規則を維持する。
- `--override` はテンプレートに含まれる異なる通常ファイルを内容とモードごと置換する。
- `--override` でもテンプレート外ファイルを保持し、型衝突とシンボリックリンクを拒否する。
- 同じ環境の再インストールは冪等であり、既存ファイルを更新しない。
- コピーと更新が混在しても、論理的な競合による部分更新が起きない。
- リポジトリで定義した検証がすべて成功する。

## Phases

### Phase 1: Override Contract

Status: Completed

- `--override` の対象、非対象、モード保持、失敗条件を全 DOCUMENT へ反映する。
- 旧 ADR を退避し、明示的な全面置換を採用する ADR を作成する。

完了条件は、要件、仕様、設計、ADR のマージ規則が一致することである。

### Phase 2: Override Implementation

Status: Completed

- 引数解析、上書き用Preflight、置換件数の表示を実装する。
- 全パスの検証成功後にだけ配置先を更新する。

完了条件は、新規コピー、同一ファイル、正常マージ、競合を実装できることである。

### Phase 3: Verification Coverage

Status: Completed

- 通常モードの既存回帰テストを維持する。
- 上書き、テンプレート外ファイル保持、モード、シンボリックリンク拒否をテストする。
- 再インストール時に内容と更新時刻が変わらないことを確認する。

完了条件は、追加シナリオと既存シナリオがすべて成功することである。

### Phase 4: Documentation Synchronization

Status: Completed

- 実装結果に合わせて README と全 DOCUMENT を同期する。
- 検証コマンドと結果を記録する。

完了条件は、README、要件、仕様、設計、実装、テストが一致することである。

## Out of Scope

- `.agent-hooks/*.sh` を含む任意テキストの自動マージ
- 競合時の既存値またはテンプレート値の自動優先
- 利用者へファイル単位の選択や競合解消を求める追加対話
- 過去のテンプレートを保存した三者間マージ
- コピー開始後の OS または I/O 障害に対する完全なロールバック

## Verification

- `bash -n install.sh tests/install_test.sh`
- `python3 -m py_compile merge.py`
- `shellcheck install.sh tests/install_test.sh`
- `tests/install_test.sh`
- `git diff --check`

上記は 2026-07-13 にすべて成功した。
