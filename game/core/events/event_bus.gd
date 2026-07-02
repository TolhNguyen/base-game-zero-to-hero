extends Node
## Topic-based pub/sub hub. Registered as autoload `EventBus`.
## Modules communicate through this bus and never call each other directly
## (Constitution P8). Callbacks receive a single Dictionary payload.

var _subs: Dictionary = {}


func subscribe(topic: StringName, cb: Callable) -> void:
	if not _subs.has(topic):
		_subs[topic] = []
	var list: Array = _subs[topic]
	if not list.has(cb):
		list.append(cb)


func unsubscribe(topic: StringName, cb: Callable) -> void:
	if _subs.has(topic):
		_subs[topic].erase(cb)


func publish(topic: StringName, payload: Dictionary = {}) -> void:
	if not _subs.has(topic):
		return
	var dead: Array = []
	# Iterate a copy so subscribers may (un)subscribe during delivery.
	for cb: Callable in _subs[topic].duplicate():
		if cb.is_valid():
			cb.call(payload)
		else:
			dead.append(cb)
	for cb: Callable in dead:
		_subs[topic].erase(cb)


## Number of live subscribers for a topic (dead callables not yet pruned count too).
func subscriber_count(topic: StringName) -> int:
	return _subs[topic].size() if _subs.has(topic) else 0
