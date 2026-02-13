---
name: javascript-code-generator
description: JavaScript のコード生成を支援する。Vanilla JS（Vanila JS 表記を含む）、AngularJS、Vue、Nuxt、React のいずれかで実装方針の整理、雛形作成、機能追加、リファクタ、テスト観点整理が必要なときに使う。
---

# JavaScript コード生成

## 前提

- 前提として AGENTS.md と GEMINI.md と CLAUDE.md を必ず遵守すること。

## 概要

JavaScript 実装を、要件確認からコード生成、テスト観点の整理まで一貫して進めるための指針を提供する。
ユーザーが指定したフレームワークを優先し、未指定の場合のみ最小質問または合理的仮定で前進する。

## 実行手順

1. 対象フレームワークを特定する。`Vanilla JS` `AngularJS` `Vue` `Nuxt` `React` のいずれかを決める。
2. 入出力、状態管理、エラー時挙動、境界値、描画更新条件を確認する。
3. 既存コードの構成、命名、依存、テスト方針に合わせる。
4. 変更範囲を最小化して実装し、動作確認手順を明示する。

## フレームワーク選択

- `Vanilla JS` を使う場合: 依存を増やしたくない小規模機能、既存が素の DOM 操作中心。
- `AngularJS` を使う場合: 既存が AngularJS 1.x で構成されており、段階的改修が必要。
- `Vue` を使う場合: コンポーネント分割と宣言的 UI を短時間で組みたい。
- `Nuxt` を使う場合: ルーティング、SSR/SSG、データ取得を含むアプリ構成が必要。
- `React` を使う場合: コンポーネント再利用と状態管理を中心に拡張したい。

## 生成ポリシー

- 先にデータ構造とイベント契約を決めてから UI 実装へ進む。
- 失敗系を先に決める。通信失敗、入力不正、空データを明示的に扱う。
- 既存スタイルガイドがあれば最優先で従う。
- 大きな変更は段階分割し、差分の意図を短く説明する。

## 参照

- 共通の進め方: `references/common.md`
- Vanilla JS: `references/vanilla-js.md`
- AngularJS: `references/angularjs.md`
- Vue: `references/vue.md`
- Nuxt: `references/nuxt.md`
- React: `references/react.md`
