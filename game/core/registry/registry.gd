extends Node
## Stable ID registry. Registered as autoload `Registry`.
## Scans a directory tree for Definition resources and indexes them by id.
## Duplicate or empty ids are hard errors at scan time — better to fail the
## boot (and tools/check) than to ship ambiguous identity.

var _defs: Dictionary = {}


## Scans `dir_path` recursively for .tres/.res Definition resources.
## Clears any previous scan. Returns OK or the first error found.
func scan(dir_path: String) -> Error:
	_defs.clear()
	return _scan_dir(dir_path)


func get_def(id: StringName) -> Definition:
	if not _defs.has(id):
		push_error("Registry: unknown id '%s'" % id)
		return null
	return _defs[id]


func has_def(id: StringName) -> bool:
	return _defs.has(id)


func ids_with_prefix(prefix: String) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in _defs.keys():
		if String(id).begins_with(prefix):
			out.append(id)
	out.sort()
	return out


func count() -> int:
	return _defs.size()


func _scan_dir(dir_path: String) -> Error:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("Registry: cannot open directory '%s'" % dir_path)
		return ERR_CANT_OPEN
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var path := dir_path.path_join(name)
		if dir.current_is_dir():
			if not name.begins_with("."):
				var err := _scan_dir(path)
				if err != OK:
					return err
		elif name.ends_with(".tres") or name.ends_with(".res"):
			var res := ResourceLoader.load(path)
			if res is Definition:
				var err := _index(res, path)
				if err != OK:
					return err
		name = dir.get_next()
	return OK


func _index(def: Definition, path: String) -> Error:
	if def.id == &"":
		push_error("Registry: empty id in '%s'" % path)
		return ERR_INVALID_DATA
	if _defs.has(def.id):
		push_error("Registry: duplicate id '%s' in '%s'" % [def.id, path])
		return ERR_ALREADY_EXISTS
	_defs[def.id] = def
	return OK
