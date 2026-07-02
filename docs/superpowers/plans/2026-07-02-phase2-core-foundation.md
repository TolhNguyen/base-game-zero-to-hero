# Phase 2 — Core Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.
> **Execution note:** This plan is executed inline by the Super Agent session that wrote it (owner-approved economy deviation): tasks fix files, public signatures, and acceptance criteria; implementation detail is authored at execution time under TDD.

**Goal:** A booting Godot 4.7 project with all `game/core/` services, headless tests, and a working `tools/check` that mechanically enforces the Constitution.

**Architecture:** Ring 1 only (`game/core/` + tests). Core services are autoload singletons (`Log`, `EventBus`, `Registry`, `Settings`, `SaveService`, `SceneFlow`, `Platform`) — deliberately few, all genre-agnostic (P2). Modules/demo come in Phase 3.

**Tech Stack:** Godot 4.7-stable (ADR-0002), GDScript, gdUnit4 v6.1.3 (vendored addon), bash for `tools/check` (Git Bash on Windows).

## Global Constraints

- Engine binary: `tools/godot/Godot_v*.exe`, override via `GODOT_BIN` (ADR-0002).
- P8: core imports nothing above it; no `res://game/modules` or `res://game/demo` references inside `game/core/`.
- P7: no asset paths as identifiers; registry maps `StringName` IDs → definitions.
- P4: every task ends with `tools/check` (or its current subset) passing, output quoted in the commit body.
- Third-party code: gdUnit4 only (named in approved spec). Nothing else without owner approval.
- Commit format per `docs/governance/change-rules.md`; one task = one commit.
- These are Core paths being **created** under the Super Agent's original mandate (ADR-0001); once Phase 2 completes, all further `game/core/` edits follow the Core-change procedure.

---

### Task 1: Godot project skeleton
**Files:** `game/project.godot`, `game/core/boot/boot.tscn` (+ `boot.gd`), `game/icon.svg`
**Produces:** project boots headless; main scene = boot screen that later hands off to SceneFlow.
**Accept:** `$GODOT_BIN --headless --path game --import` exits 0; `--headless --quit-after 2` runs boot scene without errors.

### Task 2: Vendor gdUnit4 + smoke test
**Files:** `game/addons/gdUnit4/**` (v6.1.3 release zip), `game/tests/core/test_smoke.gd`
**Produces:** the headless test command used by every later task:
`$GODOT_BIN --headless --path game -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests -c`
**Accept:** smoke test (asserts `true`) passes headless; exit code 0.

### Task 3: tools/check v1
**Files:** `tools/check.sh`, `tools/check.bat` (thin wrapper)
**Produces:** single entry point running, in order: engine discovery → headless import → headless tests. Prints `CHECK: PASS|FAIL` and exits nonzero on failure.
**Accept:** `bash tools/check.sh` passes on clean tree; injecting a failing test flips it to FAIL (demonstrate, then remove).

### Task 4: core/debug — Log
**Files:** `game/core/debug/log.gd` (autoload `Log`), `game/tests/core/test_log.gd`
**Interface:** `Log.debug/info/warn/error(msg: String, ctx: Dictionary = {})`; ring buffer `get_recent(count: int) -> Array[Dictionary]`; writes to `user://logs/session.log`; level filtering via `Log.min_level`.
**Accept:** tests cover level filtering, ring buffer capacity, context merge.

### Task 5: core/events — EventBus
**Files:** `game/core/events/event_bus.gd` (autoload `EventBus`), `game/tests/core/test_event_bus.gd`
**Interface:** `publish(topic: StringName, payload: Dictionary = {})`, `subscribe(topic: StringName, cb: Callable)`, `unsubscribe(topic: StringName, cb: Callable)`. Subscribers of dead objects are auto-pruned.
**Accept:** tests cover publish/subscribe, unsubscribe, multiple subscribers, dead-object pruning, payload delivery.

### Task 6: core/registry — stable IDs
**Files:** `game/core/registry/registry.gd` (autoload `Registry`), `game/core/registry/definition.gd` (`class_name Definition extends Resource` with `id: StringName`), `game/tests/core/test_registry.gd`
**Interface:** `scan(dir: String)` loads all `Definition` resources under a directory (Phase 3 will point it at `game/content/`); `get_def(id: StringName) -> Definition`, `has_def(id) -> bool`, `ids_with_prefix(prefix: String) -> Array[StringName]`. Duplicate ID = hard error at scan.
**Accept:** tests cover scan of fixture dir, lookup, prefix query, duplicate-ID error.

