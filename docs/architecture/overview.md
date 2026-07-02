# Architecture Overview

> `game/` does not exist yet (built in Phase 2). This document is the contract it will be built against.

## The three rings

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

## One-way dependencies (Constitution P8)

```text
demo → modules → core
```

Never the reverse. Two corollaries:

- **Modules never import other modules.** If two modules need to talk, they do it through the core event bus or shared core interfaces. If that feels impossible, the boundary is wrong — escalate to the Architect.
- **Core never imports anything above it.** Core must compile and run with all of `modules/` and `demo/` deleted.

## Stable IDs (Constitution P7)

All cross-references between game data use string stable IDs, never asset paths or node paths. Example: a quest condition references `item.healing_potion`. The item's sprite can be renamed, moved, or replaced and nothing breaks — the ID is the identity, the asset is a detail. The registry (`game/core/registry/`) maps IDs to definitions; finding "everything affected by this item" is a grep for its ID.

## Save versioning

Every save file carries a `schema_version` integer. Loaders migrate forward version by version; they never migrate backward. Changing what gets saved means: bump `schema_version`, add a migration step, keep old saves loadable. Save schema changes are Core-level (see `docs/governance/protected-core.md`).

## Starting a new game from this base

Copy the repo → delete `game/demo/` and the demo data in `game/content/` → toggle the `modules/` the game needs → keep `core/`, `docs/`, `tools/` as-is.
