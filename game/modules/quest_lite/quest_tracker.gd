class_name QuestTracker
extends Node
## Tracks active quests by counting EventBus topic occurrences.
## SaveService provider: capture()/restore().
## EventBus topics published: &"quest.started" {id}, &"quest.completed" {id}.

var registry: Node
var bus: Node

# quest id -> {"progress": int, "done": bool}
var _quests: Dictionary = {}
# topic -> Array[StringName] quest ids listening
var _topic_quests: Dictionary = {}


func _ready() -> void:
	if registry == null:
		registry = get_node_or_null("/root/Registry")
	if bus == null:
		bus = get_node_or_null("/root/EventBus")


func start_quest(id: StringName) -> Error:
	if registry == null or not registry.has_def(id):
		push_error("QuestTracker: unknown quest id '%s'" % id)
		return ERR_DOES_NOT_EXIST
	var def: Definition = registry.get_def(id)
	if not def is QuestDef:
		push_error("QuestTracker: '%s' is not a QuestDef" % id)
		return ERR_INVALID_DATA
	if _quests.has(id):
		return ERR_ALREADY_IN_USE
	_quests[id] = {"progress": 0, "done": false}
	_listen(id, (def as QuestDef).completion_topic)
	if bus:
		bus.publish(&"quest.started", {"id": id})
	return OK


func progress(id: StringName) -> int:
	return _quests[id]["progress"] if _quests.has(id) else 0


func is_active(id: StringName) -> bool:
	return _quests.has(id) and not _quests[id]["done"]


func is_completed(id: StringName) -> bool:
	return _quests.has(id) and _quests[id]["done"]


# --- SaveService provider contract -------------------------------------------

func capture() -> Dictionary:
	var out := {}
	for id: StringName in _quests:
		out[String(id)] = {
			"progress": _quests[id]["progress"],
			"done": _quests[id]["done"],
		}
	return out


func restore(data: Dictionary) -> void:
	_quests.clear()
	_topic_quests.clear()
	for key: String in data:
		var id := StringName(key)
		_quests[id] = {
			"progress": int(data[key].get("progress", 0)),
			"done": bool(data[key].get("done", false)),
		}
		if not _quests[id]["done"] and registry and registry.has_def(id):
			var def: Definition = registry.get_def(id)
			if def is QuestDef:
				_listen(id, (def as QuestDef).completion_topic)


func _listen(id: StringName, topic: StringName) -> void:
	if topic == &"":
		return
	if not _topic_quests.has(topic):
		_topic_quests[topic] = []
		if bus:
			bus.subscribe(topic, _on_topic.bind(topic))
	_topic_quests[topic].append(id)


func _on_topic(_payload: Dictionary, topic: StringName) -> void:
	if not _topic_quests.has(topic):
		return
	for id: StringName in _topic_quests[topic]:
		if not _quests.has(id) or _quests[id]["done"]:
			continue
		_quests[id]["progress"] += 1
		var def: QuestDef = registry.get_def(id)
		if _quests[id]["progress"] >= def.required_count:
			_quests[id]["done"] = true
			if bus:
				bus.publish(&"quest.completed", {"id": id})
