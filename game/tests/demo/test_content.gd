extends GdUnitTestSuite
## Content integrity: everything in res://content scans cleanly and the
## demo's expected stable IDs exist with valid targets.

const RegistryScript := preload("res://core/registry/registry.gd")


func test_content_scans_without_errors() -> void:
	var reg: Node = auto_free(RegistryScript.new())
	assert_int(reg.scan("res://content")).is_equal(OK)
	assert_int(reg.count()).is_equal(20)


func test_expected_ids_present() -> void:
	var reg: Node = auto_free(RegistryScript.new())
	reg.scan("res://content")
	for id in [&"item.apple", &"dialogue.npc_greeting", &"quest.collect_apples",
			&"scene.demo_room_a", &"scene.demo_room_b",
			&"card.march", &"card.gather_food", &"card.build_camp",
			&"card.transport", &"card.assault", &"card.feast",
			&"general.asun", &"terrain.plains", &"terrain.forest",
			&"terrain.river", &"terrain.mountain", &"terrain.city_home",
			&"terrain.city_enemy", &"map.tutorial_01", &"scenario.tutorial_01"]:
		assert_bool(reg.has_def(id)).override_failure_message("missing id: %s" % id).is_true()


func test_scene_defs_point_at_existing_scenes() -> void:
	var reg: Node = auto_free(RegistryScript.new())
	reg.scan("res://content")
	for id in [&"scene.demo_room_a", &"scene.demo_room_b"]:
		var def: SceneDef = reg.get_def(id)
		assert_bool(ResourceLoader.exists(def.scene_path))\
			.override_failure_message("missing scene file: %s" % def.scene_path).is_true()


func test_quest_topic_matches_demo_publisher() -> void:
	var reg: Node = auto_free(RegistryScript.new())
	reg.scan("res://content")
	var quest: QuestDef = reg.get_def(&"quest.collect_apples")
	# demo_state.collect_apple() publishes this exact topic
	assert_str(String(quest.completion_topic)).is_equal("demo.apple_collected")
