# Domain: Registry (stable IDs)

- Owner role: Architect
- Last verified: 2026-07-02

Stable ID index (`core/registry/registry.gd`, autoload `Registry`) over `Definition` resources (P7).

**Invariants**
- IDs are dot-namespaced: `item.x`, `scene.y`, `achievement.z`. The ID is the identity; file paths are details.
- Duplicate or empty IDs are hard scan errors — boot and tools/check must fail, never "last one wins".
- `scan()` clears previous state (idempotent rescans).

**Gotchas**
- Phase 3 will point `scan()` at `res://content/`; until then only tests call it.
- Impact analysis = grep the ID string across the repo.
