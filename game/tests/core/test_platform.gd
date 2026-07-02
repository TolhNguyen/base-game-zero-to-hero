extends GdUnitTestSuite

const StandaloneScript := preload("res://core/platform/standalone_platform.gd")


func _fresh() -> PlatformService:
	return auto_free(StandaloneScript.new())


func test_platform_name() -> void:
	assert_str(_fresh().platform_name()).is_equal("standalone")


func test_features_unavailable_on_standalone() -> void:
	var p := _fresh()
	assert_bool(p.is_feature_available(&"cloud_saves")).is_false()
	assert_bool(p.is_feature_available(&"overlay")).is_false()


func test_achievement_unlock_is_remembered() -> void:
	var p := _fresh()
	assert_bool(p.is_achievement_unlocked(&"achievement.test")).is_false()
	p.unlock_achievement(&"achievement.test")
	assert_bool(p.is_achievement_unlocked(&"achievement.test")).is_true()


func test_double_unlock_is_idempotent() -> void:
	var p := _fresh()
	p.unlock_achievement(&"achievement.test")
	p.unlock_achievement(&"achievement.test")
	assert_bool(p.is_achievement_unlocked(&"achievement.test")).is_true()
