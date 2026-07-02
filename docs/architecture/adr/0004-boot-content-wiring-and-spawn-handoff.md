# ADR-0004: Boot content wiring and spawn-point handoff

- Date: 2026-07-02
- Status: Accepted
- Approved by: Human Owner (full-autonomy grant, chat 2026-07-02)

## Context

Phase 3 needs (a) the boot scene to load game content and enter a start scene without core referencing demo paths (P8), and (b) a way for a freshly loaded scene to know which spawn point the traveler asked for — `scene.changed` fires before the new scene's nodes exist, so an event alone cannot deliver it.

## Decision

Two additive core changes: `boot.gd` scans `res://content` into Registry (if the directory exists) and travels to the scene id in the `app/start_scene_id` project setting (if set) — both data-driven, no upward code references. `SceneFlow` records the requested spawn point and exposes `consume_spawn_point() -> StringName` (one-shot) for the incoming scene's `_ready`.

## Alternatives considered

- Demo-owned boot autoload — rejected: two competing entry points confuse humans (P1).
- Passing spawn via `scene.changed` event — rejected: subscriber does not exist yet at publish time.
- Global blackboard singleton — rejected: too broad for one value; YAGNI (P6).

## Consequences

Easier: any game built on the base gets content scanning + start scene by setting one project setting. Harder: none noted. Revisit when: games need transition effects (loading screens) — that will grow SceneFlow, with its own ADR.
