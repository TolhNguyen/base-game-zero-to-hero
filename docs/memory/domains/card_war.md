# Domain: card_war (module)

- Owner role: Architect
- Last verified: 2026-07-03

Turn-based card-war slice (Tutorial Mission 1). Spec:
`docs/superpowers/specs/2026-07-02-card-war-vertical-slice-design.md`.

**Invariants**
- `sim/` is pure: RefCounted, plain values, no Registry/EventBus/scene access.
  `CwBuilder` is the only sim file that reads Definition resources (passed in).
- State mutates only via `CwState.play_card` (atomic: reject = zero change,
  with pending-order reservations) and `CwResolver.resolve` (7 fixed phases:
  orders, movement, combat, production, consumption, morale, end-check).
- Food formula is locked: `ceili(troops / 100.0 * 3.0)` per turn (1 thach =
  100 troops x 1 day; 1 turn = 3 days). All other numbers live in
  `CwScenarioDef` (.tres), never in code.
- Ids: `card.* general.* terrain.* map.* scenario.*` plus
  `scene.card_war_battle`.
- Map letters: P/F/R/M terrain, H/E are home/enemy city ground (cost 2).
- EventBus topics published: `card_war.victory`, `card_war.defeat` with
  `{turn}`.
- Resolver events (`{"t": ...}`) are the only UI-facing change feed.

**Gotchas**
- Seeded shuffle: sim tests that need specific cards stuff `state.hand`
  directly instead of relying on draws.
- Generals stay busy while their army or camp exists; freed on merge-home,
  disband, or camp loss.
- Boot starts `scene.card_war_battle` (`game/project.godot`
  `app/start_scene_id`); demo scenes remain but are unreached.
- Convoys are abstract: no escort/interception yet. Next iterations add
  scouting/ambush per the full spec.
