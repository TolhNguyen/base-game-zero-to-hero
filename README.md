# base-game-zero-to-hero

A **genre-agnostic base codebase for Godot 4.x 2.5D games**, co-developed by humans and AI agents. This repository is a factory, not a game: future games (card strategy, RPG, puzzle, ...) start by copying this base, deleting the demo content, and keeping the core systems and the agent operating machinery.

## For humans

One-time setup after cloning: download the engine per `tools/godot/README.md`, then run `bash tools/install_hooks.sh` (activates governance pre-commit checks). Verify everything with `bash tools/check.sh`.

Open the project in Godot 4.x and press F5 (playable Demo Sandbox arrives in Phase 3). This is a standard Godot project — you can read, run, and extend it without any AI tooling or agent documentation. If every AI agent disappeared tomorrow, development continues normally.

## For AI agents

Read `AGENTS.md` first. It is the entry point for every agent session.

## Repository map

| Path | What it is |
|---|---|
| `AGENTS.md` | Agent entry point — how AI sessions work here |
| `CONSTITUTION.md` | Immutable project principles and governance |
| `game/` | The Godot project (Phase 2+) |
| `docs/` | Governance, architecture, agent roles, project memory |
| `tools/` | Local validators — `tools/check` (Phase 2+) |

## Status

| Phase | Deliverable | Status |
|---|---|---|
| 1 — Blueprint | Constitution, roles, governance docs | **Complete** (2026-07-02) |
| 2 — Core Foundation | `game/core/`, tests, `tools/check` | **Complete** (2026-07-02) |
| 3 — Modules + Demo Sandbox | 5 gameplay modules, playable demo | **Complete** (2026-07-02) |
| 4 — Production Hardening | Skills, workflows, art integration | **Complete** (2026-07-02) |
| 5 — Handover | Maintainer guide, final audit | **In progress** |
