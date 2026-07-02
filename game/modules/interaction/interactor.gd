class_name Interactor
extends Area2D
## Attach under a player body. Tracks overlapping Interactables and triggers
## the nearest on demand. The owner calls `try_interact()` from its input
## handling (thin wrapper; keeps this testable headless).

var _candidates: Array[Interactable] = []


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func nearest() -> Interactable:
	var best: Interactable = null
	var best_d := INF
	for c in _candidates:
		if not is_instance_valid(c):
			continue
		var d := global_position.distance_squared_to(c.global_position)
		if d < best_d:
			best_d = d
			best = c
	return best


## Returns true if something was interacted with.
func try_interact(actor: Node = null) -> bool:
	var target := nearest()
	if target == null:
		return false
	target.interact(actor if actor else owner)
	return true


func _on_area_entered(area: Area2D) -> void:
	if area is Interactable:
		_candidates.append(area)


func _on_area_exited(area: Area2D) -> void:
	if area is Interactable:
		_candidates.erase(area)
