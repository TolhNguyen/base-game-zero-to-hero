class_name InputRemap
extends RefCounted
## Runtime input rebinding helpers. Not an autoload: InputMap is already a
## global singleton; these are stateless functions over it.
## Persistence: callers store `serialize()` output under the Settings key
## "input.bindings" and call `apply()` with it at startup.

## Actions owned by the engine/UI layer; never serialized or rebound in bulk.
const _BUILTIN_PREFIX := "ui_"


## Replaces every binding of `action` with the single `event`.
static func rebind(action: StringName, event: InputEvent) -> Error:
	if not InputMap.has_action(action):
		push_error("InputRemap: unknown action '%s'" % action)
		return ERR_DOES_NOT_EXIST
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	return OK


## Adds `event` to `action`, keeping existing bindings (e.g. keyboard + pad).
static func add_binding(action: StringName, event: InputEvent) -> Error:
	if not InputMap.has_action(action):
		push_error("InputRemap: unknown action '%s'" % action)
		return ERR_DOES_NOT_EXIST
	InputMap.action_add_event(action, event)
	return OK


## Snapshot of all game actions (built-in ui_* excluded) as portable data.
static func serialize() -> Dictionary:
	var out := {}
	for action: StringName in InputMap.get_actions():
		if String(action).begins_with(_BUILTIN_PREFIX):
			continue
		var events := []
		for ev: InputEvent in InputMap.action_get_events(action):
			events.append(var_to_str(ev))
		out[String(action)] = {
			"deadzone": InputMap.action_get_deadzone(action),
			"events": events,
		}
	return out


## Applies a `serialize()` snapshot. Unknown actions are skipped with a log.
static func apply(data: Dictionary) -> void:
	for action_name: String in data:
		var action := StringName(action_name)
		if not InputMap.has_action(action):
			push_warning("InputRemap: skipping unknown action '%s'" % action)
			continue
		var entry: Dictionary = data[action_name]
		InputMap.action_erase_events(action)
		InputMap.action_set_deadzone(action, float(entry.get("deadzone", 0.5)))
		for ev_str: String in entry.get("events", []):
			var ev: Variant = str_to_var(ev_str)
			if ev is InputEvent:
				InputMap.action_add_event(action, ev)


## Restores project-default bindings (discards runtime rebinds).
static func reset_to_defaults() -> void:
	InputMap.load_from_project_settings()
