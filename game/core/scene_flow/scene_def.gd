class_name SceneDef
extends Definition
## Registry definition for a playable scene. Callers travel by stable ID
## (P7); only this resource knows the actual file path.

@export_file("*.tscn") var scene_path: String = ""
## Spawn point used when the caller does not specify one.
@export var default_spawn: StringName = &""
