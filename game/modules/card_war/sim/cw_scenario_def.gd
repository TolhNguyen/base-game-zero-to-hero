class_name CwScenarioDef
extends Definition
## Scenario setup + all provisional balance values (design doc table).
## Numbers are data: tuning never requires code changes.

@export var map_id: StringName = &""
@export var turn_limit: int = 30
## card id (String) -> copies (int)
@export var deck: Dictionary = {}
@export var general_ids: PackedStringArray = PackedStringArray()

@export_group("Energy and hand")
@export var energy_start: int = 3
@export var energy_per_turn: int = 1
@export var energy_max: int = 10
@export var opening_hand: int = 5
@export var draw_per_turn: int = 2
@export var hand_max: int = 10

@export_group("Movement and camps")
@export var move_points_per_turn: int = 6
@export var march_hold_turns: int = 2
@export var troops_per_camp_tile: int = 2000

@export_group("Morale")
@export var morale_start: float = 80.0
@export var starve_morale_loss: float = 10.0
@export var victory_morale_gain: float = 20.0
@export var defeat_morale_loss: float = 20.0
@export var feast_morale_gain: float = 30.0

@export_group("Home city")
@export var home_troops: int = 5000
@export var home_food: int = 2000
@export var home_production_per_day: int = 40

@export_group("Enemy city")
@export var enemy_troops: int = 1000
@export var enemy_food: int = 500
@export var enemy_production_per_day: int = 40
@export var enemy_wall_factor: float = 1.5
