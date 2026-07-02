extends Node
## Versioned save/load. Registered as autoload `SaveService`.
##
## Providers own their data: any system that wants to be saved registers a
## provider object implementing `capture() -> Dictionary` and
## `restore(data: Dictionary) -> void`. The service never knows what is
## inside provider data (P2: genre-agnostic).
##
## Save files are JSON at user://saves/slot_N.json carrying `schema_version`.
## Migrations run forward one version at a time on load; loading a file
## newer than SCHEMA_VERSION is refused (never migrate backward).
## Changing SCHEMA_VERSION or the file layout is a Core-level change.

const SCHEMA_VERSION: int = 1
const SAVE_DIR := "user://saves"

## migrations[v] converts a raw save Dictionary from version v to v+1.
var migrations: Array[Callable] = []

var _providers: Dictionary = {}


func register_provider(key: StringName, provider: Object) -> void:
	assert(provider.has_method("capture") and provider.has_method("restore"),
		"SaveService: provider '%s' must implement capture() and restore()" % key)
	_providers[key] = provider


func unregister_provider(key: StringName) -> void:
	_providers.erase(key)


## Writes are atomic (P3): the document goes to a .tmp file first, the
## previous save (if any) is kept as .bak, then .tmp is renamed into place.
## A crash at any point leaves either the old save or the old save + .bak.
func save_game(slot: int) -> Error:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var data := {}
	for key: StringName in _providers:
		data[String(key)] = _providers[key].capture()
	var doc := {"schema_version": SCHEMA_VERSION, "data": data}
	var path := _slot_path(slot)
	var tmp_path := path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(doc, "\t"))
	file.close()
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(path + ".bak")
		var err := DirAccess.rename_absolute(path, path + ".bak")
		if err != OK:
			return err
	return DirAccess.rename_absolute(tmp_path, path)


func load_game(slot: int) -> Error:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return ERR_DOES_NOT_EXIST
	var err := _load_from(slot, path)
	if err == ERR_FILE_CORRUPT and FileAccess.file_exists(path + ".bak"):
		push_warning("SaveService: slot %d is corrupt, restoring from backup" % slot)
		return _load_from(slot, path + ".bak")
	return err


func _load_from(slot: int, path: String) -> Error:
	var text := FileAccess.get_file_as_string(path)
	var doc: Variant = JSON.parse_string(text)
	if doc == null or not doc is Dictionary or not doc.has("schema_version"):
		return ERR_FILE_CORRUPT
	var version := int(doc["schema_version"])
	if version > SCHEMA_VERSION:
		push_error("SaveService: slot %d is schema v%d, newer than supported v%d"
			% [slot, version, SCHEMA_VERSION])
		return ERR_INVALID_DATA
	while version < SCHEMA_VERSION:
		if version >= migrations.size() or not migrations[version].is_valid():
			push_error("SaveService: no migration from schema v%d" % version)
			return ERR_METHOD_NOT_FOUND
		doc = migrations[version].call(doc)
		version += 1
		doc["schema_version"] = version
	var data: Dictionary = doc.get("data", {})
	for key: StringName in _providers:
		if data.has(String(key)):
			_providers[key].restore(data[String(key)])
	return OK


func list_slots() -> Array[int]:
	var out: Array[int] = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return out
	for name in dir.get_files():
		if name.begins_with("slot_") and name.ends_with(".json"):
			out.append(int(name.trim_prefix("slot_").trim_suffix(".json")))
	out.sort()
	return out


func delete_slot(slot: int) -> Error:
	if not FileAccess.file_exists(_slot_path(slot)):
		return ERR_DOES_NOT_EXIST
	for suffix in [".bak", ".tmp"]:
		if FileAccess.file_exists(_slot_path(slot) + suffix):
			DirAccess.remove_absolute(_slot_path(slot) + suffix)
	return DirAccess.remove_absolute(_slot_path(slot))


func _slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]
