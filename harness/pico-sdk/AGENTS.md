# Pico C Development Harness Rules

This project targets Raspberry Pi Pico WH using the Raspberry Pi Pico SDK and the VS Code Raspberry Pi Pico extension.

The local toolchain is expected under `$HOME/.pico-sdk`.

Before stopping:

1. Do not call `codex` or `copilot` from scripts.
2. Use the project harness scripts under `.agent-hooks/`.
3. Run or respect the Stop/agentStop validation pipeline.
4. If validation fails, read `.agent-hooks/state/logs/check.log`.
5. Fix the root cause instead of suppressing warnings or weakening build settings.
6. Do not delete `$HOME/.pico-sdk`.
7. Do not bypass CMake, Ninja, or the Pico SDK toolchain.
8. Do not stop until `.agent-hooks/check.sh` succeeds.

Preferred commands:

- Configure: `./.agent-hooks/configure.sh`
- Format: `./.agent-hooks/format.sh`
- Build: `./.agent-hooks/build.sh`
- Full check: `./.agent-hooks/check.sh`

The build source of truth is CMake + Ninja + Pico SDK.
Do not invent include paths manually.
Use `build/compile_commands.json` when tool-based analysis is needed.
