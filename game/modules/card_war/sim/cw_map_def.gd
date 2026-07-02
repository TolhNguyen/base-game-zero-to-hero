class_name CwMapDef
extends Definition
## Grid layout as rows of terrain letters. City tiles use H (home) / E (enemy);
## both are passable city ground. Row 0 is the top of the map.

@export var rows: PackedStringArray = PackedStringArray()
