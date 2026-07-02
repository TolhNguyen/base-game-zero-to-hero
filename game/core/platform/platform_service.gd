class_name PlatformService
extends Node
## Base class for platform integrations. Gameplay code talks ONLY to the
## `Platform` autoload (an instance of a subclass of this) and never to a
## platform SDK directly. Steam (or any other store) plugs in by subclassing
## this and swapping the autoload — nothing above core may change.

## Achievement ids are stable IDs (P7), e.g. &"achievement.first_quest".
func unlock_achievement(id: StringName) -> void:
	push_warning("PlatformService.unlock_achievement not implemented (%s)" % id)


func is_achievement_unlocked(id: StringName) -> bool:
	return false


## Feature flags, e.g. &"cloud_saves", &"overlay", &"rich_presence".
func is_feature_available(_feature: StringName) -> bool:
	return false


func platform_name() -> String:
	return "abstract"
