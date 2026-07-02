extends Node
## Boot entry point. Ring-1 only: nothing genre-specific, no upward code
## references (P8). Content dir and start scene are DATA, wired via
## `res://content` and the `app/start_scene_id` project setting (ADR-0004).


func _ready() -> void:
	print("boot: ok (base-game-zero-to-hero)")
	var registry := get_node_or_null("/root/Registry")
	if registry and DirAccess.dir_exists_absolute("res://content"):
		var err: int = registry.scan("res://content")
		if err != OK:
			push_error("boot: content scan failed (%d)" % err)
			return
		print("boot: content scanned (%d definitions)" % registry.count())
	var start_id := String(ProjectSettings.get_setting("app/start_scene_id", ""))
	if start_id != "":
		var flow := get_node_or_null("/root/SceneFlow")
		if flow:
			flow.goto_scene.call_deferred(StringName(start_id))
