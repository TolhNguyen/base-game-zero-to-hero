extends Area2D
## Walk-over apple pickup: collects on player contact and disappears.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is TopdownPlayer:
		get_node("/root/DemoState").collect_apple()
		queue_free()