### Task 7: core/save — versioned saves
**Files:** `game/core/save/save_service.gd` (autoload `SaveService`), `game/tests/core/test_save.gd`
**Interface:** `SCHEMA_VERSION: int = 1`; `register_provider(key: StringName, provider: Object)` where provider implements `capture() -> Dictionary` / `restore(data: Dictionary) -> void`; `save_game(slot: int) -> Error`, `load_game(slot: int) -> Error`, `list_slots() -> Array[int]`, `delete_slot(slot: int) -> Error`; JSON files `user://saves/slot_N.json` carrying `schema_version`; `migrations: Array[Callable]` run forward one version at a time on load.
**Accept:** tests cover round-trip, multiple providers, missing slot, forward migration (fixture v0 file → migrated), refusal to load future versions.

### Task 8: core/scene_flow — transitions
**Files:** `game/core/scene_flow/scene_flow.gd` (autoload `SceneFlow`), `game/core/scene_flow/scene_def.gd` (`class_name SceneDef extends Definition` with `scene_path: String`), `game/tests/core/test_scene_flow.gd`
**Interface:** `goto_scene(scene_id: StringName, spawn_point: StringName = &"")` — resolves via `Registry` (P7: callers never pass paths); emits `EventBus` topics `&"scene.about_to_change"` / `&"scene.changed"`; `current_scene_id() -> StringName`.
**Accept:** tests cover resolution via registry, unknown-ID error, event emission order, spawn-point payload.

### Task 9: core/settings — persisted settings
**Files:** `game/core/settings/settings.gd` (autoload `Settings`), `game/tests/core/test_settings.gd`
**Interface:** `get_value(key: String, default: Variant = null) -> Variant`, `set_value(key: String, value: Variant)` (auto-persists to `user://settings.cfg`), `reset()`; applies known keys on load: `audio.*_volume` → bus volumes, `video.window_mode`, `general.locale`.
**Accept:** tests cover persistence round-trip, defaults, audio bus application.

### Task 10: core/input — actions + remapping
**Files:** `game/core/input/input_remap.gd` (helper, not autoload), default actions in `game/project.godot` (`move_up/down/left/right`, `interact`, `pause`, `ui_*` untouched), `game/tests/core/test_input_remap.gd`
**Interface:** `InputRemap.rebind(action: StringName, event: InputEvent)`, `InputRemap.serialize() -> Dictionary`, `InputRemap.apply(data: Dictionary)`; persistence goes through `Settings` key `input.bindings`.
**Accept:** tests cover rebind, serialize/apply round-trip, unknown action error. Both keyboard and gamepad events representable.

### Task 11: core/platform — abstraction seam
**Files:** `game/core/platform/platform_service.gd` (`class_name PlatformService`), `game/core/platform/standalone_platform.gd`, autoload `Platform` bound to standalone impl, `game/tests/core/test_platform.gd`
**Interface:** `unlock_achievement(id: StringName) -> void`, `is_feature_available(feature: StringName) -> bool`, `platform_name() -> String`. Standalone: logs achievement unlocks via `Log`, features return false, name "standalone".
**Accept:** tests cover stub behavior; interface documented as the only place Steam may later plug in.

### Task 12: core/ui_kit — theme, focus, base screens
**Files:** `game/core/ui_kit/theme.tres`, `game/core/ui_kit/focus_helper.gd`, `game/core/ui_kit/pause_menu.tscn` (+ `.gd`), `game/core/ui_kit/settings_menu.tscn` (+ `.gd`), `game/tests/core/test_ui_kit.gd`
**Interface:** `FocusHelper.grab_first(container: Control)` (controller navigation entry); pause menu toggles on `pause` action, pauses tree, offers Resume/Settings/Quit; settings menu edits `Settings` values. Minimal visuals — placeholder theme.
**Accept:** tests cover focus grab and pause-state toggle (scene runner); menus operable by `ui_*` actions only (controller-ready).

### Task 13: Validators v2 + pre-commit hook
**Files:** `tools/validate_deps.sh` (P8: greps `game/core/` for `res://game/modules|res://game/demo`; greps modules for cross-module refs), `tools/validate_protected.sh` (staged diff touches protected paths ⇒ require a new `docs/architecture/adr/*.md` in the same commit), `tools/install_hooks.sh`, `.githooks/pre-commit`; wire both validators into `tools/check.sh`.
**Accept:** deliberate P8 violation fails check; staged core edit without ADR is blocked by hook; both demonstrated then reverted.

### Task 14: Domain docs + status
**Files:** `docs/memory/domains/` one page each: `save-system.md`, `events.md`, `registry.md`, `scene-flow.md`, `input.md`, `ui-kit.md`, `platform.md`; README status table row Phase 2.
**Accept:** each doc has `Owner role` + `Last verified` headers, ≤ 1 page, states invariants not code.

### Task 15: Phase gate
**Accept (all):** full `tools/check` PASS quoted in commit; violation drills from Task 13 re-run once more from clean tree; boot scene runs headless; README Phase 2 marked complete.

## Out of scope
Modules, demo content, art pipeline, Steam impl, gdlint (add only if a failure entry demands it — P6).
