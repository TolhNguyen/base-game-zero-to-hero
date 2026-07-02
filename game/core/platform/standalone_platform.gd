extends PlatformService
## Store-free implementation. Registered as autoload `Platform`.
## Achievements are remembered in-session (and logged) so gameplay code can
## behave identically with or without a store behind it.

var _unlocked: Dictionary = {}


func unlock_achievement(id: StringName) -> void:
	if _unlocked.has(id):
		return
	_unlocked[id] = true
	var log_svc := get_node_or_null("/root/Log")
	if log_svc:
		log_svc.info("achievement unlocked", {"id": String(id)})


func is_achievement_unlocked(id: StringName) -> bool:
	return _unlocked.has(id)


func is_feature_available(_feature: StringName) -> bool:
	return false


func platform_name() -> String:
	return "standalone"
