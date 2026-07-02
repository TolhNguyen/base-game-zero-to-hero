extends Node
## Demo-only autoload (`DemoState`): owns cross-room state (inventory,
## quests), wires SaveService providers, and binds F9/F10 save/load.
## Deleting the demo = remove this autoload line + app/start_scene_id
## from project.godot (see README "starting a real game").

var inventory: Inventory
var quests: QuestTracker


func _ready() -> void:
	inventory = Inventory.new()
	inventory.name = "Inventory"
	add_child(inventory)
	quests = QuestTracker.new()
	quests.name = "Quests"
	add_child(quests)
	var save := get_node("/root/SaveService")
	save.register_provider(&"inventory", inventory)
	save.register_provider(&"quests", quests)
	save.register_provider(&"world", self)


## SaveService provider: which scene the player was in.
func capture() -> Dictionary:
	return {"scene": String(get_node("/root/SceneFlow").current_scene_id())}


func restore(data: Dictionary) -> void:
	var scene_id := String(data.get("scene", ""))
	if scene_id != "":
		var flow := get_node("/root/SceneFlow")
		flow.goto_scene.call_deferred(StringName(scene_id))


func collect_apple() -> void:
	inventory.add(&"item.apple", 1)
	get_node("/root/EventBus").publish(&"demo.apple_collected", {})


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var log_svc := get_node("/root/Log")
		if event.physical_keycode == KEY_F9:
			var err: int = get_node("/root/SaveService").save_game(1)
			log_svc.info("demo: save slot 1", {"result": err})
		elif event.physical_keycode == KEY_F10:
			var err: int = get_node("/root/SaveService").load_game(1)
			log_svc.info("demo: load slot 1", {"result": err})
