extends Node
## Persisted user settings. Registered as autoload `Settings`.
## Keys are "section.name" strings (e.g. "audio.master_volume").
## Known keys are applied to the engine on load and on change:
##   audio.<bus>_volume  (float 0..1)  -> AudioServer bus volume
##   general.locale      (String)      -> TranslationServer locale
## Everything else is stored verbatim for modules to read.

var config_path := "user://settings.cfg"
var autosave := true

var _cfg := ConfigFile.new()


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	_cfg = ConfigFile.new()
	_cfg.load(config_path)  # missing file is fine: empty config
	apply_all()


func get_value(key: String, default: Variant = null) -> Variant:
	var parts := _split(key)
	return _cfg.get_value(parts[0], parts[1], default)


func set_value(key: String, value: Variant) -> void:
	var parts := _split(key)
	_cfg.set_value(parts[0], parts[1], value)
	_apply(key, value)
	if autosave:
		_cfg.save(config_path)


func reset() -> void:
	_cfg = ConfigFile.new()
	if FileAccess.file_exists(config_path):
		DirAccess.remove_absolute(config_path)


func apply_all() -> void:
	for section in _cfg.get_sections():
		for name in _cfg.get_section_keys(section):
			_apply("%s.%s" % [section, name], _cfg.get_value(section, name))


func _apply(key: String, value: Variant) -> void:
	if key.begins_with("audio.") and key.ends_with("_volume"):
		var bus_name := key.trim_prefix("audio.").trim_suffix("_volume").capitalize()
		var bus := AudioServer.get_bus_index(bus_name)
		if bus >= 0:
			AudioServer.set_bus_volume_db(bus, linear_to_db(clampf(float(value), 0.0001, 1.0)))
	elif key == "general.locale":
		TranslationServer.set_locale(String(value))


func _split(key: String) -> PackedStringArray:
	var idx := key.find(".")
	assert(idx > 0, "Settings: key must be 'section.name', got '%s'" % key)
	return PackedStringArray([key.substr(0, idx), key.substr(idx + 1)])
