extends GdUnitTestSuite

const PlayerScene := preload("res://modules/topdown_character/player.tscn")
const PlayerScript := preload("res://modules/topdown_character/player.gd")


func _fresh() -> TopdownPlayer:
	return auto_free(PlayerScript.new())


func test_cardinal_velocity_uses_speed() -> void:
	var p := _fresh()
	p.speed = 100.0
	assert_that(p.compute_velocity(Vector2.RIGHT)).is_equal(Vector2(100, 0))


func test_diagonal_is_normalized() -> void:
	var p := _fresh()
	p.speed = 100.0
	var v := p.compute_velocity(Vector2(1, 1))
	assert_float(v.length()).is_equal_approx(100.0, 0.01)


func test_analog_partial_input_scales() -> void:
	var p := _fresh()
	p.speed = 100.0
	var v := p.compute_velocity(Vector2(0.5, 0))
	assert_float(v.length()).is_equal_approx(50.0, 0.01)


func test_zero_input_stops_but_keeps_facing() -> void:
	var p := _fresh()
	p.compute_velocity(Vector2.LEFT)
	assert_that(p.compute_velocity(Vector2.ZERO)).is_equal(Vector2.ZERO)
	assert_that(p.facing).is_equal(Vector2.LEFT)


func test_scene_instantiates() -> void:
	var node: TopdownPlayer = auto_free(PlayerScene.instantiate())
	add_child(node)
	assert_object(node.get_node("Sprite")).is_not_null()
	assert_object(node.get_node("Collision")).is_not_null()
