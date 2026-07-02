# Project Constitution

This repository builds a **genre-agnostic base codebase for Godot 4.x 2.5D games** together with the operating system for the AI agents that help build it. This document is the highest law of the project: every rule, workflow, and piece of code must be consistent with it. It changes only through the Core-change process (see §4) with explicit Human Owner approval.

## 1. Roles

- **Human Owner** — final authority. Approves all Core-level changes, reviews commits on `main`, owns creative and product decisions, holds all secrets.
- **Super Agent** — designed this ecosystem. Not involved in daily work; recalled only under the criteria in §5.
- **High/Mid-level agent sessions** (Director, Architect, Producer, QA — see `docs/agents/`) — analyze, design, plan, write task contracts, and summon executor sessions. Free to create within governed boundaries.
- **Executor sessions** — implement exactly one task contract at a time, inside its `allowed_paths`, with evidence.

Agents are stateless CLI sessions (Claude Code, Codex, Gemini, or any other). A "role" is a hat: the role profile a session loads, not a persistent process.

## 2. Principles

**P1 — Human-First Codebase.** If all AI agents disappear, a human developer opens the Godot editor and keeps working normally. The game is a standard Godot project; no abstraction may exist solely to serve agents.

**P2 — Genre-Agnostic Core.** Nothing genre-specific lives in `game/core/`. Even top-down movement is an optional module. The core contains only what every 2.5D game needs.

**P3 — Fail Small.** Every change is small, task-scoped, and independently revertable (`git revert` of one commit). No agent can silently break the system; the cost of turning back stays low.

**P4 — Verifiable Over Plausible.** Work is proven by evidence — `tools/check` output, test results, screenshots — never by claims. "It should work" is not a completion state.

**P5 — Docs Versioned With Code.** Rules, roles, ADRs, and memory live in this repository and evolve in the same commits as the systems they describe. A stale doc is a bug.

**P6 — No Over-Engineering.** Every governance layer starts as the thinnest possible file or script and thickens only when a recorded failure (`docs/memory/failures/`) demands it. Rules are born from post-mortems, not imagination.

**P7 — Stable IDs, Not Asset Paths.** All cross-references between game data (items, entities, quests, dialogue) use string stable IDs (e.g. `item.healing_potion`). Asset file paths are never used as identifiers.

**P8 — One-Way Dependencies.** `demo → modules → core`, never the reverse. Modules never depend on other modules, only on core. Core imports nothing above it.

## 3. Language

Repository documents are written in English. Agents converse with the Human Owner in Vietnamese when the owner writes Vietnamese.

## 4. Governance — two levels only

Details live in `docs/governance/change-rules.md`; the summary here is binding:

- **Normal** — everything outside the Protected Core (`game/modules/`, `game/demo/`, `game/content/`, domain docs, skills, workflows). Process: make the change, verify it, commit to `main` with the standard message format; the dev reviews the commit log. No pre-approval needed.
- **Core** — the Protected Core paths listed in `docs/governance/protected-core.md` (this file, governance docs, `game/core/`, `tools/check`, save schema). Process: **stop before editing, warn the dev, explain why, wait for explicit approval**, then make the change and record it in an ADR.

There is no third level. Do not invent approval ceremonies beyond these.

## 5. Super Agent recall criteria

Recall the Super Agent only when one of these is on the table:

1. Changing this Constitution.
2. Changing the Protected Core boundary itself (what is protected, not a protected file).
3. Changing the agent organization or permission model.
4. Replacing the game engine.
5. An ecosystem-level incident that agent sessions and the dev cannot resolve with existing rules.

Everything else — features, modules, content, bugs, docs — is normal work and must not wait for the Super Agent.
