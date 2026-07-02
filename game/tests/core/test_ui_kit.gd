extends GdUnitTestSuite

const PauseMenuScene := preload("res://core/ui_kit/pause_menu.tscn")
const SettingsMenuScene := preload("res://core/ui_kit/settings_menu.tscn")


func after_test() -> void:
	get_tree().paused = false


func test_focus_helper_grabs_first_focusable() -> void:
	var root := Control.new()
	add_child(auto_free(root))
	var label := Label.new()  # not focusable
	root.add_child(label)
	var button := Button.new()
	root.add_child(button)

	var focused := FocusHelper.grab_first(root)
	assert_object(focused).is_same(button)
	assert_bool(button.has_focus()).is_true()


func test_focus_helper_returns_null_when_nothing_focusable() -> void:
	var root := Control.new()
	add_child(auto_free(root))
	root.add_child(Label.new())
	assert_object(FocusHelper.grab_first(root)).is_null()


func test_pause_menu_open_pauses_tree_and_focuses() -> void:
	var menu: CanvasLayer = auto_free(PauseMenuScene.instantiate())
	add_child(menu)
	assert_bool(menu.visible).is_false()

	menu.open()
	assert_bool(menu.visible).is_true()
	assert_bool(get_tree().paused).is_true()

	menu.close()
	assert_bool(menu.visible).is_false()
	assert_bool(get_tree().paused).is_false()


func test_pause_menu_resume_emits_and_closes() -> void:
	var menu: CanvasLayer = auto_free(PauseMenuScene.instantiate())
	add_child(menu)
	var resumed := [false]
	menu.resume_requested.connect(func() -> void: resumed[0] = true)
	menu.open()
	menu._on_resume_pressed()
	assert_bool(resumed[0]).is_true()
	assert_bool(get_tree().paused).is_false()


func test_pause_menu_close_restores_prior_pause_state() -> void:
	var menu: CanvasLayer = auto_free(PauseMenuScene.instantiate())
	add_child(menu)
	get_tree().paused = true  # paused by something else (cutscene, modal, ...)
	menu.open()
	menu.close()
	assert_bool(get_tree().paused).is_true()


func test_pause_menu_freed_while_open_restores_pause_state() -> void:
	var menu: CanvasLayer = PauseMenuScene.instantiate()
	add_child(menu)
	menu.open()
	menu.free()
	assert_bool(get_tree().paused).is_false()


func test_settings_menu_instantiates_with_slider() -> void:
	var menu: Control = auto_free(SettingsMenuScene.instantiate())
	add_child(menu)
	var slider: HSlider = menu.get_node("%MasterVolume")
	assert_object(slider).is_not_null()
	assert_float(slider.max_value).is_equal(1.0)
