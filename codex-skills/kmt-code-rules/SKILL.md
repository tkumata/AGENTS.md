---
name: kmt-code-rules
description: クリーンアーキテクチャの依存規則と責務分離に従って実装・変更する。
---
# Kmt Code Rules

コードを変更するときは、既存構成を尊重しつつクリーンアーキテクチャの依存規則を維持する。

## Dependency Rule

依存は外側から内側へのみ許可する。

`Frameworks / Drivers -> Adapters -> Application -> Domain`

内側のレイヤは外側のレイヤを import、include、参照してはならない。

* Domain は Application、Adapter、Framework に依存しない。
* Application は Adapter、Framework に依存しない。
* Adapter は Framework の詳細を Application / Domain に漏らさない。
* 外部システムへの依存は境界で抽象化する。

## Responsibilities

### Domain

業務ルール、Entity、Value Object、ドメイン固有の不変条件を置く。

I/O、DB、HTTP、UI、OS、SDK、Framework の詳細を置かない。

### Application

Use Case とアプリケーション固有の処理フローを置く。

Domain を操作し、外部機能は Port / Interface 経由で利用する。

### Adapters

Port の実装、DTO 変換、Controller、Presenter、Repository Adapter を置く。

外部形式と内部モデルの変換を境界で行う。

### Frameworks / Drivers

DB、HTTP Client、GUI、CLI、デバイス、OS、SDK、Framework 固有コードを置く。

## Implementation Rules

* Business logic を Controller、UI、DB、SDK 呼び出しへ直接記述しない。
* Domain 型を外部 API や永続化形式に直接依存させない。
* 外部依存は Application 側で定義した Port を介して扱う。
* DTO と Domain Model を必要に応じて分離する。
* レイヤを跨ぐデータ変換は境界付近で行う。
* 循環依存を作らない。
* グローバル状態への依存を増やさない。
* テストのためだけの不要な抽象化を追加しない。
* 単純な処理に形式的な Use Case や Interface を量産しない。
* 既存構造で依存規則を満たせる場合は新しいレイヤを追加しない。

## Before Editing

変更対象について、責務、依存元、依存先を確認する。

依存規則に違反する変更が必要なら、そのまま実装せず境界または責務配置を修正する。

## Verification

実装後、変更された依存関係を確認する。

外側の詳細が Domain / Application に侵入していないこと、Business logic が Framework 側へ流出していないこと、不要な抽象化を追加していないことを確認する。
