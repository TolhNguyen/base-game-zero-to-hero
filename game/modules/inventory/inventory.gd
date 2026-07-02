class_name Inventory
extends Node
## Holds item counts by stable ID (one stack per id — the simplest model
## that demonstrates the pattern; per-slot bags arrive when a game needs
## them, P6). SaveService provider: capture()/restore().
## EventBus topic: &"inventory.changed" {id, delta, total}.

var registry: Node
var bus: Node

var _counts: Dictionary = {}


func _ready() -> void:
	if registry == null:
		registry = get_node_or_null("/root/Registry")
	if bus == null:
		bus = get_node_or_null("/root/EventBus")


## Adds up to `count` units. Returns the overflow that did NOT fit.
## Unknown or non-item ids are rejected outright (fail early, like the
## other id consumers); the whole `count` comes back as overflow.
func add(id: StringName, count: int = 1) -> int:
	if count <= 0:
		return 0
	var def := _item_def(id)
	if def == null:
		push_error("Inventory: unknown item id '%s'" % id)
		return count
	var limit := def.max_stack
	var current: int = _counts.get(id, 0)
	var accepted := mini(count, limit - current)
	if accepted <= 0:
		return count
	_counts[id] = current + accepted
	_announce(id, accepted)
	return count - accepted


## Removes up to `count` units. Returns how many were actually removed.
func remove(id: StringName, count: int = 1) -> int:
	if count <= 0:
		return 0
	var current: int = _counts.get(id, 0)
	var removed := mini(count, current)
	if removed <= 0:
		return 0
	if current - removed == 0:
		_counts.erase(id)
	else:
		_counts[id] = current - removed
	_announce(id, -removed)
	return removed


func count(id: StringName) -> int:
	return _counts.get(id, 0)


func item_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in _counts.keys():
		out.append(id)
	out.sort()
	return out


# --- SaveService provider contract -------------------------------------------

func capture() -> Dictionary:
	var out := {}
	for id: StringName in _counts:
		out[String(id)] = _counts[id]
	return out


func restore(data: Dictionary) -> void:
	_counts.clear()
	for key: String in data:
		_counts[StringName(key)] = int(data[key])


func _item_def(id: StringName) -> ItemDef:
	if registry and registry.has_def(id):
		var def: Definition = registry.get_def(id)
		if def is ItemDef:
			return def as ItemDef
	return null


func _announce(id: StringName, delta: int) -> void:
	if bus:
		bus.publish(&"inventory.changed",
			{"id": id, "delta": delta, "total": count(id)})
