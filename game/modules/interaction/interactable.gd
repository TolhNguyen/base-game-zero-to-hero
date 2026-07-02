class_name Interactable
extends Area2D
## Something the player can interact with. Owners connect to `interacted`
## (demo glue / other systems listen on the EventBus topic instead).

## Stable ID describing what this is (P7), e.g. &"npc.elder", &"chest.room_a".
@export var action_id: StringName = &""
## Short UI prompt, e.g. "Talk", "Open".
@export var prompt: String = "Interact"

signal interacted(actor: Node)


func interact(actor: Node) -> void:
	interacted.emit(actor)
	var bus := get_node_or_null("/root/EventBus")
	if bus:
		bus.publish(&"interaction.triggered", {"id": action_id, "actor": actor})
