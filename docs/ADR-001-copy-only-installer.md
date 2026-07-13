# ADR: Copy Complete Harness Templates with a Bash Installer

## Status

Superseded by `ADR.md`

## Context

手作業コピーの漏れを防ぐため、選択されたテンプレート一式を配置する必要があった。

## Decision

Bash 製インストーラで新規ファイルだけを配置し、異なる既存ファイルはマージせず、
コピー前に競合として停止する。

## Consequences

既存の `Cargo.toml`、`Makefile`、各種 JSON 設定があるプロジェクトには、そのままでは
インストールできない。
