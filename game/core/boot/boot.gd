extends Node
## Boot entry point. Ring-1 only: initializes nothing genre-specific.
## Phase 3 will hand off to SceneFlow's configured start scene; until then
## it just reports a healthy boot.


func _ready() -> void:
	print("boot: ok (base-game-zero-to-hero)")
