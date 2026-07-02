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
| 5 — Handover | Maintainer guide, final audit | **Complete** (2026-07-02) |
| Post-handover hardening | External-review remediation (ADR-0006..0009) | **Complete** (2026-07-02) |

### Post-handover hardening (2026-07-02)

An external code review was triaged and its accepted findings fixed:

- **Atomic saves** — writes go tmp → rename with a one-generation `.bak`; corrupt saves self-heal from backup (ADR-0006).
- **Lifecycle correctness** — failed scene switches and registry scans leave no partial state; the pause menu preserves pre-existing pause state (ADR-0007).
- **Fail-early inventory** — unknown/non-item IDs are rejected, consistent with every other stable-ID consumer.
- **Enforcement gaps closed** — boot smoke requires positive markers and exit code 0; `validate_deps` catches cross-module `class_name` coupling; `.githooks/`, the hook installer, and committed contracts are protected (ADR-0008).
- **Anti-symptom-fix rules** — bug-fix contracts require a `root_cause` field and an acceptance criterion general enough to defeat the cheapest patch; procedure in `docs/workflows/bug-fixing.md` (ADR-0009).

The base is operational. Human maintainers: see `docs/MAINTAINER.md`. Building a real game from this base: workflow `docs/workflows/new-game.md` (mechanical steps: "Starting a new game" in `docs/architecture/overview.md`).
