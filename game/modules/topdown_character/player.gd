class_name TopdownPlayer
extends CharacterBody2D
## Reusable top-down player body: normalized 8-direction movement + facing.
## Movement math is pure (`compute_velocity`) so it is testable headless;
## `_physics_process` is only a thin input wrapper.

@export var speed: float = 120.0

## Last nonzero movement direction; modules/demo read this for animation
## and interaction casting. Defaults to "down" (toward camera).
var facing: Vector2 = Vector2.DOWN


func compute_velocity(input: Vector2) -> Vector2:
	if input == Vector2.ZERO:
		return Vector2.ZERO
	var dir := input.normalized() if input.length() > 1.0 else input
	facing = dir.normalized()
	return dir * speed


func _physics_process(_delta: float) -> void:
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = compute_velocity(input)
	move_and_slide()
