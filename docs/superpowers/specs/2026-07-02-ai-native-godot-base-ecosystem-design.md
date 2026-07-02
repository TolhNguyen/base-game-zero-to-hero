# Design: AI-Native Godot Base-Game Ecosystem

- **Date**: 2026-07-02
- **Status**: Approved by owner (chat session, 2026-07-02)
- **Owner**: Human Owner (nguyenquoctin2612@gmail.com)
- **Author**: Super Agent (Claude)

## 1. What we are building

A single product: a **genre-agnostic base codebase ("factory") for Godot 4.x 2.5D games**, plus the AI-agent operating system around it. It is NOT a specific game. Future games (card strategy, RPG, puzzle, ...) will be started by copying this base, deleting demo content, and keeping the core + agent machinery.

There is no release timeline. Every phase is gated by completion criteria, not dates.

### Definition of done (for the whole base)

1. Clone repo → open Godot → F5 → Demo Sandbox runs; every system is exercisable with keyboard and gamepad.
2. A fresh agent session (any CLI: Claude Code, Codex, Gemini) reads `AGENTS.md` and can correctly state its role, permissions, how to take a task, and how to verify work.
3. A human dev who never reads the agent docs can still understand and extend the code (standard Godot project, no agent-only abstractions).
4. `tools/check` passes: lint, headless tests, schema validation, dependency-direction validation, Protected Core validation.
5. Starting a new game = copy base + delete `game/demo/` and `game/content/` demo data + keep everything else.

## 2. Non-negotiable principles (will go into CONSTITUTION.md)

1. **Human-first codebase**: if all AI agents disappear, a dev can keep coding normally in the Godot editor.
2. **Genre-agnostic core**: nothing genre-specific in `game/core/`. Even top-down movement is an optional module.
3. **Fail small**: every change is independently revertable; agents cannot silently break the system.
4. **Verifiable over plausible**: work is proven by `tools/check` output and evidence, never by claims.
5. **Docs are versioned with code**: rules, roles, ADRs, memory live in the repo.
6. **No over-engineering**: every governance layer starts as the thinnest possible file/script and only thickens after a real failure demands it (failure-driven governance).
7. **Stable IDs, not asset paths**: all cross-references (items, entities, quests, dialogue) use string stable IDs.
8. **One-way dependencies**: `demo → modules → core`. Never the reverse. Modules never depend on each other, only on core.

## 3. Source architecture (three rings)

```text
game/
  core/        ← RING 1 — Protected Core, genre-agnostic, every game needs it
    events/       event bus (modules communicate through it, no cross-calls)
    save/         versioned save system with migration hooks from day 1
    registry/     stable ID registry
    scene_flow/   scene transitions, spawn points, loading
    input/        action map, remapping, keyboard + gamepad
    settings/     audio/video/language, persisted
    ui_kit/       theme, controller focus navigation, base pause/settings screens
    platform/     empty abstraction (Steam plugs in here later)
    debug/        logger, debug overlay, console
  modules/     ← RING 2 — optional, per-game toggles, depend only on core
    topdown_character/   2.5D movement, 4/8-direction animation, Y-sort
    interaction/         interactables, interaction zones, prompts
    dialogue/            data-driven dialogue
    inventory/           items + bags
    quest_lite/          conditions + actions, demonstrates extensibility
  demo/        ← RING 3 — Demo Sandbox; deletable when building a real game
  content/     ← data definitions (items, dialogues, ...) as resources/JSON, referenced by stable ID
  tests/       ← gdUnit4, headless-runnable
```

**Language**: 100% GDScript. Owner's C# expertise is applied to architecture/interface review. Godot .NET allows adding C# modules later for a real game without changing the base.

## 4. Agent organization

Agents are **stateless CLI sessions** (Claude Code, Codex, Gemini). "Roles" are hats: a role profile document that a session loads. The human summons mid/high-level sessions; those write task contracts and summon low-level executor sessions.

```text
AGENTS.md            ← single entry point, tool-agnostic; all CLIs read this
CLAUDE.md, GEMINI.md ← 3-5 lines, pointer to AGENTS.md
docs/
  CONSTITUTION.md    ← ~2 pages, English, immutable principles
  agents/            ← 4 role profiles: director.md, architect.md, producer.md, qa.md
  governance/        ← protected-core.md, change-rules.md, task-contract-template.md
  architecture/      ← overview.md + adr/ (numbered, immutable; supersede, never edit)
  memory/            ← domains/ (one file per system), failures/ (post-mortems)
  skills/            ← markdown skills, created from real usage, lifecycle: draft → active → deprecated
  workflows/         ← markdown workflows with gates
  art/               ← asset-spec.md (the "brief" handed to external AI image tools)
```

