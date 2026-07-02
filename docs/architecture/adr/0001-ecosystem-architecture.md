# ADR-0001: Adopt the AI-native ecosystem design

- Date: 2026-07-02
- Status: Accepted
- Approved by: Human Owner (chat session, 2026-07-02)

## Context

Greenfield repository. The owner (1–2 dev team, frugal budget) wants a reusable, genre-agnostic Godot 4.x 2.5D base codebase co-developed with AI agent sessions across multiple CLIs (Claude Code, Codex, Gemini), with governance strong enough to prevent silent breakage but light enough for a tiny team.

## Decision

Adopt the design in `docs/superpowers/specs/2026-07-02-ai-native-godot-base-ecosystem-design.md`: three-ring architecture (`demo → modules → core`), four agent roles, two-level governance (Normal / Core), local-only verification via `tools/check`, GDScript throughout.

## Alternatives considered

- 10+ agent roles — rejected: maintenance cost exceeds value for 1–2 devs.
- 4-level change management with approval matrix — rejected by owner: collapsed to 2 levels.
- Cloud CI (GitHub Actions) — rejected for now: owner wants local-only, frugal.
- Separate structured audit log — rejected: git history + ADRs cover it at this scale.
- 8-state skill lifecycle — rejected: 3 states (draft/active/deprecated) suffice.
- Knowledge-graph tooling — rejected: stable IDs + grep; YAML registry only for grep-invisible relations.
- C# codebase — rejected: GDScript for agent fluency and zero build step (owner is a C# expert; that skill is applied to architecture review instead).

## Consequences

Easier: starting new games (copy base, delete demo); onboarding stateless agent sessions; reverting mistakes (one task = one commit). Harder: cross-module features must route through the core event bus; governance may thicken only via recorded failures (P6). Revisit when: a real game project starts, or Phase 3 shows the task-contract process is too heavy.
