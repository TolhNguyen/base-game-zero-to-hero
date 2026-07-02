extends GdUnitTestSuite

const InteractableScript := preload("res://modules/interaction/interactable.gd")
const InteractorScript := preload("res://modules/interaction/interactor.gd")


func _make_interactable(id: StringName, pos: Vector2) -> Interactable:
	var node: Interactable = auto_free(InteractableScript.new())
	node.action_id = id
	node.global_position = pos
	return node


func test_interact_emits_signal_with_actor() -> void:
	var target := _make_interactable(&"npc.test", Vector2.ZERO)
	add_child(target)
	var got: Array = []
	target.interacted.connect(func(actor: Node) -> void: got.append(actor))
	var actor: Node = auto_free(Node.new())
	target.interact(actor)
	assert_int(got.size()).is_equal(1)
	assert_object(got[0]).is_same(actor)


func test_interact_publishes_event_topic() -> void:
	var target := _make_interactable(&"chest.test", Vector2.ZERO)
	add_child(target)
	var events: Array = []
	var bus := get_node("/root/EventBus")
	var cb := func(p: Dictionary) -> void: events.append(p)
	bus.subscribe(&"interaction.triggered", cb)
	target.interact(null)
	bus.unsubscribe(&"interaction.triggered", cb)
	assert_int(events.size()).is_equal(1)
	assert_str(String(events[0]["id"])).is_equal("chest.test")


func test_nearest_picks_closest_candidate() -> void:
	var actor: Interactor = auto_free(InteractorScript.new())
	add_child(actor)
	actor.global_position = Vector2.ZERO
	var far := _make_interactable(&"far", Vector2(100, 0))
	var near := _make_interactable(&"near", Vector2(10, 0))
	add_child(far)
	add_child(near)
	# Inject candidates directly: physics overlap needs frames, unit test does not.
	actor._candidates = [far, near] as Array[Interactable]
	assert_object(actor.nearest()).is_same(near)


func test_try_interact_with_nothing_is_safe_noop() -> void:
	var actor: Interactor = auto_free(InteractorScript.new())
	add_child(actor)
	assert_bool(actor.try_interact()).is_false()


func test_try_interact_triggers_nearest() -> void:
	var actor: Interactor = auto_free(InteractorScript.new())
	add_child(actor)
	actor.global_position = Vector2.ZERO
	var target := _make_interactable(&"npc.hit", Vector2(5, 0))
	add_child(target)
	actor._candidates = [target] as Array[Interactable]
	var hits := [0]
	target.interacted.connect(func(_a: Node) -> void: hits[0] += 1)
	assert_bool(actor.try_interact()).is_true()
	assert_int(hits[0]).is_equal(1)
