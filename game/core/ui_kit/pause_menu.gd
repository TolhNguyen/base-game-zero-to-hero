extends CanvasLayer
## Base pause menu. Genre-agnostic: it only pauses the tree and emits
## intents; the game (demo or a real project) decides what Settings/Quit do.
## Works with keyboard and controller (focus is grabbed on open).

signal resume_requested
signal settings_requested
signal quit_requested

@onready var _panel: Control = %Panel

## Pause state of the tree before open() — the tree may already be paused
## by something else (cutscene, modal); close() must hand that state back.
var _was_paused := false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	_was_paused = get_tree().paused
	visible = true
	get_tree().paused = true
	FocusHelper.grab_first(_panel)


func close() -> void:
	visible = false
	get_tree().paused = _was_paused


func _exit_tree() -> void:
	# Freed while open (scene torn down): don't leave the tree stuck paused.
	if visible:
		get_tree().paused = _was_paused


func _on_resume_pressed() -> void:
	resume_requested.emit()
	close()


func _on_settings_pressed() -> void:
	settings_requested.emit()


func _on_quit_pressed() -> void:
	quit_requested.emit()
