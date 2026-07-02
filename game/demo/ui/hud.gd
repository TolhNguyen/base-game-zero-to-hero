extends CanvasLayer
## Demo HUD: quest status + apple count, fed by EventBus.

@onready var _quest_label: Label = %QuestLabel
@onready var _items_label: Label = %ItemsLabel


func _ready() -> void:
	var bus := get_node("/root/EventBus")
	bus.subscribe(&"inventory.changed", _on_change)
	bus.subscribe(&"quest.started", _on_change)
	bus.subscribe(&"quest.completed", _on_change)
	_refresh()


func _exit_tree() -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.unsubscribe(&"inventory.changed", _on_change)
		bus.unsubscribe(&"quest.started", _on_change)
		bus.unsubscribe(&"quest.completed", _on_change)


func _on_change(_payload: Dictionary) -> void:
	_refresh()


func _refresh() -> void:
	var state := get_node("/root/DemoState")
	_items_label.text = "Apples: %d" % state.inventory.count(&"item.apple")
	var quest_id := &"quest.collect_apples"
	if state.quests.is_completed(quest_id):
		_quest_label.text = "Quest: COMPLETE!"
	elif state.quests.is_active(quest_id):
		_quest_label.text = "Quest: apples %d/3" % state.quests.progress(quest_id)
	else:
		_quest_label.text = "Quest: talk to the elder (green)"
