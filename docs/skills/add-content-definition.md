# Skill: add-content-definition

- Status: active
- Owner: Director (what) + Architect (schema)
- Evidence: commit 158ee81 (`game/content/` — item, dialogue, quest, two scene defs)

## When to use

Adding game data (items, dialogues, quests, scenes) as `.tres` Definition resources.

## Steps

1. Choose the stable id: dot-namespaced, lowercase — `item.apple`, `scene.demo_room_b`. The id is permanent; the filename is not.
2. Write the `.tres` by hand (template below). `script_class` must equal the `class_name`; the `id` property uses `&"..."` StringName syntax.
3. Place it: real game data → `game/content/<kind>/`; test-only data → `game/tests/fixtures/<module>/`. Never mix.
4. Registry scans `res://content` at boot (ADR-0004). Duplicate or empty ids fail the boot AND `tools/check` — that is by design.
5. Update the content test (`game/tests/demo/test_content.gd`): expected count + expected ids.
6. `bash tools/check.sh` → commit with evidence.

## Template

```text
[gd_resource type="Resource" script_class="ItemDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://modules/inventory/item_def.gd" id="1_def"]

[resource]
script = ExtResource("1_def")
id = &"item.apple"
display_name = "Apple"
max_stack = 99
```

## Gotchas

- `PackedStringArray("a", "b")` for string lists; `&"topic"` for StringName exports.
- A SceneDef's `scene_path` must exist — the content test checks `ResourceLoader.exists`.
- Renaming an id is a breaking change: grep the old id repo-wide first (that IS the impact analysis).
