extends GdUnitTestSuite

const SettingsScript := preload("res://core/settings/settings.gd")
const TEST_PATH := "user://test_settings.cfg"

var _master_db_before: float


func before_test() -> void:
	_master_db_before = AudioServer.get_bus_volume_db(0)


func after_test() -> void:
	AudioServer.set_bus_volume_db(0, _master_db_before)
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)


func _fresh() -> Node:
	var svc: Node = auto_free(SettingsScript.new())
	svc.config_path = TEST_PATH
	return svc


func test_defaults_when_unset() -> void:
	var svc: Node = _fresh()
	assert_that(svc.get_value("audio.master_volume", 1.0)).is_equal(1.0)
	assert_that(svc.get_value("anything.missing")).is_null()


func test_set_get_round_trip() -> void:
	var svc: Node = _fresh()
	svc.set_value("gameplay.difficulty", "hard")
	assert_that(svc.get_value("gameplay.difficulty")).is_equal("hard")


func test_persistence_across_instances() -> void:
	var first: Node = _fresh()
	first.set_value("video.window_mode", 2)
	var second: Node = _fresh()
	second.load_settings()
	assert_that(second.get_value("video.window_mode")).is_equal(2)


func test_audio_volume_applies_to_bus() -> void:
	var svc: Node = _fresh()
	svc.set_value("audio.master_volume", 0.5)
	assert_float(AudioServer.get_bus_volume_db(0)).is_equal_approx(linear_to_db(0.5), 0.01)


func test_reset_clears_values_and_file() -> void:
	var svc: Node = _fresh()
	svc.set_value("gameplay.difficulty", "hard")
	svc.reset()
	assert_that(svc.get_value("gameplay.difficulty")).is_null()
	assert_bool(FileAccess.file_exists(TEST_PATH)).is_false()
