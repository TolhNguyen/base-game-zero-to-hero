class_name DialogueDef
extends Definition
## A conversation as data. Phase-3 scope: a linear sequence of lines.
## (Branching/conditions arrive when a real game needs them — P6.)

## Lines shown one at a time. Format "Speaker|Text" or just "Text".
@export var lines: PackedStringArray = []
