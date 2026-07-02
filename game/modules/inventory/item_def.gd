class_name ItemDef
extends Definition
## An item as data. Phase-3 scope: identity, display name, stacking.

@export var display_name: String = ""
## Maximum units per inventory (Phase-3 model: one stack per item id).
@export var max_stack: int = 99
