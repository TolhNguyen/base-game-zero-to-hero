extends Control
## Base settings screen: audio volume for now; games extend it.
## Reads/writes through the Settings autoload so values persist.

signal closed

@onready var _master: HSlider = %MasterVolume


func _ready() -> void:
	var settings := get_node_or_null("/root/Settings")
	if settings:
		_master.value = float(settings.get_value("audio.master_volume", 1.0))
	_master.value_changed.connect(_on_master_changed)


func open() -> void:
	show()
	FocusHelper.grab_first(self)


func _on_master_changed(value: float) -> void:
	var settings := get_node_or_null("/root/Settings")
	if settings:
		settings.set_value("audio.master_volume", value)


func _on_close_pressed() -> void:
	closed.emit()
	hide()
