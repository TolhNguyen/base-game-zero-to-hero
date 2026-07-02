class_name CwCardDef
extends Definition
## A card is a military order. order_type selects the CwOrder handler.

@export var display_name: String = ""
@export var energy_cost: int = 1
@export var order_type: StringName = &""
