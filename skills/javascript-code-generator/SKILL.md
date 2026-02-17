---
name: javascript-code-generator
description: Supports JavaScript code generation. Use when organizing implementation policies, creating templates, adding features, refactoring, or defining test perspectives in Vanilla JS (including Vanila JS notation), AngularJS, Vue, Nuxt, or React.
---

# JavaScript Code Generation

## Prerequisites

- Must comply with AGENTS.md, GEMINI.md, and CLAUDE.md.

## Overview

Provides guidelines for proceeding with JavaScript implementation consistently, from requirement confirmation to code generation and test perspective organization.
Prioritize the framework specified by the user; if unspecified, proceed with minimal questions or reasonable assumptions.

## Execution Steps

1. Identify the target framework: Choose one from `Vanilla JS`, `AngularJS`, `Vue`, `Nuxt`, or `React`.
2. Confirm inputs/outputs, state management, error behavior, boundary values, and rendering update conditions.
3. Align with existing code structure, naming conventions, dependencies, and testing policies.
4. Implement with minimal scope changes and clearly state verification procedures.

## Framework Selection

- `Vanilla JS`: For small-scale features without increasing dependencies, or when existing code centers on raw DOM manipulation.
- `AngularJS`: When existing code is built with AngularJS 1.x and requires incremental updates.
- `Vue`: For rapid component separation and declarative UI construction.
- `Nuxt`: When app structure including routing, SSR/SSG, and data fetching is needed.
- `React`: For extensive component reuse and state management.

## Generation Policy

- Define data structures and event contracts before proceeding to UI implementation.
- Determine failure scenarios first: explicitly handle communication failures, invalid inputs, and empty data.
- Prioritize existing style guides if available.
- Split large changes into stages and briefly explain the intent of diffs.

## References

- Common Procedure: `references/common.md`
- Vanilla JS: `references/vanilla-js.md`
- AngularJS: `references/angularjs.md`
- Vue: `references/vue.md`
- Nuxt: `references/nuxt.md`
- React: `references/react.md`
