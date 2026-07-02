# Domain: Scene flow

- Owner role: Architect
- Last verified: 2026-07-02

Scene transitions by stable ID (`core/scene_flow/scene_flow.gd`, autoload `SceneFlow`; `SceneDef` resources).

**Invariants**
- Gameplay code calls `goto_scene(&"scene.x", spawn)` — never `change_scene_to_file` (P7).
- Event order: `scene.about_to_change` → switch → `scene.changed`. A failed switch emits no `changed` and keeps the old id.
- Spawn point defaults to the SceneDef's `default_spawn`.

**Gotchas**
- `change_fn` is injectable for tests; production uses the real tree switch.
