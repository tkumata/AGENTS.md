---
name: embedded-c-coding
description: Supports design, implementation, review, refactoring, and testing of embedded C for microcontroller boards. Use for tasks involving peripheral drivers, interrupts, timing control, low power consumption, HAL separation, log design, Arduino IDE, or Raspberry Pi Pico SDK.
---

# Embedded C Coding

## Prerequisites

- Must comply with AGENTS.md, GEMINI.md, and CLAUDE.md.

## Overview

Provides guidelines for safely proceeding with C implementation for microcontroller boards with minimal prerequisite checks.
Prioritize existing code, documentation, and board-specific conventions.

## Process

1. Confirm target board and development environment. State assumptions if undefined.
2. Confirm objectives, I/O, timing requirements, interrupt requirements, and low-power requirements.
3. Align with existing naming conventions, module separation, error policies, and logging policies.
4. Minimize changes and proceed with unit tests followed by on-target verification.

## Coding Guidelines

- Use `stdint.h` and `stdbool.h` by default; use fixed-width integer types.
- Limit `volatile` usage to hardware registers and ISR shared variables, documenting reasons in comments.
- Use `static` to clarify internal linkage and minimize public APIs.
- Avoid expressions or macros with side effects; use functions if necessary.
- Structure loops and branches so that worst-case execution time is readable.

## Interrupts and Concurrency

- Keep ISRs short; offload heavy processing to the main loop via flags or ring buffers.
- Minimize critical sections for shared data, protecting with atomics or interrupt disabling if necessary.
- Explicitly comment on suspected race conditions and record reproduction conditions.

## Time and Timing

- Base timeouts and periodic processing on monotonic counters.
- Explicitly state units and create conversion functions (ms/us/clock) if necessary.

## Logging and Error Handling

- Express errors via return values and log failures.
- Design logging to be suppressible and capable of being disabled in production builds.

## Portability

- Encapsulate board-dependent parts within a HAL layer and separate upper-level logic.
- Absorb environment differences (e.g., Arduino IDE, Pico SDK) with thin wrappers.

## Testing

- Combine host-based unit tests and on-target smoke tests whenever possible.
- Document critical boundary conditions with reproduction inputs in comments.

## References

Check `references/embedded-workflows.md` for specific implementation recipes and templates.
