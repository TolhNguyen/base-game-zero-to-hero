# Phase 3 — Modules + Demo Sandbox Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans (inline) — same economy deviation as Phase 2.
> **Machinery stress test:** every module task gets a real task contract in `docs/contracts/`, committed with the work. This proves the Phase-1 process on real work.

**Goal:** The five ring-2 modules + a playable Demo Sandbox: walk, talk to an NPC, loot a chest, complete a quest, switch rooms, pause, save/load — keyboard and gamepad, F5-runnable.

**Architecture:** Ring 2 (`game/modules/*` — depend ONLY on core, never on each other; cross-module effects go through EventBus or demo glue) + Ring 3 (`game/demo/` + `game/content/` data). Core gets exactly one change (boot wiring, ADR-0004).

**Tech Stack:** unchanged (Godot 4.7, gdUnit4, tools/check).

## Global Constraints

- P8 enforced by validators: module ↛ module, module ↛ demo, core ↛ anything above.
- All content references by stable ID (P7); content lives in `game/content/` as `.tres` Definitions.
- Placeholder art only: `icon.svg` sprites with modulate colors (real art = Phase 4+).
- Headless tests cannot simulate real input: modules expose pure/testable methods; `_physics_process`/`_unhandled_input` are thin wrappers.
- Every commit: `tools/check` PASS quoted; module commits reference their contract file.

## Tasks

### T1 — Contracts scaffold
`docs/contracts/README.md` (naming: `TASK-YYYY-MM-DD-NNN.yaml`, lifecycle: committed with the work, immutable after) + this plan committed.

### T2 — Module: topdown_character (contract TASK-…-101)
`game/modules/topdown_character/player.gd` (`class_name TopdownPlayer extends CharacterBody2D`): `@export speed`, pure `compute_velocity(input: Vector2) -> Vector2` (normalized diagonal), `facing: Vector2` retained from last nonzero input; `_physics_process` reads `Input.get_vector(move_left/right/up/down)`. Scene `player.tscn`: body + CollisionShape2D + Sprite2D (icon, modulate blue). Tests: velocity math, diagonal normalization, facing retention, scene instantiates.

### T3 — Module: interaction (contract …-102)
`interactable.gd` (`class_name Interactable extends Area2D`): `@export prompt: String`, `@export action_id: StringName` (stable ID of what it is), signal `interacted(actor)`, method `interact(actor)` → emit + `EventBus.publish(&"interaction.triggered", {id, actor})`. `interactor.gd` (`class_name Interactor extends Area2D`): tracks overlapping interactables, `nearest() -> Interactable`, `try_interact()` (called by player on `interact` action). Tests: nearest selection by distance, interact publishes topic + signal, empty overlap no-op.

### T4 — Module: dialogue (contract …-103)
`dialogue_def.gd` (`class_name DialogueDef extends Definition`, `@export lines: PackedStringArray`). `dialogue_box.gd` + `.tscn` (CanvasLayer panel): `start(id: StringName) -> Error` (resolves via Registry), `advance()` steps lines, publishes `&"dialogue.started"/&"dialogue.finished"` {id}; `is_active()`. Advance bound to `interact`/`ui_accept` in `_unhandled_input` thin wrapper. Tests: start resolves/errors, line stepping, finished topic, inactive advance no-op.

### T5 — Module: inventory (contract …-104)
`item_def.gd` (`class_name ItemDef extends Definition`, `@export display_name: String`, `@export max_stack: int = 99`). `inventory.gd` (`class_name Inventory extends Node`): `add(id, count) -> int` (returns overflow remainder, respects max_stack via Registry lookup), `remove(id, count) -> int` (removed amount), `count(id) -> int`, `capture()/restore()` (save provider), publishes `&"inventory.changed"` {id, delta, total}. Tests: add/remove/count, stack limit remainder, save round-trip, changed topic.

### T6 — Module: quest_lite (contract …-105)
`quest_def.gd` (`class_name QuestDef extends Definition`, `@export title: String`, `@export completion_topic: StringName`, `@export required_count: int = 1`). `quest_tracker.gd` (`class_name QuestTracker extends Node`): `start_quest(id) -> Error`, subscribes to the quest's topic, counts events, on reaching required publishes `&"quest.completed"` {id} and marks done; `progress(id) -> int`, `is_completed(id) -> bool`; `capture()/restore()`. Tests: start/subscribe/count/complete, double events after completion ignored, save round-trip.

### T7 — Content + Demo Sandbox (contract …-106)
`game/content/`: ItemDef `item.apple`; DialogueDef `dialogue.npc_greeting`; QuestDef `quest.collect_apples` (topic `&"demo.apple_collected"`, count 3); SceneDefs `scene.demo_room_a/b` (+ spawn points). `game/demo/`: `room_a.tscn` (player, NPC with Interactable→dialogue glue, 3 apple pickups publishing `demo.apple_collected` + adding `item.apple`, chest, door→`SceneFlow.goto_scene(scene.demo_room_b)`, pause menu, HUD with quest/inventory labels), `room_b.tscn` (return door), demo glue scripts under `game/demo/`. Save/load: F9 save slot 1, F10 load (demo glue registers providers).

### T8 — Boot wiring (CORE change — ADR-0004)
`boot.gd`: scan `res://content` into Registry if the dir exists; read ProjectSettings `"app/start_scene_id"`; if set, `SceneFlow.goto_scene(...)`. project.godot gains `[app] start_scene_id="scene.demo_room_a"`. Core references no demo path (data-driven — P8 intact). Commit includes ADR-0004 (hook enforces).

### T9 — Phase gate
Full `tools/check` PASS; headless run reaches room_a (log line from demo); drills stay green; README Phase 3 complete; failure entries for anything learned.
