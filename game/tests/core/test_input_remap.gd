extends GdUnitTestSuite


func after_test() -> void:
	InputRemap.reset_to_defaults()


func _key(physical_keycode: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical_keycode as Key
	return ev


func test_default_actions_exist() -> void:
	for action in [&"move_up", &"move_down", &"move_left", &"move_right", &"interact", &"pause"]:
		assert_bool(InputMap.has_action(action)).is_true()


func test_rebind_replaces_events() -> void:
	assert_int(InputRemap.rebind(&"interact", _key(KEY_T))).is_equal(OK)
	var events := InputMap.action_get_events(&"interact")
	assert_int(events.size()).is_equal(1)
	assert_int((events[0] as InputEventKey).physical_keycode).is_equal(KEY_T)


func test_rebind_unknown_action_errors() -> void:
	assert_int(InputRemap.rebind(&"no_such_action", _key(KEY_T))).is_equal(ERR_DOES_NOT_EXIST)


func test_add_binding_keeps_existing() -> void:
	var before := InputMap.action_get_events(&"pause").size()
	InputRemap.add_binding(&"pause", _key(KEY_P))
	assert_int(InputMap.action_get_events(&"pause").size()).is_equal(before + 1)


func test_serialize_apply_round_trip() -> void:
	InputRemap.rebind(&"interact", _key(KEY_T))
	var snapshot := InputRemap.serialize()

	InputRemap.reset_to_defaults()
	var defaults := InputMap.action_get_events(&"interact")
	assert_int((defaults[0] as InputEventKey).physical_keycode).is_equal(KEY_E)

	InputRemap.apply(snapshot)
	var restored := InputMap.action_get_events(&"interact")
	assert_int(restored.size()).is_equal(1)
	assert_int((restored[0] as InputEventKey).physical_keycode).is_equal(KEY_T)


func test_gamepad_events_survive_round_trip() -> void:
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_RIGHT_SHOULDER
	InputRemap.rebind(&"interact", pad)
	var snapshot := InputRemap.serialize()
	InputRemap.reset_to_defaults()
	InputRemap.apply(snapshot)
	var events := InputMap.action_get_events(&"interact")
	assert_int((events[0] as InputEventJoypadButton).button_index)\
		.is_equal(JOY_BUTTON_RIGHT_SHOULDER)


func test_serialize_excludes_builtin_ui_actions() -> void:
	var snapshot := InputRemap.serialize()
	for key: String in snapshot.keys():
		assert_bool(key.begins_with("ui_")).is_false()
