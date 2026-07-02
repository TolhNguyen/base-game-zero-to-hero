extends Area2D
## Walk-through door: travels to another scene by stable ID.

@export var target_scene_id: StringName = &""
@export var spawn_point: StringName = &""

var _fired := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _fired or not body is TopdownPlayer:
		return
	_fired = true  # scene switch is deferred; don't double-fire
	get_node("/root/SceneFlow").goto_scene(target_scene_id, spawn_point)