### Roles (start with 4; split only when one is genuinely overloaded)

- **Director**: product/design intent, demo scope, art direction, UX intent.
- **Architect**: technical design, module contracts, reviews architecture compliance.
- **Producer**: turns specs into plans + task contracts, tracks status.
- **QA/Verifier**: defines acceptance criteria, runs verification, gates completion.

### Task contract (for executor sessions)

Minimum fields: task_id, objective, context, inputs, expected_outputs, allowed_paths, forbidden_actions, acceptance_criteria, required_evidence, iteration_limit, escalation_conditions, report_format. Tasks must be small enough to verify and revert independently.

### Learning loop

Every significant failure creates an entry in `docs/memory/failures/` with symptom, root cause, detection, and **one system action** (new rule / new test / skill fix). No system action → entry stays open. This is the only mechanism allowed to thicken governance.

## 5. Governance — exactly 2 levels

| Level | Scope | Process |
|---|---|---|
| **Normal** | `game/modules/`, `game/demo/`, `game/content/`, domain docs, skills, workflows | Agent works → runs `tools/check` → commits to `main` with standard message (task ID + evidence) → dev reviews commit log. No pre-approval. |
| **Core** | `game/core/`, `CONSTITUTION.md`, `docs/governance/`, `tools/check` itself, save schema, stable ID rules | Agent **stops, warns, explains, waits for dev approval**, then changes + writes a short ADR. |

Enforcement is mechanical, not honor-based: `tools/check` + a git pre-commit hook detect diffs touching Core paths without a new ADR → block the commit. The ADR is the record of dev approval.

Work happens directly on `main` (team of 1–2). Rollback = `git revert` of small, task-scoped commits.

## 6. Verification (local only, cheap)

- `tools/check` — one command: gdlint/format → Godot headless import → gdUnit4 tests → stable ID registry validation → dependency-direction validation (script greps `preload`/class usage) → Protected Core path check.
- Git pre-commit hook runs a fast subset.
- Task evidence = `tools/check` output + screenshots from headless demo runs where visuals matter.
- No cloud CI. Scripts are written so wrapping them in GitHub Actions later takes minutes.

## 7. Art pipeline (integration only)

Art is 100% AI-generated outside the repo (owner or a friend, using external AI tools). The repo provides the **integration contract**:

- `docs/art/asset-spec.md`: sprite sizes, directions, frame counts, pivots, naming conventions — the brief given to image-generation AI.
- `tools/` scripts: background removal check, frame normalization, sprite-sheet packing, naming enforcement.
- Simple states: `assets/incoming/` → validate + dev eyeballs → `assets/` (approved). No 8-state lifecycle.
- Versioned Godot import presets (e.g., filtering off for pixel art).

## 8. Steam / platform

Deferred. Only `game/core/platform/` abstraction seam + one page of notes now. Real Steamworks integration happens per-game, later.

## 9. Roadmap (criteria-gated)

1. **Blueprint** — Constitution, AGENTS.md, role profiles, governance docs, templates. Done when: a fresh agent session self-describes its permissions correctly. Hard cap: < 20 pages total.
2. **Core Foundation** — Godot project + `game/core/` + tests + working `tools/check`. Done when: a deliberate rule violation is blocked; tests pass headless.
3. **Modules + Demo Sandbox** — the 5 ring-2 modules + playable demo. Every module must be built via the task-contract process (stress test of the machinery itself).
4. **Agent Production Hardening** — codify phase-3 practices into skills/workflows; art integration pipeline.
5. **Handover** — maintainer guide, Super Agent recall criteria, final audit.

## 10. Success metrics

- % of executor tasks completed without human correction.
- Time from idea → merged verified change.
- Scope violations caught by `tools/check` (catching them = the system works).
- After 2 weeks away, time for the dev to resume correctly.

## 11. Explicitly rejected / deferred alternatives

- 10+ agent roles → rejected (maintenance cost for 1–2 devs); start with 4.
- 4-level change management with approval matrix → collapsed to 2 levels per owner decision.
- Cloud CI → rejected for now (owner wants local-only, frugal).
- Separate structured audit log → git history + ADRs cover it at this scale.
- 8-state skill lifecycle → 3 states (draft/active/deprecated).
- Knowledge graph/registry tooling → stable IDs + grep; a YAML registry only for relations invisible to grep (asset lineage).
- C# codebase → GDScript for agent fluency and zero build step.
