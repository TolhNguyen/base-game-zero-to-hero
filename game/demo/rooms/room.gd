extends Node2D
## Shared demo room glue: spawn positioning, interact input, NPC/chest
## wiring, pause menu intents. Optional nodes are looked up defensively so
## both rooms share this script.


func _ready() -> void:
	get_node("/root/Log").info("demo: entered room", {"scene": name})
	_position_player()
	var npc: Interactable = get_node_or_null("%NpcInteractable")
	if npc:
		npc.interacted.connect(_on_npc_interacted)
	var chest: Interactable = get_node_or_null("%ChestInteractable")
	if chest:
		chest.interacted.connect(_on_chest_interacted)
	var pause: CanvasLayer = get_node_or_null("%PauseMenu")
	if pause:
		pause.quit_requested.connect(func() -> void: get_tree().quit())
		pause.settings_requested.connect(_open_settings)


func _unhandled_input(event: InputEvent) -> void:
	var dialogue: CanvasLayer = get_node_or_null("%DialogueBox")
	if dialogue and dialogue.is_active():
		return  # DialogueBox owns the interact action while talking
	if event.is_action_pressed(&"interact"):
		var interactor: Interactor = get_node_or_null("World/Player/Interactor")
		if interactor and interactor.try_interact():
			get_viewport().set_input_as_handled()


func _position_player() -> void:
	var flow := get_node("/root/SceneFlow")
	var spawn := String(flow.consume_spawn_point())
	var marker: Marker2D = get_node_or_null("Spawns/%s" % spawn)
	if marker == null:
		var spawns := get_node_or_null("Spawns")
		if spawns and spawns.get_child_count() > 0:
			marker = spawns.get_child(0)
	if marker:
		var player: Node2D = get_node_or_null("World/Player")
		if player:
			player.global_position = marker.global_position


func _on_npc_interacted(_actor: Node) -> void:
	var dialogue: CanvasLayer = get_node_or_null("%DialogueBox")
	if dialogue:
		dialogue.start(&"dialogue.npc_greeting")
	var state := get_node("/root/DemoState")
	state.quests.start_quest(&"quest.collect_apples")  # ERR_ALREADY_IN_USE is fine


func _on_chest_interacted(_actor: Node) -> void:
	get_node("/root/DemoState").collect_apple()
	get_node("/root/Log").info("demo: chest gave an apple", {})


func _open_settings() -> void:
	var settings: Control = get_node_or_null("%SettingsMenu")
	if settings:
		settings.open()
