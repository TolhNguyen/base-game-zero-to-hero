extends Node
## Structured logger. Registered as autoload `Log`.
## Ring buffer keeps recent entries for the debug overlay; WARN+ also goes
## to the console and everything goes to user://logs/session.log.

enum Level { DEBUG, INFO, WARN, ERROR }

var min_level: int = Level.DEBUG
var ring_capacity: int = 200

var _ring: Array[Dictionary] = []
var _file: FileAccess


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://logs")
	_file = FileAccess.open("user://logs/session.log", FileAccess.WRITE)


func debug(msg: String, ctx: Dictionary = {}) -> void:
	_write(Level.DEBUG, msg, ctx)


func info(msg: String, ctx: Dictionary = {}) -> void:
	_write(Level.INFO, msg, ctx)


func warn(msg: String, ctx: Dictionary = {}) -> void:
	_write(Level.WARN, msg, ctx)


func error(msg: String, ctx: Dictionary = {}) -> void:
	_write(Level.ERROR, msg, ctx)


## Returns up to `count` most recent entries, oldest first.
func get_recent(count: int = 50) -> Array[Dictionary]:
	return _ring.slice(maxi(0, _ring.size() - count))


func _write(level: int, msg: String, ctx: Dictionary) -> void:
	if level < min_level:
		return
	var entry := {"ticks": Time.get_ticks_msec(), "level": level, "msg": msg, "ctx": ctx}
	_ring.append(entry)
	if _ring.size() > ring_capacity:
		_ring = _ring.slice(_ring.size() - ring_capacity)
	var suffix := "" if ctx.is_empty() else " " + JSON.stringify(ctx)
	var line := "%s [%s] %s%s" % [
		Time.get_datetime_string_from_system(), Level.keys()[level], msg, suffix
	]
	if level >= Level.WARN:
		printerr(line)
	if _file:
		_file.store_line(line)
		_file.flush()
