---
name: doc-spec-authoring
description: Create, update, and review Requirement documents, Design documents, Specification documents, and TODO lists. Use for requirement organization, acceptance criteria, I/O specifications, non-functional requirements, checking consistency with existing docs, and managing revision history.
---

# Documentation & Specification Authoring

## Prerequisites

- Comply with AGENTS.md, GEMINI.md, CLAUDE.md, and project documents. In case of conflict, prioritize source code.
- Do not overfill unknowns with guesses; explicitly mark them as gaps in the documentation.

## Scope

- `Requirement Document`: Background, objectives, scope, functional requirements, non-functional requirements, constraints, acceptance criteria.
- `Design Document`: Architecture, responsibility separation, data models, external integrations, error handling, operational aspects.
- `Specification Document`: Inputs/outputs, boundary values, state transitions, exceptions, compatibility, external contracts.
- `TODO Document`: Implementation tasks, verification tasks, unresolved items, priorities.

## Execution Steps

1. Gather existing materials and define target documents and update scope.
2. Check differences between existing code and documents, organizing facts based on current behavior.
3. Classify uncertain items as "Confirmed," "Assumed," or "Undecided."
4. Determine document structure and fill input information for each section.
5. Explicitly document numeric conditions, boundary values, error behavior, and constraints.
6. Refine acceptance criteria into testable statements.
7. Check for terminology inconsistencies, contradictions, and omissions, then update revision history.

## Writing Rules

- Base on one meaning per sentence; avoid excessive subject omission.
- Clearly separate mandatory requirements from recommended ones.
- Quantify whenever possible. Example: Instead of "fast," use "95th percentile under 300ms."
- Write error conditions separately: occurrence conditions, return content, user impact, and recovery methods.
- Always add compatibility impact and migration strategy when changing specifications.

## Minimal Checklist

- Objectives and scope can be explained in 3 lines or less.
- Functional requirements include input, processing, output, and failure cases.
- Non-functional requirements cover performance, availability, security, and operations.
- Acceptance criteria are in observable forms.
- Unresolved items are identifiable within the document.

## References

Check `references/document-templates.md` for document templates and section guidelines.
Check `references/review-checklist.md` for review perspectives and quality gates.
