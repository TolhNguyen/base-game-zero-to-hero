extends CanvasLayer
## Plays DialogueDefs. One instance per scene (demo glue owns it).
## EventBus topics: &"dialogue.started" {id}, &"dialogue.finished" {id}.
## The input wrapper is thin; all logic is in start()/advance() (testable).

@onready var _speaker: Label = %Speaker
@onready var _text: Label = %Text

var registry: Node
var bus: Node

var _lines: PackedStringArray = []
var _index: int = -1
var _current_id: StringName = &""


func _ready() -> void:
	if registry == null:
		registry = get_node_or_null("/root/Registry")
	if bus == null:
		bus = get_node_or_null("/root/EventBus")
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if is_active() and (event.is_action_pressed(&"interact")
			or event.is_action_pressed(&"ui_accept")):
		advance()
		get_viewport().set_input_as_handled()


func is_active() -> bool:
	return _index >= 0


func start(dialogue_id: StringName) -> Error:
	if registry == null or not registry.has_def(dialogue_id):
		push_error("DialogueBox: unknown dialogue id '%s'" % dialogue_id)
		return ERR_DOES_NOT_EXIST
	var def: Definition = registry.get_def(dialogue_id)
	if not def is DialogueDef or (def as DialogueDef).lines.is_empty():
		push_error("DialogueBox: '%s' is not a playable DialogueDef" % dialogue_id)
		return ERR_INVALID_DATA
	_lines = (def as DialogueDef).lines
	_index = 0
	_current_id = dialogue_id
	visible = true
	_show_line()
	if bus:
		bus.publish(&"dialogue.started", {"id": dialogue_id})
	return OK


func advance() -> void:
	if not is_active():
		return
	_index += 1
	if _index >= _lines.size():
		_finish()
	else:
		_show_line()


func _show_line() -> void:
	var line := _lines[_index]
	var sep := line.find("|")
	if sep >= 0:
		_speaker.text = line.substr(0, sep)
		_text.text = line.substr(sep + 1)
	else:
		_speaker.text = ""
		_text.text = line
	_speaker.visible = not _speaker.text.is_empty()


func _finish() -> void:
	var finished_id := _current_id
	_index = -1
	_current_id = &""
	_lines = []
	visible = false
	if bus:
		bus.publish(&"dialogue.finished", {"id": finished_id})
