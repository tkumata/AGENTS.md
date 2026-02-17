---
name: rust-coding
description: Supports Rust CLI and Web server development, design, testing, and error handling. use when implementation, refactoring, structure planning, cargo/clippy/fmt operations, or crate selection are needed.
---

# Rust Coding

## Prerequisites

- Must comply with AGENTS.md, GEMINI.md, and CLAUDE.md.

## Overview

Provides guidelines for implementing and designing Rust CLI tools and Web servers with minimal prerequisite checks.
Prioritizes existing project conventions and code, proposing minimal additional specifications only when necessary.

## Process

1. Identify the target: Clarify whether it is a CLI, Web server, or both.
2. Confirm inputs/outputs, error behavior, performance requirements, need for async, and external dependencies.
3. Align with existing code structure, module separation, naming conventions, and error policies.
4. Proceed with implementation followed by testing, assuming `cargo fmt` and `cargo clippy` usage.

## CLI Guidelines

- Use `clap` for argument parsing by default; keep subcommand hierarchy shallow if present.
- Clarify handling of standard I/O, exit codes, and error message formats.
- On failure, provide short diagnostic messages and reproducible input examples.

## Web Server Guidelines

- Use `axum` and `tokio` as the default framework.
- Organize routing, state management, error conversion, logging, and timeouts first.
- Define return JSON types and error formats beforehand, ensuring comprehensive returns from handlers.

## Error Handling Design

- Use `anyhow` for binary applications and `thiserror` for libraries by default.
- Minimize error types and convert them at boundaries.
- Separate display messages from debug messages.

## Testing

- Use unit tests for small functions and integration tests for those involving I/O.
- Clarify the distinction between `#[cfg(test)]` and `tests/`.

## References

Check `references/rust-workflows.md` for detailed implementation recipes and minimal templates.
