---
name: code-review
description: Systematically detect and report bugs, regression risks, deviations from specifications, security issues, performance degradation, and insufficient testing in code reviews. Use for PR reviews, diff reviews, quality checks after implementation changes, pre-release checks, and responding to review requests.
---

# Code Review

## Prerequisites

- Must comply with AGENTS.md, GEMINI.md, and CLAUDE.md.
- If specifications contradict between documentation and code, prioritize the actual behavior of existing code.

## Objective

Identify harmful issues from changes with priority and provide actionable feedback that leads directly to fixes.

## Execution Steps

1. List changed files and read diffs that affect behavior first.
2. Inspect for correctness, security, data integrity, and availability risks in order of severity.
3. Check for specification deviations and inconsistencies with existing behavior, identifying reproduction conditions.
4. Verify if necessary tests for regression prevention exist; propose specific additions if lacking.
5. Clearly state "what is the issue," "why it is an issue," and "how to fix it" briefly.

## Priority of Feedback

- `Critical`: Data corruption, privilege escalation, secret leakage, crashes, widespread regressions.
- `High`: Specification violations, malfunction of major features, unmonitorable failures, risk of operational incapacity.
- `Medium`: Performance degradation, missing boundary values, missing exception handling, maintainability decline due to lack of tests.
- `Low`: Suggestions for readability or consistency improvements.

## Output Rules

- List feedback in order of severity.
- Attach target file names and line numbers to each comment.
- Explicitly state premises if assumptions are involved.
- If no issues are found, explicitly state "No critical issues found" and supplement with remaining verification risks only.

## Prohibitions

- Do not make assertions without evidence.
- Do not prioritize minor preferences that have no explainable harmful effects.
- Do not stop at pointing out issues; always attach a minimal fix strategy or additional test strategy.

## References

Open `references/review-workflow.md` to check detailed perspectives as needed.
