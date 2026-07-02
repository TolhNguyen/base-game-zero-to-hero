class_name Definition
extends Resource
## Base class for all data definitions (items, scenes, quests, ...).
## The `id` is the stable identity (Constitution P7): every cross-reference
## in code, content, and save data uses this string, never a file path.
## Convention: dot-namespaced, e.g. &"item.healing_potion", &"scene.village".

@export var id: StringName = &""
