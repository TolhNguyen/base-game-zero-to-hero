extends Node
## Scene transitions by stable ID. Registered as autoload `SceneFlow`.
## Emits EventBus topics so modules can react without referencing scenes:
##   &"scene.about_to_change"  {from, to, spawn_point}   (before the switch)
##   &"scene.changed"          {from, to, spawn_point}   (after the switch)

var registry: Node
var bus: Node
## Replaceable scene-switch primitive; tests stub this. Signature:
## func(scene_path: String) -> Error
var change_fn: Callable

var _current_id: StringName = &""
var _pending_spawn: StringName = &""


func _ready() -> void:
	registry = get_node_or_null("/root/Registry")
	bus = get_node_or_null("/root/EventBus")


func goto_scene(scene_id: StringName, spawn_point: StringName = &"") -> Error:
	if registry == null or not registry.has_def(scene_id):
		push_error("SceneFlow: unknown scene id '%s'" % scene_id)
		return ERR_DOES_NOT_EXIST
	var def: Definition = registry.get_def(scene_id)
	if not def is SceneDef:
		push_error("SceneFlow: id '%s' is not a SceneDef" % scene_id)
		return ERR_INVALID_DATA
	if spawn_point == &"":
		spawn_point = (def as SceneDef).default_spawn
	var payload := {"from": _current_id, "to": scene_id, "spawn_point": spawn_point}
	_pending_spawn = spawn_point
	if bus:
		bus.publish(&"scene.about_to_change", payload)
	var switcher := change_fn if change_fn.is_valid() else Callable(self, "_change_scene_real")
	var err: Error = switcher.call((def as SceneDef).scene_path)
	if err != OK:
		push_error("SceneFlow: switching to '%s' failed (%d)" % [scene_id, err])
		_pending_spawn = &""
		return err
	_current_id = scene_id
	if bus:
		bus.publish(&"scene.changed", payload)
	return OK


func current_scene_id() -> StringName:
	return _current_id


## One-shot: the spawn point requested by the last transition. The incoming
## scene calls this from _ready (events fire before that scene exists).
func consume_spawn_point() -> StringName:
	var sp := _pending_spawn
	_pending_spawn = &""
	return sp


func _change_scene_real(scene_path: String) -> Error:
	return get_tree().change_scene_to_file(scene_path)
