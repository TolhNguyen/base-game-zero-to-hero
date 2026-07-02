# Card War Vertical Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A playable Tutorial Mission 1 of the card-war game: 16x16 map, 6 order cards, 1 general, food + morale simulation, win by capturing the enemy city.

**Architecture:** One module `game/modules/card_war/` with a pure-logic `sim/` layer (RefCounted classes, no scene tree, no autoloads, deterministic) and a thin `ui/` layer (programmatic UI, placeholder `_draw()` rendering). All data lives in `Definition` resources under `game/content/`. Spec: `docs/superpowers/specs/2026-07-02-card-war-vertical-slice-design.md`.

**Tech Stack:** Godot 4.7 (GL Compatibility), GDScript, gdUnit4 headless tests, `tools/check.sh` as the verification gate.

## Global Constraints

- Branch: all work commits to `game/Game_card` (owner-approved exception to the fork workflow).
- Governance: each task is wrapped in a contract `docs/contracts/TASK-2026-07-02-1NN.yaml` (template: `docs/governance/task-contract-template.md`) committed together with the work. `allowed_paths` per task are listed in the task.
- Never touch `game/core/**`, `tools/check*`, `tools/validate_*`, `.githooks/**`, `docs/governance/**` (Protected Core).
- Never `preload`/reference another module from `card_war` (P8; `tools/validate_deps.sh` fails the commit).
- `sim/` classes are `RefCounted`, take plain values, and never touch `Registry`, `EventBus`, or any autoload. Only `ui/` reads autoloads.
- All class names use the `Cw` prefix (global `class_name` namespace).
- GDScript warnings are errors here. Never `var x := call_returning_variant()` — always type the variable explicitly. Build typed arrays in a typed local before assigning.
- Indent GDScript with tabs (repo style).
- All balance numbers live in `CwScenarioDef` / content `.tres`, not in code. The locked food formula: `food per turn = ceili(troops / 100.0 * 3.0)` thạch (1 thạch feeds 100 troops 1 day; 1 turn = 3 days).
- Movement model: an army has 6 move points per turn; plains/city tiles cost 2, forest 3, river/mountain impassable (= 3 tiles/turn plains, 2 forest).
- After adding new `.gd`/`.tres` files run `bash tools/check.sh` (full, not `--fast`) once so Godot imports them, then `git add` the generated `*.uid` files with the commit.
- Verification per task: run the named test suite + `bash tools/check.sh --fast`; full `bash tools/check.sh` for tasks that add `.tres`/scenes. Quote `CHECK: PASS` in the commit body with the task id.
- Test suites live in `game/tests/card_war/`, `extends GdUnitTestSuite`, use `auto_free()` only for Nodes (sim classes are RefCounted).
- Single-suite run command (from repo root, Git Bash):

```bash
GODOT="$(ls tools/godot/Godot_v*.exe | grep -v console | head -1)"
"$GODOT" --headless --path game -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
  -a res://tests/card_war/<suite>.gd -c --ignoreHeadlessMode
```

## File Structure

```text
game/modules/card_war/
  sim/
    cw_card_def.gd       # CwCardDef extends Definition (schema)
    cw_general_def.gd    # CwGeneralDef extends Definition (schema)
    cw_terrain_def.gd    # CwTerrainDef extends Definition (schema)
    cw_map_def.gd        # CwMapDef extends Definition (schema)
    cw_scenario_def.gd   # CwScenarioDef extends Definition (schema + tuning)
    cw_tuning.gd         # CwTuning — plain tuning values, built from CwScenarioDef
    cw_map_grid.gd       # CwMapGrid — tiles, move costs, Dijkstra pathfinding
    cw_army.gd           # CwArmy
    cw_city.gd           # CwCity
    cw_camp.gd           # CwCamp
    cw_convoy.gd         # CwConvoy
    cw_order.gd          # CwOrder — one played card's parameters
    cw_state.gd          # CwState — full game state, deck/energy, play_card validation
    cw_combat.gd         # CwCombat — assault resolution (static)
    cw_resolver.gd       # CwResolver — end-of-turn resolution, 7 fixed phases
    cw_builder.gd        # CwBuilder — CwState from content Definitions (Task 9)
  ui/
    battle.tscn          # single Node2D root with battle.gd
    battle.gd            # builds CwState from Registry content, owns UI + order flow
    cw_map_view.gd       # Node2D: _draw() grid + entities, emits tile_clicked
game/content/
  cards/       card.march.tres card.gather_food.tres card.build_camp.tres
               card.transport.tres card.assault.tres card.feast.tres
  generals/    general.asun.tres
  terrains/    terrain.plains.tres terrain.forest.tres terrain.river.tres
               terrain.mountain.tres terrain.city_home.tres terrain.city_enemy.tres
  maps/        map.tutorial_01.tres
  scenarios/   scenario.tutorial_01.tres
  scenes/      card_war_battle.tres   # SceneDef -> battle.tscn (Task 10)
game/tests/card_war/
  test_defs.gd test_map_grid.gd test_state_deck.gd test_orders.gd
  test_march.gd test_supply_morale.gd test_combat.gd test_camp_convoy.gd
  test_playthrough.gd test_battle_scene.gd
docs/memory/domains/card_war.md   # domain doc (Task 12)
docs/memory/domains/registry.md   # + new id prefixes (Task 1)
```

Sim event records: every resolver mutation appends `{"t": StringName, ...fields}` to the returned events array. UI renders reports purely from these. Event types: `army_moved, army_arrived, army_returning, army_returned, army_disbanded, camp_built, camp_lost, convoy_arrived, food_gathered, feast_held, assault, starving, city_surrendered, victory, defeat, turn_ended`.

---

### Task 1: Definition schemas + id prefixes

**Files:**
- Create: `game/modules/card_war/sim/cw_card_def.gd`, `cw_general_def.gd`, `cw_terrain_def.gd`, `cw_map_def.gd`, `cw_scenario_def.gd`
- Create: `game/tests/card_war/test_defs.gd`
- Modify: `docs/memory/domains/registry.md` (register prefixes `card. general. terrain. map. scenario.`)

**Interfaces:**
- Produces (later tasks + content rely on these exact exports):
  - `CwCardDef`: `display_name: String`, `energy_cost: int`, `order_type: StringName` (one of `&"march" &"gather_food" &"build_camp" &"transport" &"assault" &"feast"`)
  - `CwGeneralDef`: `display_name: String`, `general_class: StringName`, `combat_factor: float`, `loss_reduction: float`
  - `CwTerrainDef`: `display_name: String`, `letter: String`, `move_cost: int` (0 = impassable)
  - `CwMapDef`: `rows: PackedStringArray` (16 strings of 16 chars; letters P F R M H E)
  - `CwScenarioDef`: see code below — all slice tuning values.

- [ ] **Step 1: Write the failing test**

`game/tests/card_war/test_defs.gd`:

```gdscript
extends GdUnitTestSuite

const CardDefScript := preload("res://modules/card_war/sim/cw_card_def.gd")
const ScenarioDefScript := preload("res://modules/card_war/sim/cw_scenario_def.gd")


func test_card_def_defaults() -> void:
	var def: CwCardDef = CardDefScript.new()
	def.id = &"card.test"
	def.energy_cost = 2
	def.order_type = &"march"
	assert_str(String(def.order_type)).is_equal("march")
	assert_bool(def is Definition).is_true()


func test_scenario_def_carries_tuning() -> void:
	var s: CwScenarioDef = ScenarioDefScript.new()
	assert_int(s.energy_start).is_equal(3)
	assert_int(s.move_points_per_turn).is_equal(6)
	assert_int(s.turn_limit).is_equal(30)
	assert_that(s.deck).is_equal({})
```

- [ ] **Step 2: Run test to verify it fails**

Run the single-suite command with `test_defs.gd`. Expected: FAIL / script load error (`cw_card_def.gd` missing).

- [ ] **Step 3: Write the five schema scripts**

`game/modules/card_war/sim/cw_card_def.gd`:

```gdscript
class_name CwCardDef
extends Definition
## A card is a military order. order_type selects the CwOrder handler.

@export var display_name: String = ""
@export var energy_cost: int = 1
@export var order_type: StringName = &""
```

`game/modules/card_war/sim/cw_general_def.gd`:

```gdscript
class_name CwGeneralDef
extends Definition
## A general. combat_factor multiplies attack power when leading;
## loss_reduction (0..1) reduces own combat losses (e.g. Asun 0.25).

@export var display_name: String = ""
@export var general_class: StringName = &"warrior"
@export var combat_factor: float = 1.0
@export var loss_reduction: float = 0.0
```

`game/modules/card_war/sim/cw_terrain_def.gd`:

```gdscript
class_name CwTerrainDef
extends Definition
## Terrain kind. letter is the map-row character; move_cost 0 = impassable.

@export var display_name: String = ""
@export var letter: String = "P"
@export var move_cost: int = 2
```

`game/modules/card_war/sim/cw_map_def.gd`:

```gdscript
class_name CwMapDef
extends Definition
## Grid layout as rows of terrain letters. City tiles use H (home) / E (enemy);
## both are passable city ground. Row 0 is the top of the map.

@export var rows: PackedStringArray = PackedStringArray()
```

`game/modules/card_war/sim/cw_scenario_def.gd`:

```gdscript
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
```

- [ ] **Step 4: Run test to verify it passes**

Single-suite command with `test_defs.gd`. Expected: PASS (2 test cases).

- [ ] **Step 5: Register the id prefixes**

In `docs/memory/domains/registry.md`, under **Invariants**, extend the namespace line example list with the card_war prefixes so the doc reads:

```text
- IDs are dot-namespaced: `item.x`, `scene.y`, `achievement.z`; card_war adds
  `card.*`, `general.*`, `terrain.*`, `map.*`, `scenario.*` (module card_war).
```

- [ ] **Step 6: Verify + commit**

```bash
bash tools/check.sh   # full: imports the new scripts, generates *.uid
git add game/modules/card_war game/tests/card_war docs/memory/domains/registry.md docs/contracts/TASK-2026-07-02-101.yaml
git commit -m "feat(card_war): definition schemas for cards, generals, terrain, map, scenario

TASK-2026-07-02-101. Evidence: CHECK: PASS (tools/check.sh)."
```

---

### Task 2: CwMapGrid — grid, costs, pathfinding

**Files:**
- Create: `game/modules/card_war/sim/cw_map_grid.gd`
- Test: `game/tests/card_war/test_map_grid.gd`

**Interfaces:**
- Consumes: nothing (plain values; `CwMapDef.rows` format only by convention).
- Produces:
  - `CwMapGrid.from_rows(rows: PackedStringArray, letter_cost: Dictionary) -> CwMapGrid` (static; `letter_cost` maps letter `String` -> `int` cost, 0 = impassable)
  - `size: Vector2i`, `letter_at(p: Vector2i) -> String`
  - `in_bounds(p: Vector2i) -> bool`, `move_cost(p: Vector2i) -> int`
  - `find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]` — cheapest 4-neighbour path, excludes `from`, includes `to`; `[]` if unreachable/invalid
  - `turns_for_path(path: Array[Vector2i], points_per_turn: int) -> int`
  - `tiles_with_letter(letter: String) -> Array[Vector2i]`

- [ ] **Step 1: Write the failing test**

`game/tests/card_war/test_map_grid.gd`:

```gdscript
extends GdUnitTestSuite

const GridScript := preload("res://modules/card_war/sim/cw_map_grid.gd")

const COSTS := {"P": 2, "F": 3, "R": 0, "M": 0, "H": 2, "E": 2}


func _grid(rows: PackedStringArray) -> CwMapGrid:
	return GridScript.from_rows(rows, COSTS)


func test_size_and_costs() -> void:
	var g: CwMapGrid = _grid(PackedStringArray(["PF", "RM"]))
	assert_that(g.size).is_equal(Vector2i(2, 2))
	assert_int(g.move_cost(Vector2i(0, 0))).is_equal(2)
	assert_int(g.move_cost(Vector2i(1, 0))).is_equal(3)
	assert_int(g.move_cost(Vector2i(0, 1))).is_equal(0)
	assert_bool(g.in_bounds(Vector2i(2, 0))).is_false()
	assert_str(g.letter_at(Vector2i(1, 1))).is_equal("M")


func test_path_straight_line() -> void:
	var g: CwMapGrid = _grid(PackedStringArray(["PPPP"]))
	var path: Array[Vector2i] = g.find_path(Vector2i(0, 0), Vector2i(3, 0))
	assert_that(path).is_equal([Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)])


func test_path_avoids_impassable_river() -> void:
	# P P P
	# R R P   -> must go around via x=2
	# P P P
	var g: CwMapGrid = _grid(PackedStringArray(["PPP", "RRP", "PPP"]))
	var path: Array[Vector2i] = g.find_path(Vector2i(0, 0), Vector2i(0, 2))
	assert_bool(path.size() > 0).is_true()
	for p: Vector2i in path:
		assert_int(g.move_cost(p)).is_not_equal(0)
	assert_that(path[path.size() - 1]).is_equal(Vector2i(0, 2))


func test_path_prefers_cheap_terrain() -> void:
	# Going through F costs 3, around through P costs 2 each.
	var g: CwMapGrid = _grid(PackedStringArray(["PFP", "PPP"]))
	var path: Array[Vector2i] = g.find_path(Vector2i(0, 0), Vector2i(2, 0))
	# cheap route: down, right, right, up = cost 8 vs through F = 5 -> F wins
	assert_that(path).is_equal([Vector2i(1, 0), Vector2i(2, 0)])


func test_unreachable_returns_empty() -> void:
	var g: CwMapGrid = _grid(PackedStringArray(["PMP"]))
	assert_that(g.find_path(Vector2i(0, 0), Vector2i(2, 0))).is_equal([] as Array[Vector2i])


func test_turns_for_path() -> void:
	var g: CwMapGrid = _grid(PackedStringArray(["PPPPPPPP"]))
	var path: Array[Vector2i] = g.find_path(Vector2i(0, 0), Vector2i(7, 0))
	# 7 tiles x cost 2 = 14 points, 6 points/turn -> 3 turns
	assert_int(g.turns_for_path(path, 6)).is_equal(3)


func test_tiles_with_letter() -> void:
	var g: CwMapGrid = _grid(PackedStringArray(["PH", "HP"]))
	var tiles: Array[Vector2i] = g.tiles_with_letter("H")
	assert_that(tiles).contains([Vector2i(1, 0), Vector2i(0, 1)])
```

- [ ] **Step 2: Run test to verify it fails**

Single-suite command with `test_map_grid.gd`. Expected: FAIL (script missing).

- [ ] **Step 3: Implement CwMapGrid**

`game/modules/card_war/sim/cw_map_grid.gd`:

```gdscript
class_name CwMapGrid
extends RefCounted
## 16x16 (or any) grid of terrain letters with move costs.
## Pure logic: no scene tree, no autoloads. Dijkstra over 4-neighbours.

var size: Vector2i = Vector2i.ZERO
var _letters: Array[String] = []
var _costs: Array[int] = []


static func from_rows(rows: PackedStringArray, letter_cost: Dictionary) -> CwMapGrid:
	var g := CwMapGrid.new()
	g.size = Vector2i(rows[0].length() if rows.size() > 0 else 0, rows.size())
	for row: String in rows:
		for i: int in row.length():
			var letter := row[i]
			g._letters.append(letter)
			g._costs.append(int(letter_cost.get(letter, 0)))
	return g


func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < size.x and p.y < size.y


func letter_at(p: Vector2i) -> String:
	return _letters[p.y * size.x + p.x] if in_bounds(p) else ""


func move_cost(p: Vector2i) -> int:
	return _costs[p.y * size.x + p.x] if in_bounds(p) else 0


func tiles_with_letter(letter: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in size.y:
		for x: int in size.x:
			if _letters[y * size.x + x] == letter:
				out.append(Vector2i(x, y))
	return out


## Cheapest path (Dijkstra). Excludes `from`, includes `to`. [] if unreachable.
func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if not in_bounds(from) or not in_bounds(to) or move_cost(to) == 0:
		return empty
	if from == to:
		return empty
	var dist := {from: 0}
	var prev := {}
	var frontier: Array[Vector2i] = [from]
	while not frontier.is_empty():
		var best_i := 0
		for i: int in frontier.size():
			if dist[frontier[i]] < dist[frontier[best_i]]:
				best_i = i
		var cur: Vector2i = frontier[best_i]
		frontier.remove_at(best_i)
		if cur == to:
			break
		for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var nxt: Vector2i = cur + d
			var c := move_cost(nxt)
			if c == 0:
				continue
			var nd: int = dist[cur] + c
			if not dist.has(nxt) or nd < dist[nxt]:
				dist[nxt] = nd
				prev[nxt] = cur
				if not frontier.has(nxt):
					frontier.append(nxt)
	if not prev.has(to):
		return empty
	var path: Array[Vector2i] = []
	var node: Vector2i = to
	while node != from:
		path.push_front(node)
		node = prev[node]
	return path


func turns_for_path(path: Array[Vector2i], points_per_turn: int) -> int:
	var turns := 0
	var points := 0
	for p: Vector2i in path:
		var c := move_cost(p)
		if points < c:
			turns += 1
			points = points_per_turn
		points -= c
	return turns
```

- [ ] **Step 4: Run test to verify it passes**

Single-suite command with `test_map_grid.gd`. Expected: PASS (7 test cases).

- [ ] **Step 5: Verify + commit**

```bash
bash tools/check.sh --fast
git add game/modules/card_war/sim/cw_map_grid.gd* game/tests/card_war/test_map_grid.gd* docs/contracts/TASK-2026-07-02-102.yaml
git commit -m "feat(card_war): map grid with terrain costs and Dijkstra pathfinding

TASK-2026-07-02-102. Evidence: CHECK: PASS (tools/check.sh --fast)."
```

---

### Task 3: Entities, tuning, CwState with deck and energy

**Files:**
- Create: `game/modules/card_war/sim/cw_tuning.gd`, `cw_army.gd`, `cw_city.gd`, `cw_camp.gd`, `cw_convoy.gd`, `cw_order.gd`, `cw_state.gd`
- Test: `game/tests/card_war/test_state_deck.gd`

**Interfaces:**
- Consumes: `CwMapGrid` (Task 2), `CwScenarioDef` (Task 1).
- Produces (exact members later tasks use):
  - `CwTuning` — mirrors every `CwScenarioDef` tuning export as a plain var; `static func from_def(def: CwScenarioDef) -> CwTuning`.
  - `CwArmy`: `id: int, general_id: StringName, general_combat_factor: float, general_loss_reduction: float, troops: int, morale: float, food: int, pos: Vector2i, state: StringName (&"marching"|&"holding"|&"returning"), path: Array[Vector2i], hold_left: int, home_city: StringName, assault_city: StringName, victory_cooldown: int, starving: bool, food_per_turn() -> int`
  - `CwCity`: `id: StringName, owner_side: StringName, tiles: Array[Vector2i], troops: int, food: int, production_per_day: int, morale: float, wall_factor: float, victory_cooldown: int, starving: bool, anchor() -> Vector2i, contains(p) -> bool, food_per_turn() -> int`
  - `CwCamp`: `id: int, pos: Vector2i, troops: int, food: int, morale: float, general_id: StringName, footprint_tiles: int, starving: bool, food_per_turn() -> int`
  - `CwConvoy`: `id: int, food: int, pos: Vector2i, path: Array[Vector2i], target_kind: StringName (&"camp"|&"army"), target_id: Variant`
  - `CwOrder`: `card_id: StringName, type: StringName, params: Dictionary`
  - `CwState`:
    - `turn: int, energy: int, result: StringName, map: CwMapGrid, tuning: CwTuning`
    - `deck/hand/discard: Array[StringName]`, `cities: Dictionary, armies: Dictionary, camps: Dictionary, convoys: Dictionary, pending: Array[CwOrder]`
    - `setup(map, tuning, seed_value: int)`, `register_card(id, order_type, cost)`, `register_general(id, combat_factor, loss_reduction)`, `add_city(id, owner_side, tiles, troops, food, production, wall) -> CwCity`
    - `set_deck(cards: Array[StringName])` (full copy list, shuffled with seeded rng, draws opening hand), `draw(n) -> Array[StringName]`
    - `has_card(id) -> bool`, `card_cost(id) -> int`, `card_type(id) -> StringName`, `has_general(id) -> bool`, `general_combat_factor(id) -> float`, `general_loss_reduction(id) -> float`
    - `next_id() -> int`, `army_at(p) -> CwArmy`, `camp_at(p) -> CwCamp`, `city_at(p) -> CwCity`
    - `is_general_busy(id) -> bool`, `set_general_busy(id, busy)`
    - `total_player_food() -> int`, `avg_player_morale() -> float`

- [ ] **Step 1: Write the failing test**

`game/tests/card_war/test_state_deck.gd`:

```gdscript
extends GdUnitTestSuite

const StateScript := preload("res://modules/card_war/sim/cw_state.gd")
const GridScript := preload("res://modules/card_war/sim/cw_map_grid.gd")
const TuningScript := preload("res://modules/card_war/sim/cw_tuning.gd")

const COSTS := {"P": 2, "F": 3, "R": 0, "M": 0, "H": 2, "E": 2}


func _state() -> CwState:
	var s: CwState = StateScript.new()
	var g: CwMapGrid = GridScript.from_rows(PackedStringArray(["HPPE", "PPPP"]), COSTS)
	var t: CwTuning = TuningScript.new()
	s.setup(g, t, 42)
	s.register_card(&"card.march", &"march", 2)
	s.register_card(&"card.gather_food", &"gather_food", 1)
	return s


func test_setup_defaults() -> void:
	var s: CwState = _state()
	assert_int(s.turn).is_equal(1)
	assert_int(s.energy).is_equal(3)
	assert_str(String(s.result)).is_equal("")


func test_deck_shuffle_is_seeded_and_opening_hand_drawn() -> void:
	var cards: Array[StringName] = []
	for i: int in 9:
		cards.append(&"card.march" if i % 2 == 0 else &"card.gather_food")
	var s1: CwState = _state()
	s1.set_deck(cards.duplicate())
	var s2: CwState = _state()
	s2.set_deck(cards.duplicate())
	assert_that(s1.hand).is_equal(s2.hand)  # same seed -> same order
	assert_int(s1.hand.size()).is_equal(5)  # opening_hand
	assert_int(s1.deck.size()).is_equal(4)


func test_draw_respects_hand_cap_and_reshuffles_discard() -> void:
	var cards: Array[StringName] = []
	for i: int in 6:
		cards.append(&"card.march")
	var s: CwState = _state()
	s.tuning.hand_max = 6
	s.set_deck(cards)
	assert_int(s.hand.size()).is_equal(5)
	s.discard.append(&"card.gather_food")
	var drawn: Array[StringName] = s.draw(3)
	# hand 5 -> cap 6: only 1 drawn even though deck+discard hold 2
	assert_int(drawn.size()).is_equal(1)
	assert_int(s.hand.size()).is_equal(6)
	s.hand.clear()
	var drawn2: Array[StringName] = s.draw(2)  # deck empty -> reshuffle discard
	assert_int(drawn2.size()).is_equal(2)


func test_city_and_lookups() -> void:
	var s: CwState = _state()
	var tiles: Array[Vector2i] = [Vector2i(0, 0)]
	var c: CwCity = s.add_city(&"city.home", &"player", tiles, 5000, 2000, 40, 1.0)
	assert_that(s.city_at(Vector2i(0, 0))).is_same(c)
	assert_that(c.anchor()).is_equal(Vector2i(0, 0))
	assert_int(c.food_per_turn()).is_equal(150)  # 5000/100*3
	assert_float(s.avg_player_morale()).is_equal_approx(80.0, 0.01)
	assert_int(s.total_player_food()).is_equal(2000)
```

- [ ] **Step 2: Run test to verify it fails**

Single-suite command with `test_state_deck.gd`. Expected: FAIL (scripts missing).

- [ ] **Step 3: Implement tuning, entities, order, state**

`game/modules/card_war/sim/cw_tuning.gd`:

```gdscript
class_name CwTuning
extends RefCounted
## Plain tuning values so the sim never touches Registry or Resources.
## Defaults mirror CwScenarioDef; from_def copies a scenario over them.

var turn_limit := 30
var energy_start := 3
var energy_per_turn := 1
var energy_max := 10
var opening_hand := 5
var draw_per_turn := 2
var hand_max := 10
var move_points_per_turn := 6
var march_hold_turns := 2
var troops_per_camp_tile := 2000
var morale_start := 80.0
var starve_morale_loss := 10.0
var victory_morale_gain := 20.0
var defeat_morale_loss := 20.0
var feast_morale_gain := 30.0


static func from_def(def: CwScenarioDef) -> CwTuning:
	var t := CwTuning.new()
	t.turn_limit = def.turn_limit
	t.energy_start = def.energy_start
	t.energy_per_turn = def.energy_per_turn
	t.energy_max = def.energy_max
	t.opening_hand = def.opening_hand
	t.draw_per_turn = def.draw_per_turn
	t.hand_max = def.hand_max
	t.move_points_per_turn = def.move_points_per_turn
	t.march_hold_turns = def.march_hold_turns
	t.troops_per_camp_tile = def.troops_per_camp_tile
	t.morale_start = def.morale_start
	t.starve_morale_loss = def.starve_morale_loss
	t.victory_morale_gain = def.victory_morale_gain
	t.defeat_morale_loss = def.defeat_morale_loss
	t.feast_morale_gain = def.feast_morale_gain
	return t
```

`game/modules/card_war/sim/cw_army.gd`:

```gdscript
class_name CwArmy
extends RefCounted
## A field army led by one general. Food is carried thach (spec 13.4).

var id := 0
var general_id: StringName = &""
var general_combat_factor := 1.0
var general_loss_reduction := 0.0
var troops := 0
var morale := 80.0
var food := 0
var pos := Vector2i.ZERO
var state: StringName = &"marching"  # marching | holding | returning
var path: Array[Vector2i] = []
var hold_left := 0
var home_city: StringName = &""
var assault_city: StringName = &""
var victory_cooldown := 0
var starving := false


## Locked formula: 1 thach feeds 100 troops 1 day; 1 turn = 3 days.
func food_per_turn() -> int:
	return ceili(troops / 100.0 * 3.0)
```

`game/modules/card_war/sim/cw_city.gd`:

```gdscript
class_name CwCity
extends RefCounted
## A city: multi-tile footprint, food store, production, garrison, morale.

var id: StringName = &""
var owner_side: StringName = &"player"  # player | enemy
var tiles: Array[Vector2i] = []
var troops := 0
var food := 0
var production_per_day := 0
var morale := 80.0
var wall_factor := 1.0
var victory_cooldown := 0
var starving := false


func anchor() -> Vector2i:
	return tiles[0] if tiles.size() > 0 else Vector2i.ZERO


func contains(p: Vector2i) -> bool:
	return tiles.has(p)


func food_per_turn() -> int:
	return ceili(troops / 100.0 * 3.0)
```

`game/modules/card_war/sim/cw_camp.gd`:

```gdscript
class_name CwCamp
extends RefCounted
## A camp: an army dug in. No production; footprint ~2000 troops/tile.

var id := 0
var pos := Vector2i.ZERO
var troops := 0
var food := 0
var morale := 80.0
var general_id: StringName = &""
var footprint_tiles := 1
var starving := false


func food_per_turn() -> int:
	return ceili(troops / 100.0 * 3.0)
```

`game/modules/card_war/sim/cw_convoy.gd`:

```gdscript
class_name CwConvoy
extends RefCounted
## A food convoy in transit. Abstracted: no escort/interception in the slice.

var id := 0
var food := 0
var pos := Vector2i.ZERO
var path: Array[Vector2i] = []
var target_kind: StringName = &"camp"  # camp | army
var target_id: Variant = null
```

`game/modules/card_war/sim/cw_order.gd`:

```gdscript
class_name CwOrder
extends RefCounted
## One played card, fully parameterized. params content by type:
##   march:       {general_id: StringName, troops: int, from_city: StringName, to: Vector2i}
##   gather_food: {city: StringName}
##   build_camp:  {army_id: int}
##   transport:   {from_city: StringName, food: int, target_kind: StringName, target_id: Variant}
##   assault:     {army_id: int, city: StringName}
##   feast:       {target_kind: StringName (&"army"|&"city"), target_id: Variant}

var card_id: StringName = &""
var type: StringName = &""
var params: Dictionary = {}
```

`game/modules/card_war/sim/cw_state.gd`:

```gdscript
class_name CwState
extends RefCounted
## Full sim state. Mutated only by play_card() (validated, atomic) and
## CwResolver.resolve(). Deterministic: seeded rng for deck shuffles.

var turn := 1
var energy := 0
var result: StringName = &""  # "" | victory | defeat
var map: CwMapGrid
var tuning: CwTuning

var deck: Array[StringName] = []
var hand: Array[StringName] = []
var discard: Array[StringName] = []

var cities := {}   # StringName -> CwCity
var armies := {}   # int -> CwArmy
var camps := {}    # int -> CwCamp
var convoys := {}  # int -> CwConvoy
var pending: Array[CwOrder] = []

var _cards := {}     # card id -> {"type": StringName, "cost": int}
var _generals := {}  # general id -> {"combat_factor": float, "loss_reduction": float}
var _busy := {}      # general id -> true
var _next_id := 1
var _rng := RandomNumberGenerator.new()


func setup(p_map: CwMapGrid, p_tuning: CwTuning, seed_value: int) -> void:
	map = p_map
	tuning = p_tuning
	energy = tuning.energy_start
	_rng.seed = seed_value


func register_card(id: StringName, order_type: StringName, cost: int) -> void:
	_cards[id] = {"type": order_type, "cost": cost}


func register_general(id: StringName, combat_factor: float, loss_reduction: float) -> void:
	_generals[id] = {"combat_factor": combat_factor, "loss_reduction": loss_reduction}


func has_card(id: StringName) -> bool:
	return _cards.has(id)


func card_cost(id: StringName) -> int:
	return int(_cards[id]["cost"]) if _cards.has(id) else 0


func card_type(id: StringName) -> StringName:
	return _cards[id]["type"] if _cards.has(id) else &""


func has_general(id: StringName) -> bool:
	return _generals.has(id)


func general_combat_factor(id: StringName) -> float:
	return float(_generals[id]["combat_factor"]) if _generals.has(id) else 1.0


func general_loss_reduction(id: StringName) -> float:
	return float(_generals[id]["loss_reduction"]) if _generals.has(id) else 0.0


func is_general_busy(id: StringName) -> bool:
	return _busy.get(id, false)


func set_general_busy(id: StringName, busy: bool) -> void:
	if busy:
		_busy[id] = true
	else:
		_busy.erase(id)


func add_city(id: StringName, owner_side: StringName, tiles: Array[Vector2i],
		troops: int, food: int, production: int, wall: float) -> CwCity:
	var c := CwCity.new()
	c.id = id
	c.owner_side = owner_side
	c.tiles = tiles
	c.troops = troops
	c.food = food
	c.production_per_day = production
	c.morale = tuning.morale_start
	c.wall_factor = wall
	cities[id] = c
	return c


## Takes the full card list (all copies), shuffles with the seeded rng,
## draws the opening hand.
func set_deck(cards: Array[StringName]) -> void:
	deck = cards.duplicate()
	_shuffle(deck)
	hand.clear()
	discard.clear()
	draw(tuning.opening_hand)


## Draws up to n cards (hand cap; reshuffles discard when the deck runs out).
func draw(n: int) -> Array[StringName]:
	var drawn: Array[StringName] = []
	for i: int in n:
		if hand.size() >= tuning.hand_max:
			break
		if deck.is_empty():
			if discard.is_empty():
				break
			deck = discard.duplicate()
			discard.clear()
			_shuffle(deck)
		var card: StringName = deck.pop_back()
		hand.append(card)
		drawn.append(card)
	return drawn


func next_id() -> int:
	_next_id += 1
	return _next_id - 1


func army_at(p: Vector2i) -> CwArmy:
	for a: CwArmy in armies.values():
		if a.pos == p:
			return a
	return null


func camp_at(p: Vector2i) -> CwCamp:
	for c: CwCamp in camps.values():
		if c.pos == p:
			return c
	return null


func city_at(p: Vector2i) -> CwCity:
	for c: CwCity in cities.values():
		if c.contains(p):
			return c
	return null


func total_player_food() -> int:
	var total := 0
	for c: CwCity in cities.values():
		if c.owner_side == &"player":
			total += c.food
	for camp: CwCamp in camps.values():
		total += camp.food
	for a: CwArmy in armies.values():
		total += a.food
	for v: CwConvoy in convoys.values():
		total += v.food
	return total


func avg_player_morale() -> float:
	var sum := 0.0
	var n := 0
	for c: CwCity in cities.values():
		if c.owner_side == &"player":
			sum += c.morale
			n += 1
	for camp: CwCamp in camps.values():
		sum += camp.morale
		n += 1
	for a: CwArmy in armies.values():
		sum += a.morale
		n += 1
	return sum / n if n > 0 else 0.0


func _shuffle(arr: Array[StringName]) -> void:
	for i: int in range(arr.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp: StringName = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
```

- [ ] **Step 4: Run test to verify it passes**

Single-suite command with `test_state_deck.gd`. Expected: PASS (4 test cases).

- [ ] **Step 5: Verify + commit**

```bash
bash tools/check.sh   # full: new scripts need import for *.uid
git add game/modules/card_war/sim game/tests/card_war/test_state_deck.gd* docs/contracts/TASK-2026-07-02-103.yaml
git commit -m "feat(card_war): sim entities, tuning, state with seeded deck and energy

TASK-2026-07-02-103. Evidence: CHECK: PASS (tools/check.sh)."
```

---

### Task 5: CwResolver — march lifecycle (start, move, hold, return)

**Files:**
- Create: `game/modules/card_war/sim/cw_resolver.gd`
- Modify: `game/modules/card_war/sim/cw_state.gd` (pending-reservation validation)
- Test: `game/tests/card_war/test_march.gd`

**Interfaces:**
- Consumes: `CwState.play_card/pending/armies/cities`, `CwArmy`, `CwMapGrid` (Tasks 2–4).
- Produces:
  - `CwResolver.resolve(s: CwState) -> Array[Dictionary]` (static) — runs the 7 fixed phases in order: start orders, movement, combat, production, consumption, morale, win/lose check; then (if no result) `turn += 1`, energy regen, draw. Phases combat/production/consumption/morale are implemented in Tasks 6–7 and are empty private funcs here.
  - March lifecycle: order → army spawned at city anchor (troops+food deducted, general busy) → moves `move_points_per_turn` per turn → arrival sets `state = &"holding"`, `hold_left = march_hold_turns` → countdown → `&"returning"` on reverse path → merge back into home city (troops + leftover food returned, general freed).
  - `CwState._pending_reserves(city_id: StringName) -> Dictionary` — `{"troops": int, "food": int, "generals": Array[StringName]}` summed over `pending`; march validation subtracts these so two orders in one turn cannot overdraw a city or double-book a general.
  - Full `_endcheck`: victory when no city has `owner_side == &"enemy"`; defeat when no player city, total player troops ≤ 0, or `turn >= tuning.turn_limit`. Sets `s.result`, appends `{"t": &"victory"}` / `{"t": &"defeat"}`.

- [ ] **Step 1: Write the failing test**

`game/tests/card_war/test_march.gd`:

```gdscript
extends GdUnitTestSuite

const StateScript := preload("res://modules/card_war/sim/cw_state.gd")
const GridScript := preload("res://modules/card_war/sim/cw_map_grid.gd")
const TuningScript := preload("res://modules/card_war/sim/cw_tuning.gd")
const OrderScript := preload("res://modules/card_war/sim/cw_order.gd")
const ResolverScript := preload("res://modules/card_war/sim/cw_resolver.gd")

const COSTS := {"P": 2, "F": 3, "R": 0, "M": 0, "H": 2, "E": 2}


func _state() -> CwState:
	var s: CwState = StateScript.new()
	var g: CwMapGrid = GridScript.from_rows(PackedStringArray(["HPPPPE"]), COSTS)
	s.setup(g, TuningScript.new(), 42)
	s.register_card(&"card.march", &"march", 2)
	s.register_general(&"general.asun", 1.0, 0.25)
	var home_tiles: Array[Vector2i] = [Vector2i(0, 0)]
	s.add_city(&"city.home", &"player", home_tiles, 5000, 2000, 40, 1.0)
	var enemy_tiles: Array[Vector2i] = [Vector2i(5, 0)]
	s.add_city(&"city.enemy", &"enemy", enemy_tiles, 1000, 500, 40, 1.5)
	var cards: Array[StringName] = []
	for i: int in 6:
		cards.append(&"card.march")
	s.set_deck(cards)
	s.energy = 10
	return s


func _play_march(s: CwState, troops: int, to: Vector2i) -> Error:
	var o: CwOrder = OrderScript.new()
	o.card_id = &"card.march"
	o.type = &"march"
	o.params = {"general_id": &"general.asun", "troops": troops,
			"from_city": &"city.home", "to": to}
	return s.play_card(o)


func test_full_march_lifecycle() -> void:
	var s: CwState = _state()
	assert_int(_play_march(s, 2000, Vector2i(4, 0))).is_equal(OK)
	var home: CwCity = s.cities[&"city.home"]

	# turn 1: order starts (deduct 2000 troops + 360 food), moves 3 tiles (6 pts)
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_int(home.troops).is_equal(3000)
	assert_int(home.food).is_equal(1640)  # 2000 - 360
	assert_int(s.armies.size()).is_equal(1)
	var a: CwArmy = s.armies.values()[0]
	assert_that(a.pos).is_equal(Vector2i(3, 0))
	assert_str(String(a.state)).is_equal("marching")
	assert_bool(s.is_general_busy(&"general.asun")).is_true()
	assert_int(s.turn).is_equal(2)

	# turn 2: arrives, holds
	ResolverScript.resolve(s)
	assert_that(a.pos).is_equal(Vector2i(4, 0))
	assert_str(String(a.state)).is_equal("holding")
	assert_int(a.hold_left).is_equal(2)

	# turns 3-4: hold countdown, then returning
	ResolverScript.resolve(s)
	assert_int(a.hold_left).is_equal(1)
	ResolverScript.resolve(s)
	assert_str(String(a.state)).is_equal("returning")

	# turns 5-6: march home, merge back
	ResolverScript.resolve(s)
	ResolverScript.resolve(s)
	assert_int(s.armies.size()).is_equal(0)
	assert_int(home.troops).is_equal(5000)
	assert_bool(s.is_general_busy(&"general.asun")).is_false()
	var types: Array = []
	for e: Dictionary in ev:
		types.append(e["t"])
	assert_that(types).contains([&"order_started", &"army_moved"])


func test_pending_reservations_block_overdraw() -> void:
	var s: CwState = _state()
	assert_int(_play_march(s, 3000, Vector2i(4, 0))).is_equal(OK)
	# same general double-booked -> rejected
	assert_int(_play_march(s, 1000, Vector2i(3, 0))).is_equal(ERR_INVALID_PARAMETER)
	s.register_general(&"general.b", 1.0, 0.0)
	# troops overdraw: 3000 reserved, only 2000 left
	var o: CwOrder = OrderScript.new()
	o.card_id = &"card.march"
	o.type = &"march"
	o.params = {"general_id": &"general.b", "troops": 2500,
			"from_city": &"city.home", "to": Vector2i(3, 0)}
	assert_int(s.play_card(o)).is_equal(ERR_INVALID_PARAMETER)


func test_no_result_before_turn_limit_and_defeat_on_limit() -> void:
	var s: CwState = _state()
	s.tuning.turn_limit = 3
	ResolverScript.resolve(s)
	assert_str(String(s.result)).is_equal("")
	ResolverScript.resolve(s)  # turn becomes 3 -> next resolve hits limit
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_str(String(s.result)).is_equal("defeat")
	var types: Array = []
	for e: Dictionary in ev:
		types.append(e["t"])
	assert_that(types).contains([&"defeat"])


func test_resolve_after_result_is_noop() -> void:
	var s: CwState = _state()
	s.result = &"victory"
	var before: int = s.turn
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_int(ev.size()).is_equal(0)
	assert_int(s.turn).is_equal(before)
```

- [ ] **Step 2: Run test to verify it fails**

Single-suite command with `test_march.gd`. Expected: FAIL (`cw_resolver.gd` missing).

- [ ] **Step 3: Implement CwResolver + pending reservations**

`game/modules/card_war/sim/cw_resolver.gd`:

```gdscript
class_name CwResolver
extends RefCounted
## End-of-turn resolution. Seven fixed phases (design doc, in this order):
## 1 start orders, 2 movement, 3 combat, 4 production, 5 consumption,
## 6 morale, 7 win/lose. Then turn++, energy regen, card draw.
## All mutations append an event record {"t": StringName, ...} for the UI.

static func resolve(s: CwState) -> Array[Dictionary]:
	var ev: Array[Dictionary] = []
	if s.result != &"":
		return ev
	_start_orders(s, ev)
	_movement(s, ev)
	_combat(s, ev)
	_production(s, ev)
	_consumption(s, ev)
	_morale(s, ev)
	_endcheck(s, ev)
	if s.result == &"":
		s.turn += 1
		s.energy = mini(s.energy + s.tuning.energy_per_turn, s.tuning.energy_max)
		s.draw(s.tuning.draw_per_turn)
	ev.append({"t": &"turn_ended", "turn": s.turn})
	return ev


# --- Phase 1: start orders -----------------------------------------------------

static func _start_orders(s: CwState, ev: Array[Dictionary]) -> void:
	for o: CwOrder in s.pending:
		match o.type:
			&"march":
				_start_march(s, o, ev)
			# gather_food / feast: Task 7. build_camp / transport: Task 8.
	s.pending.clear()


static func _start_march(s: CwState, o: CwOrder, ev: Array[Dictionary]) -> void:
	var city: CwCity = s.cities[o.params["from_city"]]
	var troops := int(o.params["troops"])
	var path: Array[Vector2i] = s.map.find_path(s.spawn_tile(city), o.params["to"])
	var food := s.march_food_needed(troops, path)
	city.troops -= troops
	city.food -= food
	var a := CwArmy.new()
	a.id = s.next_id()
	a.general_id = o.params["general_id"]
	a.general_combat_factor = s.general_combat_factor(a.general_id)
	a.general_loss_reduction = s.general_loss_reduction(a.general_id)
	a.troops = troops
	a.morale = s.tuning.morale_start
	a.food = food
	a.pos = s.spawn_tile(city)
	a.state = &"marching"
	a.path = path
	a.hold_left = s.tuning.march_hold_turns
	a.home_city = city.id
	s.armies[a.id] = a
	s.set_general_busy(a.general_id, true)
	ev.append({"t": &"order_started", "type": &"march", "army": a.id})


# --- Phase 2: movement -----------------------------------------------------------

static func _movement(s: CwState, ev: Array[Dictionary]) -> void:
	for a: CwArmy in s.armies.values().duplicate():
		match a.state:
			&"marching", &"returning":
				_move_army(s, a, ev)
			&"holding":
				if a.assault_city == &"":
					a.hold_left -= 1
					if a.hold_left <= 0:
						_begin_return(s, a, ev)
	# Convoy movement: Task 8.


static func _move_army(s: CwState, a: CwArmy, ev: Array[Dictionary]) -> void:
	var points := s.tuning.move_points_per_turn
	while not a.path.is_empty():
		var cost := s.map.move_cost(a.path[0])
		if cost > points:
			break
		points -= cost
		a.pos = a.path.pop_front()
	ev.append({"t": &"army_moved", "id": a.id, "pos": a.pos})
	if not a.path.is_empty():
		return
	if a.state == &"marching":
		a.state = &"holding"
		a.hold_left = s.tuning.march_hold_turns
		ev.append({"t": &"army_arrived", "id": a.id, "pos": a.pos})
	else:  # returning
		_merge_home(s, a, ev)


static func _begin_return(s: CwState, a: CwArmy, ev: Array[Dictionary]) -> void:
	var city: CwCity = s.cities.get(a.home_city)
	if city == null:
		return
	if a.pos == s.spawn_tile(city):
		_merge_home(s, a, ev)
		return
	var path: Array[Vector2i] = s.map.find_path(a.pos, s.spawn_tile(city))
	if path.is_empty():
		a.hold_left = 1  # blocked: keep holding, try again next turn
		return
	a.state = &"returning"
	a.path = path
	ev.append({"t": &"army_returning", "id": a.id})


static func _merge_home(s: CwState, a: CwArmy, ev: Array[Dictionary]) -> void:
	var city: CwCity = s.cities.get(a.home_city)
	if city != null:
		city.troops += a.troops
		city.food += a.food
	s.set_general_busy(a.general_id, false)
	s.armies.erase(a.id)
	ev.append({"t": &"army_returned", "id": a.id})


# --- Phases 3-6: implemented in Tasks 6-7 ---------------------------------------

static func _combat(_s: CwState, _ev: Array[Dictionary]) -> void:
	pass  # Task 7


static func _production(_s: CwState, _ev: Array[Dictionary]) -> void:
	pass  # Task 6


static func _consumption(_s: CwState, _ev: Array[Dictionary]) -> void:
	pass  # Task 6


static func _morale(_s: CwState, _ev: Array[Dictionary]) -> void:
	pass  # Task 6


# --- Phase 7: win/lose -----------------------------------------------------------

static func _endcheck(s: CwState, ev: Array[Dictionary]) -> void:
	var enemy_left := false
	var player_city := false
	for c: CwCity in s.cities.values():
		if c.owner_side == &"enemy":
			enemy_left = true
		else:
			player_city = true
	if not enemy_left:
		s.result = &"victory"
		ev.append({"t": &"victory"})
		return
	var troops := 0
	for c: CwCity in s.cities.values():
		if c.owner_side == &"player":
			troops += c.troops
	for a: CwArmy in s.armies.values():
		troops += a.troops
	for camp: CwCamp in s.camps.values():
		troops += camp.troops
	if not player_city or troops <= 0 or s.turn >= s.tuning.turn_limit:
		s.result = &"defeat"
		ev.append({"t": &"defeat"})
```

In `game/modules/card_war/sim/cw_state.gd`, add the reservation helper and use it in `_validate_march` (replace the troops/food/busy checks):

```gdscript
## Troops/food/generals already committed by not-yet-resolved orders.
func _pending_reserves(city_id: StringName) -> Dictionary:
	var out := {"troops": 0, "food": 0, "generals": []}
	for o: CwOrder in pending:
		if o.type == &"march" and o.params.get("from_city") == city_id:
			out["troops"] += int(o.params["troops"])
			var city: CwCity = cities[city_id]
			var path: Array[Vector2i] = map.find_path(spawn_tile(city), o.params["to"])
			out["food"] += march_food_needed(int(o.params["troops"]), path)
		if o.type == &"transport" and o.params.get("from_city") == city_id:
			out["food"] += int(o.params["food"])
		if o.type == &"march":
			out["generals"].append(o.params.get("general_id"))
	return out
```

And in `_validate_march`, after resolving `city`:

```gdscript
	var reserved: Dictionary = _pending_reserves(from_id)
	var gid: StringName = p.get("general_id", &"")
	if not _generals.has(gid) or is_general_busy(gid) \
			or (reserved["generals"] as Array).has(gid):
		return ERR_INVALID_PARAMETER
	var troops := int(p.get("troops", 0))
	if troops < 1 or troops > city.troops - int(reserved["troops"]):
		return ERR_INVALID_PARAMETER
```

and the food check becomes:

```gdscript
	if march_food_needed(troops, path) > city.food - int(reserved["food"]):
		return ERR_INVALID_PARAMETER
```

Also add the same reservation subtraction to `_validate_transport`'s amount check:

```gdscript
	var reserved: Dictionary = _pending_reserves(from_id)
	if amount < 1 or amount > city.food - int(reserved["food"]):
		return ERR_INVALID_PARAMETER
```

- [ ] **Step 4: Run tests to verify they pass**

Single-suite command with `test_march.gd`, then with `test_orders.gd` (must still pass after the validation change). Expected: PASS both.

- [ ] **Step 5: Verify + commit**

```bash
bash tools/check.sh
git add game/modules/card_war/sim game/tests/card_war/test_march.gd* docs/contracts/TASK-2026-07-02-105.yaml
git commit -m "feat(card_war): turn resolver with multi-turn march lifecycle

TASK-2026-07-02-105. Evidence: CHECK: PASS (tools/check.sh)."
```

---

### Task 6: Supply and morale phases (production, consumption, starvation, collapse)

**Files:**
- Modify: `game/modules/card_war/sim/cw_resolver.gd` (fill `_production`, `_consumption`, `_morale`)
- Test: `game/tests/card_war/test_supply_morale.gd`

**Interfaces:**
- Consumes: Task 5 resolver skeleton, entities from Task 3.
- Produces (rules later tasks + UI rely on):
  - `_production`: every city (both sides) gains `production_per_day * 3` food.
  - `_consumption`: every city/camp/army pays `food_per_turn()` from its local stock/carry. If short: stock goes to 0 and `starving = true`, else `starving = false`. Starving emits `{"t": &"starving", "kind": &"city"|&"camp"|&"army", "id": ...}`.
  - `_morale`: each starving entity loses `tuning.starve_morale_loss` morale (floor 0). At morale 0: army disbands (`{"t": &"army_disbanded"}`, general freed, removed), camp is lost (`{"t": &"camp_lost"}`, general freed, removed), city surrenders — `owner_side` flips to the other side (`{"t": &"city_surrendered", "id", "to"}`).

- [ ] **Step 1: Write the failing test**

`game/tests/card_war/test_supply_morale.gd`:

```gdscript
extends GdUnitTestSuite

const StateScript := preload("res://modules/card_war/sim/cw_state.gd")
const GridScript := preload("res://modules/card_war/sim/cw_map_grid.gd")
const TuningScript := preload("res://modules/card_war/sim/cw_tuning.gd")
const ResolverScript := preload("res://modules/card_war/sim/cw_resolver.gd")
const ArmyScript := preload("res://modules/card_war/sim/cw_army.gd")
const CampScript := preload("res://modules/card_war/sim/cw_camp.gd")

const COSTS := {"P": 2, "F": 3, "R": 0, "M": 0, "H": 2, "E": 2}


func _state() -> CwState:
	var s: CwState = StateScript.new()
	var g: CwMapGrid = GridScript.from_rows(PackedStringArray(["HPPPPE"]), COSTS)
	s.setup(g, TuningScript.new(), 42)
	var home_tiles: Array[Vector2i] = [Vector2i(0, 0)]
	s.add_city(&"city.home", &"player", home_tiles, 1000, 500, 40, 1.0)
	var enemy_tiles: Array[Vector2i] = [Vector2i(5, 0)]
	s.add_city(&"city.enemy", &"enemy", enemy_tiles, 1000, 500, 40, 1.5)
	return s


func test_city_production_and_consumption() -> void:
	var s: CwState = _state()
	var home: CwCity = s.cities[&"city.home"]
	ResolverScript.resolve(s)
	# +40*3 production, -1000/100*3 consumption = 500 + 120 - 30 = 590
	assert_int(home.food).is_equal(590)
	assert_bool(home.starving).is_false()
	assert_float(home.morale).is_equal_approx(80.0, 0.01)


func test_starving_city_loses_morale_and_surrenders() -> void:
	var s: CwState = _state()
	var home: CwCity = s.cities[&"city.home"]
	home.food = 0
	home.production_per_day = 0
	home.morale = 25.0
	ResolverScript.resolve(s)
	assert_bool(home.starving).is_true()
	assert_float(home.morale).is_equal_approx(15.0, 0.01)
	ResolverScript.resolve(s)
	assert_float(home.morale).is_equal_approx(5.0, 0.01)
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_str(String(home.owner_side)).is_equal("enemy")
	var types: Array = []
	for e: Dictionary in ev:
		types.append(e["t"])
	assert_that(types).contains([&"starving", &"city_surrendered"])
	# no player city left -> defeat
	assert_str(String(s.result)).is_equal("defeat")


func test_starving_army_decays_and_disbands() -> void:
	var s: CwState = _state()
	var a: CwArmy = ArmyScript.new()
	a.id = s.next_id()
	a.general_id = &"general.asun"
	a.troops = 2000
	a.morale = 15.0
	a.food = 0
	a.pos = Vector2i(2, 0)
	a.state = &"holding"
	a.hold_left = 99
	a.home_city = &"city.home"
	s.armies[a.id] = a
	s.set_general_busy(&"general.asun", true)
	ResolverScript.resolve(s)
	assert_float(a.morale).is_equal_approx(5.0, 0.01)
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_int(s.armies.size()).is_equal(0)
	assert_bool(s.is_general_busy(&"general.asun")).is_false()
	var types: Array = []
	for e: Dictionary in ev:
		types.append(e["t"])
	assert_that(types).contains([&"army_disbanded"])


func test_army_consumes_carried_food() -> void:
	var s: CwState = _state()
	var a: CwArmy = ArmyScript.new()
	a.id = s.next_id()
	a.troops = 2000  # 60/turn
	a.food = 100
	a.pos = Vector2i(2, 0)
	a.state = &"holding"
	a.hold_left = 99
	s.armies[a.id] = a
	ResolverScript.resolve(s)
	assert_int(a.food).is_equal(40)
	assert_bool(a.starving).is_false()
	ResolverScript.resolve(s)
	assert_int(a.food).is_equal(0)
	assert_bool(a.starving).is_true()


func test_camp_consumes_and_collapses() -> void:
	var s: CwState = _state()
	var c: CwCamp = CampScript.new()
	c.id = s.next_id()
	c.pos = Vector2i(3, 0)
	c.troops = 2000
	c.food = 0
	c.morale = 5.0
	c.general_id = &"general.x"
	s.camps[c.id] = c
	s.set_general_busy(&"general.x", true)
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_int(s.camps.size()).is_equal(0)
	assert_bool(s.is_general_busy(&"general.x")).is_false()
	var types: Array = []
	for e: Dictionary in ev:
		types.append(e["t"])
	assert_that(types).contains([&"camp_lost"])
```

- [ ] **Step 2: Run test to verify it fails**

Single-suite command with `test_supply_morale.gd`. Expected: FAIL (production/consumption/morale are no-ops).

- [ ] **Step 3: Fill the three phases in cw_resolver.gd**

Replace the three `pass  # Task 6` stubs:

```gdscript
static func _production(s: CwState, _ev: Array[Dictionary]) -> void:
	for c: CwCity in s.cities.values():
		c.food += c.production_per_day * 3


static func _consumption(s: CwState, ev: Array[Dictionary]) -> void:
	for c: CwCity in s.cities.values():
		c.starving = _consume(c, ev, &"city", c.id)
	for camp: CwCamp in s.camps.values():
		camp.starving = _consume(camp, ev, &"camp", camp.id)
	for a: CwArmy in s.armies.values():
		a.starving = _consume(a, ev, &"army", a.id)


## entity must expose food: int and food_per_turn() -> int. Returns starving.
static func _consume(entity: RefCounted, ev: Array[Dictionary],
		kind: StringName, id: Variant) -> bool:
	var need := int(entity.call("food_per_turn"))
	var stock := int(entity.get("food"))
	if stock >= need:
		entity.set("food", stock - need)
		return false
	entity.set("food", 0)
	ev.append({"t": &"starving", "kind": kind, "id": id})
	return true


static func _morale(s: CwState, ev: Array[Dictionary]) -> void:
	for c: CwCity in s.cities.values():
		if c.starving:
			c.morale = maxf(0.0, c.morale - s.tuning.starve_morale_loss)
		if c.morale <= 0.0:
			var to: StringName = &"enemy" if c.owner_side == &"player" else &"player"
			c.owner_side = to
			c.morale = s.tuning.morale_start
			c.starving = false
			ev.append({"t": &"city_surrendered", "id": c.id, "to": to})
	for camp: CwCamp in s.camps.values().duplicate():
		if camp.starving:
			camp.morale = maxf(0.0, camp.morale - s.tuning.starve_morale_loss)
		if camp.morale <= 0.0:
			s.set_general_busy(camp.general_id, false)
			s.camps.erase(camp.id)
			ev.append({"t": &"camp_lost", "id": camp.id})
	for a: CwArmy in s.armies.values().duplicate():
		if a.starving:
			a.morale = maxf(0.0, a.morale - s.tuning.starve_morale_loss)
		if a.morale <= 0.0:
			s.set_general_busy(a.general_id, false)
			s.armies.erase(a.id)
			ev.append({"t": &"army_disbanded", "id": a.id})
```

- [ ] **Step 4: Run tests to verify they pass**

Single-suite with `test_supply_morale.gd`, then `test_march.gd` (lifecycle numbers unchanged: army food covers the trip exactly — verify no regression). Expected: PASS both.

Note: `test_march.gd::test_full_march_lifecycle` asserts `home.food == 1640` right after turn 1 — production/consumption now change city food each turn. Update that one assertion in the same commit: after turn 1 home food = `2000 - 360 (march) + 120 (production) - 90 (3000 garrison)` = `1670`. This is the only test line this task may touch.

- [ ] **Step 5: Verify + commit**

```bash
bash tools/check.sh --fast
git add game/modules/card_war/sim/cw_resolver.gd game/tests/card_war docs/contracts/TASK-2026-07-02-106.yaml
git commit -m "feat(card_war): food production/consumption and morale collapse

TASK-2026-07-02-106. Evidence: CHECK: PASS (tools/check.sh --fast)."
```

---

### Task 7: Assault combat, gather food, victory feast

**Files:**
- Create: `game/modules/card_war/sim/cw_combat.gd`
- Modify: `game/modules/card_war/sim/cw_resolver.gd` (fill `_combat`; add `gather_food` + `feast` to `_start_orders`)
- Test: `game/tests/card_war/test_combat.gd`

**Interfaces:**
- Consumes: resolver from Tasks 5–6; `CwArmy.assault_city`, `victory_cooldown` (Task 3); validation from Task 4.
- Produces:
  - `CwCombat.assault(army: CwArmy, city: CwCity) -> Dictionary` (static, pure — mutates nothing): returns `{"won": bool, "captured": bool, "att_losses": int, "def_losses": int}` using the provisional formula:
    - `att_power = troops * (morale/100) * general_combat_factor`
    - `def_power = troops * (morale/100) * wall_factor`
    - `ratio = att_power / def_power`; `def_power <= 0` → captured outright.
    - ratio ≥ 1: won; `def_losses = def_troops * clampf(0.3 * ratio, 0.3, 1.0)`; `att_losses = att_troops * clampf(0.2 / ratio, 0.05, 0.2) * (1 - loss_reduction)`.
    - ratio < 1: lost; `att_losses = att_troops * clampf(0.25 / maxf(ratio, 0.1), 0.25, 0.5) * (1 - loss_reduction)`; `def_losses = def_troops * 0.1 * ratio`.
  - Resolver `_combat`: decrements all `victory_cooldown`s, then resolves every army with `assault_city != &""` (clears it): applies losses; winner gains `victory_morale_gain` (cap 100), loser drops `defeat_morale_loss` (floor 0); captured when won and (city troops ≤ 0 or city morale ≤ 0) → `owner_side = &"player"`, `troops = 0`, city+army `victory_cooldown = 2`; army `hold_left` resets to `march_hold_turns`. Event `{"t": &"assault", "army", "city", "att_losses", "def_losses", "captured"}`.
  - `_start_orders` gains: `gather_food` → `city.food += production_per_day * 3`, event `{"t": &"food_gathered", "city", "amount"}`; `feast` → target (+`feast_morale_gain` cap 100), pays `ceili(troops/100.0)` food from its own stock/carry, `victory_cooldown = 0`, event `{"t": &"feast_held", "kind", "id"}`.

- [ ] **Step 1: Write the failing test**

`game/tests/card_war/test_combat.gd`:

```gdscript
extends GdUnitTestSuite

const StateScript := preload("res://modules/card_war/sim/cw_state.gd")
const GridScript := preload("res://modules/card_war/sim/cw_map_grid.gd")
const TuningScript := preload("res://modules/card_war/sim/cw_tuning.gd")
const OrderScript := preload("res://modules/card_war/sim/cw_order.gd")
const ResolverScript := preload("res://modules/card_war/sim/cw_resolver.gd")
const ArmyScript := preload("res://modules/card_war/sim/cw_army.gd")
const CityScript := preload("res://modules/card_war/sim/cw_city.gd")
const CombatScript := preload("res://modules/card_war/sim/cw_combat.gd")

const COSTS := {"P": 2, "F": 3, "R": 0, "M": 0, "H": 2, "E": 2}


func _army(troops: int, morale: float, loss_reduction: float) -> CwArmy:
	var a: CwArmy = ArmyScript.new()
	a.troops = troops
	a.morale = morale
	a.general_combat_factor = 1.0
	a.general_loss_reduction = loss_reduction
	return a


func _city(troops: int, morale: float, wall: float) -> CwCity:
	var c: CwCity = CityScript.new()
	c.troops = troops
	c.morale = morale
	c.wall_factor = wall
	c.owner_side = &"enemy"
	return c


func test_assault_formula_strong_attacker() -> void:
	# 4000@80 vs 1000@80 wall 1.5: ratio 2.667
	var r: Dictionary = CombatScript.assault(_army(4000, 80.0, 0.25), _city(1000, 80.0, 1.5))
	assert_bool(r["won"]).is_true()
	assert_int(r["def_losses"]).is_equal(800)   # 1000 * 0.3*2.667 = 0.8
	assert_int(r["att_losses"]).is_equal(225)   # 4000 * 0.075 * 0.75
	assert_bool(r["captured"]).is_false()       # troops remain; resolver decides


func test_assault_formula_weak_attacker() -> void:
	# 500@80 vs 1000@80 wall 1.5: ratio 0.333
	var r: Dictionary = CombatScript.assault(_army(500, 80.0, 0.0), _city(1000, 80.0, 1.5))
	assert_bool(r["won"]).is_false()
	assert_int(r["att_losses"]).is_equal(250)   # 500 * clamp(0.75,.25,.5)=0.5
	assert_int(r["def_losses"]).is_equal(33)    # 1000 * 0.1 * 0.333


func test_asun_loss_reduction_applies() -> void:
	var with_asun: Dictionary = CombatScript.assault(_army(4000, 80.0, 0.25), _city(1000, 80.0, 1.5))
	var without: Dictionary = CombatScript.assault(_army(4000, 80.0, 0.0), _city(1000, 80.0, 1.5))
	assert_int(int(with_asun["att_losses"])).is_less(int(without["att_losses"]))


func _battle_state() -> CwState:
	var s: CwState = StateScript.new()
	var g: CwMapGrid = GridScript.from_rows(PackedStringArray(["HPPPPE"]), COSTS)
	s.setup(g, TuningScript.new(), 42)
	s.register_card(&"card.assault", &"assault", 3)
	s.register_card(&"card.gather_food", &"gather_food", 1)
	s.register_card(&"card.feast", &"feast", 1)
	s.register_general(&"general.asun", 1.0, 0.25)
	var home_tiles: Array[Vector2i] = [Vector2i(0, 0)]
	s.add_city(&"city.home", &"player", home_tiles, 1000, 2000, 40, 1.0)
	var enemy_tiles: Array[Vector2i] = [Vector2i(5, 0)]
	s.add_city(&"city.enemy", &"enemy", enemy_tiles, 1000, 500, 40, 1.5)
	var a: CwArmy = ArmyScript.new()
	a.id = s.next_id()
	a.general_id = &"general.asun"
	a.general_combat_factor = 1.0
	a.general_loss_reduction = 0.25
	a.troops = 4000
	a.morale = 80.0
	a.food = 2000
	a.pos = Vector2i(4, 0)  # adjacent to enemy city
	a.state = &"holding"
	a.hold_left = 2
	a.home_city = &"city.home"
	s.armies[a.id] = a
	s.set_general_busy(&"general.asun", true)
	var cards: Array[StringName] = [&"card.assault", &"card.assault",
			&"card.gather_food", &"card.feast", &"card.feast", &"card.assault"]
	s.set_deck(cards)
	# The seeded shuffle decides which 5 land in hand; tests need exact cards,
	# so stuff the hand deterministically (play_card only checks hand membership).
	var forced_hand: Array[StringName] = [&"card.assault", &"card.assault",
			&"card.gather_food", &"card.feast", &"card.feast"]
	s.hand = forced_hand
	s.energy = 10
	return s


func _play(s: CwState, card: StringName, type: StringName, params: Dictionary) -> Error:
	var o: CwOrder = OrderScript.new()
	o.card_id = card
	o.type = type
	o.params = params
	return s.play_card(o)


func test_two_assaults_capture_city_then_victory() -> void:
	var s: CwState = _battle_state()
	var a: CwArmy = s.armies.values()[0]
	var enemy: CwCity = s.cities[&"city.enemy"]

	assert_int(_play(s, &"card.assault", &"assault",
			{"army_id": a.id, "city": &"city.enemy"})).is_equal(OK)
	ResolverScript.resolve(s)
	assert_int(enemy.troops).is_equal(200)  # 1000 - 800
	assert_str(String(enemy.owner_side)).is_equal("enemy")
	assert_float(a.morale).is_equal_approx(100.0, 0.01)  # +20 win, capped
	assert_int(a.hold_left).is_equal(2)  # re-engaged, not returning

	assert_int(_play(s, &"card.assault", &"assault",
			{"army_id": a.id, "city": &"city.enemy"})).is_equal(OK)
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_str(String(enemy.owner_side)).is_equal("player")
	assert_int(a.victory_cooldown).is_equal(2)
	assert_str(String(s.result)).is_equal("victory")
	var types: Array = []
	for e: Dictionary in ev:
		types.append(e["t"])
	assert_that(types).contains([&"assault", &"victory"])


func test_gather_food_adds_three_days_production() -> void:
	var s: CwState = _battle_state()
	var home: CwCity = s.cities[&"city.home"]
	assert_int(_play(s, &"card.gather_food", &"gather_food",
			{"city": &"city.home"})).is_equal(OK)
	ResolverScript.resolve(s)
	# 2000 + 120 gather + 120 production - 30 consumption = 2210
	assert_int(home.food).is_equal(2210)


func test_feast_needs_recent_victory_and_costs_food() -> void:
	var s: CwState = _battle_state()
	var a: CwArmy = s.armies.values()[0]
	# no victory yet -> rejected
	assert_int(_play(s, &"card.feast", &"feast",
			{"target_kind": &"army", "target_id": a.id})).is_equal(ERR_INVALID_PARAMETER)
	a.victory_cooldown = 2
	a.morale = 60.0
	var food_before: int = a.food
	assert_int(_play(s, &"card.feast", &"feast",
			{"target_kind": &"army", "target_id": a.id})).is_equal(OK)
	ResolverScript.resolve(s)
	assert_float(a.morale).is_equal_approx(90.0, 0.01)  # 60 + 30
	# cost 4000/100 = 40, then turn consumption 120
	assert_int(a.food).is_equal(food_before - 40 - 120)
	assert_int(a.victory_cooldown).is_equal(0)
```

- [ ] **Step 2: Run test to verify it fails**

Single-suite command with `test_combat.gd`. Expected: FAIL (`cw_combat.gd` missing).

- [ ] **Step 3: Implement CwCombat and wire the resolver**

`game/modules/card_war/sim/cw_combat.gd`:

```gdscript
class_name CwCombat
extends RefCounted
## Provisional assault formula (design doc "Combat"). Pure: mutates nothing.
## power = troops x (morale/100) x factor; victory margin sets both losses.

static func assault(army: CwArmy, city: CwCity) -> Dictionary:
	var out := {"won": false, "captured": false, "att_losses": 0, "def_losses": 0}
	var def_power := city.troops * (city.morale / 100.0) * city.wall_factor
	if def_power <= 0.0:
		out["won"] = true
		out["captured"] = true
		return out
	var att_power := army.troops * (army.morale / 100.0) * army.general_combat_factor
	var ratio := att_power / def_power
	if ratio >= 1.0:
		out["won"] = true
		out["def_losses"] = int(city.troops * clampf(0.3 * ratio, 0.3, 1.0))
		out["att_losses"] = int(army.troops * clampf(0.2 / ratio, 0.05, 0.2) \
				* (1.0 - army.general_loss_reduction))
	else:
		out["att_losses"] = int(army.troops * clampf(0.25 / maxf(ratio, 0.1), 0.25, 0.5) \
				* (1.0 - army.general_loss_reduction))
		out["def_losses"] = int(city.troops * 0.1 * ratio)
	return out
```

In `cw_resolver.gd`, replace the `_combat` stub:

```gdscript
static func _combat(s: CwState, ev: Array[Dictionary]) -> void:
	for a: CwArmy in s.armies.values():
		if a.victory_cooldown > 0:
			a.victory_cooldown -= 1
	for c: CwCity in s.cities.values():
		if c.victory_cooldown > 0:
			c.victory_cooldown -= 1
	for a: CwArmy in s.armies.values().duplicate():
		if a.assault_city == &"":
			continue
		var city: CwCity = s.cities.get(a.assault_city)
		a.assault_city = &""
		if city == null or city.owner_side != &"enemy":
			continue
		var r: Dictionary = CwCombat.assault(a, city)
		a.troops = maxi(0, a.troops - int(r["att_losses"]))
		city.troops = maxi(0, city.troops - int(r["def_losses"]))
		var captured: bool = bool(r["captured"])
		if bool(r["won"]):
			a.morale = minf(100.0, a.morale + s.tuning.victory_morale_gain)
			city.morale = maxf(0.0, city.morale - s.tuning.defeat_morale_loss)
			if city.troops <= 0 or city.morale <= 0.0:
				captured = true
		else:
			a.morale = maxf(0.0, a.morale - s.tuning.defeat_morale_loss)
		if captured:
			city.owner_side = &"player"
			city.troops = 0
			city.morale = s.tuning.morale_start
			city.victory_cooldown = 2
			a.victory_cooldown = 2
		a.hold_left = s.tuning.march_hold_turns
		ev.append({"t": &"assault", "army": a.id, "city": city.id,
				"att_losses": r["att_losses"], "def_losses": r["def_losses"],
				"captured": captured})
		if a.troops <= 0:
			s.set_general_busy(a.general_id, false)
			s.armies.erase(a.id)
			ev.append({"t": &"army_disbanded", "id": a.id})
```

In `_start_orders`, extend the `match`:

```gdscript
			&"gather_food":
				var city: CwCity = s.cities[o.params["city"]]
				var amount := city.production_per_day * 3
				city.food += amount
				ev.append({"t": &"food_gathered", "city": city.id, "amount": amount})
			&"assault":
				var a: CwArmy = s.armies.get(int(o.params["army_id"]))
				if a != null:
					a.assault_city = o.params["city"]
			&"feast":
				_start_feast(s, o, ev)
```

And add:

```gdscript
static func _start_feast(s: CwState, o: CwOrder, ev: Array[Dictionary]) -> void:
	match o.params.get("target_kind", &""):
		&"army":
			var a: CwArmy = s.armies.get(int(o.params["target_id"]))
			if a == null:
				return
			a.food = maxi(0, a.food - ceili(a.troops / 100.0))
			a.morale = minf(100.0, a.morale + s.tuning.feast_morale_gain)
			a.victory_cooldown = 0
			ev.append({"t": &"feast_held", "kind": &"army", "id": a.id})
		&"city":
			var c: CwCity = s.cities.get(o.params["target_id"])
			if c == null:
				return
			c.food = maxi(0, c.food - ceili(c.troops / 100.0))
			c.morale = minf(100.0, c.morale + s.tuning.feast_morale_gain)
			c.victory_cooldown = 0
			ev.append({"t": &"feast_held", "kind": &"city", "id": c.id})
```

- [ ] **Step 4: Run tests to verify they pass**

Single-suite with `test_combat.gd`, then re-run `test_march.gd`, `test_supply_morale.gd`, `test_orders.gd`. Expected: PASS all.

- [ ] **Step 5: Verify + commit**

```bash
bash tools/check.sh
git add game/modules/card_war/sim game/tests/card_war/test_combat.gd* docs/contracts/TASK-2026-07-02-107.yaml
git commit -m "feat(card_war): assault combat, gather food and victory feast orders

TASK-2026-07-02-107. Evidence: CHECK: PASS (tools/check.sh)."
```

---

### Task 8: Build camp and food convoys

**Files:**
- Modify: `game/modules/card_war/sim/cw_resolver.gd` (`build_camp` + `transport` in `_start_orders`; convoys in `_movement`)
- Test: `game/tests/card_war/test_camp_convoy.gd`

**Interfaces:**
- Consumes: `CwCamp`, `CwConvoy` (Task 3), resolver (Tasks 5–7), validation (Task 4).
- Produces:
  - `build_camp` order: the army (any state except returning) becomes a `CwCamp` at its position — troops/food/morale/general carried over, `footprint_tiles = ceili(troops / float(tuning.troops_per_camp_tile))`, army removed (general stays busy — the camp is an ongoing assignment). Event `{"t": &"camp_built", "id", "pos", "footprint"}`. Cancels the return plan by construction (army no longer exists).
  - `transport` order: deducts food from the source city at start; creates a `CwConvoy` with path from city anchor to the target's position at start time. Convoys move `move_points_per_turn` per turn in `_movement`; on arrival deliver into the target's `food` if it still exists (`{"t": &"convoy_arrived", "id", "delivered": true}`), else the food is lost (`"delivered": false`). Convoys consume nothing (abstraction, documented).

- [ ] **Step 1: Write the failing test**

`game/tests/card_war/test_camp_convoy.gd`:

```gdscript
extends GdUnitTestSuite

const StateScript := preload("res://modules/card_war/sim/cw_state.gd")
const GridScript := preload("res://modules/card_war/sim/cw_map_grid.gd")
const TuningScript := preload("res://modules/card_war/sim/cw_tuning.gd")
const OrderScript := preload("res://modules/card_war/sim/cw_order.gd")
const ResolverScript := preload("res://modules/card_war/sim/cw_resolver.gd")
const ArmyScript := preload("res://modules/card_war/sim/cw_army.gd")

const COSTS := {"P": 2, "F": 3, "R": 0, "M": 0, "H": 2, "E": 2}


func _state() -> CwState:
	var s: CwState = StateScript.new()
	var g: CwMapGrid = GridScript.from_rows(PackedStringArray(["HPPPPPPP"]), COSTS)
	s.setup(g, TuningScript.new(), 42)
	s.register_card(&"card.build_camp", &"build_camp", 1)
	s.register_card(&"card.transport", &"transport", 1)
	var home_tiles: Array[Vector2i] = [Vector2i(0, 0)]
	s.add_city(&"city.home", &"player", home_tiles, 3000, 2000, 40, 1.0)
	var a: CwArmy = ArmyScript.new()
	a.id = s.next_id()
	a.general_id = &"general.asun"
	a.troops = 4000
	a.morale = 75.0
	a.food = 300
	a.pos = Vector2i(6, 0)
	a.state = &"holding"
	a.hold_left = 1  # would start returning this turn without the camp order
	a.home_city = &"city.home"
	s.armies[a.id] = a
	s.set_general_busy(&"general.asun", true)
	var cards: Array[StringName] = [&"card.build_camp", &"card.transport",
			&"card.transport", &"card.build_camp"]
	s.set_deck(cards)
	s.energy = 10
	return s


func _play(s: CwState, card: StringName, type: StringName, params: Dictionary) -> Error:
	var o: CwOrder = OrderScript.new()
	o.card_id = card
	o.type = type
	o.params = params
	return s.play_card(o)


func test_build_camp_converts_army_and_cancels_return() -> void:
	var s: CwState = _state()
	var a: CwArmy = s.armies.values()[0]
	assert_int(_play(s, &"card.build_camp", &"build_camp",
			{"army_id": a.id})).is_equal(OK)
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_int(s.armies.size()).is_equal(0)
	assert_int(s.camps.size()).is_equal(1)
	var camp: CwCamp = s.camps.values()[0]
	assert_that(camp.pos).is_equal(Vector2i(6, 0))
	assert_int(camp.troops).is_equal(4000)
	assert_int(camp.footprint_tiles).is_equal(2)  # 4000 / 2000
	# food: 300 carried in, minus 120 consumption this turn
	assert_int(camp.food).is_equal(180)
	assert_bool(s.is_general_busy(&"general.asun")).is_true()
	var types: Array = []
	for e: Dictionary in ev:
		types.append(e["t"])
	assert_that(types).contains([&"camp_built"])


func test_convoy_delivers_to_camp() -> void:
	var s: CwState = _state()
	var a: CwArmy = s.armies.values()[0]
	_play(s, &"card.build_camp", &"build_camp", {"army_id": a.id})
	ResolverScript.resolve(s)
	var camp: CwCamp = s.camps.values()[0]
	var home: CwCity = s.cities[&"city.home"]
	var home_food: int = home.food

	assert_int(_play(s, &"card.transport", &"transport",
			{"from_city": &"city.home", "food": 600,
			"target_kind": &"camp", "target_id": camp.id})).is_equal(OK)
	ResolverScript.resolve(s)
	assert_int(home.food).is_equal(home_food - 600 + 120 - 90)  # -600, +prod, -cons
	assert_int(s.convoys.size()).is_equal(1)  # 6 tiles away: 2 turns
	var camp_food: int = camp.food
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_int(s.convoys.size()).is_equal(0)
	# delivered 600, then camp consumed 120
	assert_int(camp.food).is_equal(camp_food + 600 - 120)
	var types: Array = []
	for e: Dictionary in ev:
		types.append(e["t"])
	assert_that(types).contains([&"convoy_arrived"])


func test_convoy_to_dead_target_loses_food() -> void:
	var s: CwState = _state()
	var a: CwArmy = s.armies.values()[0]
	_play(s, &"card.build_camp", &"build_camp", {"army_id": a.id})
	ResolverScript.resolve(s)
	var camp: CwCamp = s.camps.values()[0]
	_play(s, &"card.transport", &"transport",
			{"from_city": &"city.home", "food": 600,
			"target_kind": &"camp", "target_id": camp.id})
	ResolverScript.resolve(s)
	s.camps.erase(camp.id)  # camp dies while convoy is en route
	var ev: Array[Dictionary] = ResolverScript.resolve(s)
	assert_int(s.convoys.size()).is_equal(0)
	var delivered := true
	for e: Dictionary in ev:
		if e["t"] == &"convoy_arrived":
			delivered = bool(e["delivered"])
	assert_bool(delivered).is_false()
```

- [ ] **Step 2: Run test to verify it fails**

Single-suite command with `test_camp_convoy.gd`. Expected: FAIL (orders ignored, no camp created).

- [ ] **Step 3: Implement camp + convoy handling in cw_resolver.gd**

Extend the `_start_orders` match:

```gdscript
			&"build_camp":
				_start_build_camp(s, o, ev)
			&"transport":
				_start_transport(s, o, ev)
```

Add the handlers:

```gdscript
static func _start_build_camp(s: CwState, o: CwOrder, ev: Array[Dictionary]) -> void:
	var a: CwArmy = s.armies.get(int(o.params["army_id"]))
	if a == null or a.state == &"returning":
		return
	var camp := CwCamp.new()
	camp.id = s.next_id()
	camp.pos = a.pos
	camp.troops = a.troops
	camp.food = a.food
	camp.morale = a.morale
	camp.general_id = a.general_id
	camp.footprint_tiles = ceili(a.troops / float(s.tuning.troops_per_camp_tile))
	s.camps[camp.id] = camp
	s.armies.erase(a.id)  # general stays busy: the camp is an ongoing assignment
	ev.append({"t": &"camp_built", "id": camp.id, "pos": camp.pos,
			"footprint": camp.footprint_tiles})


static func _start_transport(s: CwState, o: CwOrder, ev: Array[Dictionary]) -> void:
	var city: CwCity = s.cities[o.params["from_city"]]
	var amount := int(o.params["food"])
	var target_pos := Vector2i.ZERO
	match o.params["target_kind"]:
		&"camp":
			var camp: CwCamp = s.camps.get(int(o.params["target_id"]))
			if camp == null:
				return
			target_pos = camp.pos
		&"army":
			var a: CwArmy = s.armies.get(int(o.params["target_id"]))
			if a == null:
				return
			target_pos = a.pos
	city.food -= amount
	var v := CwConvoy.new()
	v.id = s.next_id()
	v.food = amount
	v.pos = s.spawn_tile(city)
	v.path = s.map.find_path(v.pos, target_pos)
	v.target_kind = o.params["target_kind"]
	v.target_id = o.params["target_id"]
	s.convoys[v.id] = v
	ev.append({"t": &"order_started", "type": &"transport", "convoy": v.id})
```

In `_movement`, after the army loop, add convoy movement:

```gdscript
	for v: CwConvoy in s.convoys.values().duplicate():
		var points := s.tuning.move_points_per_turn
		while not v.path.is_empty():
			var cost := s.map.move_cost(v.path[0])
			if cost > points:
				break
			points -= cost
			v.pos = v.path.pop_front()
		if v.path.is_empty():
			_deliver_convoy(s, v, ev)
```

Add:

```gdscript
static func _deliver_convoy(s: CwState, v: CwConvoy, ev: Array[Dictionary]) -> void:
	var delivered := false
	match v.target_kind:
		&"camp":
			var camp: CwCamp = s.camps.get(int(v.target_id))
			if camp != null:
				camp.food += v.food
				delivered = true
		&"army":
			var a: CwArmy = s.armies.get(int(v.target_id))
			if a != null:
				a.food += v.food
				delivered = true
	s.convoys.erase(v.id)
	ev.append({"t": &"convoy_arrived", "id": v.id, "delivered": delivered})
```

- [ ] **Step 4: Run tests to verify they pass**

Single-suite with `test_camp_convoy.gd`, then the four earlier card_war suites. Expected: PASS all.

- [ ] **Step 5: Verify + commit**

```bash
bash tools/check.sh --fast
git add game/modules/card_war/sim/cw_resolver.gd game/tests/card_war/test_camp_convoy.gd* docs/contracts/TASK-2026-07-02-108.yaml
git commit -m "feat(card_war): build camp and food convoy orders

TASK-2026-07-02-108. Evidence: CHECK: PASS (tools/check.sh --fast)."
```

---

### Task 9: Content definitions, state builder, scripted playthrough

**Files:**
- Create: `game/modules/card_war/sim/cw_builder.gd`
- Create: `game/content/cards/card.march.tres`, `card.gather_food.tres`, `card.build_camp.tres`, `card.transport.tres`, `card.assault.tres`, `card.feast.tres`
- Create: `game/content/generals/general.asun.tres`
- Create: `game/content/terrains/terrain.plains.tres`, `terrain.forest.tres`, `terrain.river.tres`, `terrain.mountain.tres`, `terrain.city_home.tres`, `terrain.city_enemy.tres`
- Create: `game/content/maps/map.tutorial_01.tres`
- Create: `game/content/scenarios/scenario.tutorial_01.tres`
- Modify: `game/tests/demo/test_content.gd` (expected count 5 → 20; add expected ids)
- Test: `game/tests/card_war/test_playthrough.gd`

**Interfaces:**
- Consumes: all sim classes (Tasks 1–8).
- Produces:
  - `CwBuilder.build(scenario: CwScenarioDef, map_def: CwMapDef, terrains: Array[CwTerrainDef], cards: Array[CwCardDef], generals: Array[CwGeneralDef], seed_value: int) -> CwState` (static): grid from `map_def.rows` + terrain letter costs; home city from `H` tiles / enemy city from `E` tiles with scenario stats; registers all cards and generals; deck = `scenario.deck` dictionary expanded (`card id -> copies`); calls `setup` + `set_deck`.
  - The 15 content `.tres` files with the ids `card.march`, `card.gather_food`, `card.build_camp`, `card.transport`, `card.assault`, `card.feast`, `general.asun`, `terrain.plains`, `terrain.forest`, `terrain.river`, `terrain.mountain`, `terrain.city_home`, `terrain.city_enemy`, `map.tutorial_01`, `scenario.tutorial_01`.

- [ ] **Step 1: Write the failing test**

`game/tests/card_war/test_playthrough.gd`:

```gdscript
extends GdUnitTestSuite
## Integration: builds the real tutorial scenario from res://content and
## plays a scripted winning line. Hand is stuffed explicitly before each
## play so the seeded shuffle can never starve the script of cards.

const BuilderScript := preload("res://modules/card_war/sim/cw_builder.gd")
const OrderScript := preload("res://modules/card_war/sim/cw_order.gd")
const ResolverScript := preload("res://modules/card_war/sim/cw_resolver.gd")


func _build() -> CwState:
	var scenario: CwScenarioDef = load("res://content/scenarios/scenario.tutorial_01.tres")
	# scenario.map_id stays a pure id; the game resolves it via Registry,
	# this test resolves the path itself to stay autoload-free.
	var map_def: CwMapDef = load("res://content/maps/map.tutorial_01.tres")
	var terrains: Array[CwTerrainDef] = []
	for f: String in ["plains", "forest", "river", "mountain", "city_home", "city_enemy"]:
		terrains.append(load("res://content/terrains/terrain.%s.tres" % f))
	var cards: Array[CwCardDef] = []
	for f: String in ["march", "gather_food", "build_camp", "transport", "assault", "feast"]:
		cards.append(load("res://content/cards/card.%s.tres" % f))
	var generals: Array[CwGeneralDef] = []
	generals.append(load("res://content/generals/general.asun.tres"))
	return BuilderScript.build(scenario, map_def, terrains, cards, generals, 42)


func _force_hand(s: CwState, card: StringName) -> void:
	if not s.hand.has(card):
		s.hand.append(card)


func _play(s: CwState, card: StringName, type: StringName, params: Dictionary) -> Error:
	_force_hand(s, card)
	var o: CwOrder = OrderScript.new()
	o.card_id = card
	o.type = type
	o.params = params
	return s.play_card(o)


func test_builder_wires_scenario() -> void:
	var s: CwState = _build()
	assert_that(s.map.size).is_equal(Vector2i(16, 16))
	assert_int(s.cities.size()).is_equal(2)
	var home: CwCity = s.cities[&"city.home"]
	assert_int(home.troops).is_equal(5000)
	assert_int(home.food).is_equal(2000)
	assert_int(home.tiles.size()).is_equal(4)   # 2x2 H block
	assert_that(home.anchor()).is_equal(Vector2i(7, 13))
	var enemy: CwCity = s.cities[&"city.enemy"]
	assert_int(enemy.troops).is_equal(1000)
	assert_that(enemy.tiles).is_equal([Vector2i(8, 2)] as Array[Vector2i])
	assert_int(s.deck.size() + s.hand.size()).is_equal(18)  # 3 copies x 6 cards
	assert_int(s.hand.size()).is_equal(5)
	assert_int(s.energy).is_equal(3)
	assert_bool(s.has_general(&"general.asun")).is_true()


func test_scripted_win_in_seven_turns() -> void:
	var s: CwState = _build()
	var home: CwCity = s.cities[&"city.home"]
	var enemy: CwCity = s.cities[&"city.enemy"]

	# Turn 1: march 4000 under Asun to (8,3), the tile south of the enemy city.
	assert_int(_play(s, &"card.march", &"march",
			{"general_id": &"general.asun", "troops": 4000,
			"from_city": &"city.home", "to": Vector2i(8, 3)})).is_equal(OK)
	ResolverScript.resolve(s)
	assert_int(s.armies.size()).is_equal(1)
	var a: CwArmy = s.armies.values()[0]
	assert_int(home.troops).is_equal(1000)

	# Turns 2-5: the army covers the 26-point path (5 turns total).
	for i: int in 4:
		ResolverScript.resolve(s)
	assert_that(a.pos).is_equal(Vector2i(8, 3))
	assert_str(String(a.state)).is_equal("holding")
	assert_int(s.turn).is_equal(6)

	# Turn 6: first assault cracks the garrison (1000 -> 200).
	assert_int(_play(s, &"card.assault", &"assault",
			{"army_id": a.id, "city": &"city.enemy"})).is_equal(OK)
	ResolverScript.resolve(s)
	assert_int(enemy.troops).is_equal(200)
	assert_str(String(enemy.owner_side)).is_equal("enemy")

	# Turn 7: second assault captures the city -> victory.
	assert_int(_play(s, &"card.assault", &"assault",
			{"army_id": a.id, "city": &"city.enemy"})).is_equal(OK)
	ResolverScript.resolve(s)
	assert_str(String(enemy.owner_side)).is_equal("player")
	assert_str(String(s.result)).is_equal("victory")
	assert_int(s.turn).is_equal(7)
	# Food ledger: 2000 - 1440 march budget + 7 x (120 prod - 30 garrison) = 1190
	assert_int(home.food).is_equal(1190)
```

- [ ] **Step 2: Run test to verify it fails**

Single-suite command with `test_playthrough.gd`. Expected: FAIL (builder + content missing).

- [ ] **Step 3: Implement the builder**

`game/modules/card_war/sim/cw_builder.gd`:

```gdscript
class_name CwBuilder
extends RefCounted
## Builds a ready CwState from content Definitions. The only sim-side code
## that touches Resources; it still never touches Registry or autoloads —
## callers (ui, tests) fetch the defs and pass them in.

static func build(scenario: CwScenarioDef, map_def: CwMapDef,
		terrains: Array[CwTerrainDef], cards: Array[CwCardDef],
		generals: Array[CwGeneralDef], seed_value: int) -> CwState:
	var letter_cost := {}
	for t: CwTerrainDef in terrains:
		letter_cost[t.letter] = t.move_cost
	var grid := CwMapGrid.from_rows(map_def.rows, letter_cost)
	var s := CwState.new()
	s.setup(grid, CwTuning.from_def(scenario), seed_value)
	for c: CwCardDef in cards:
		s.register_card(c.id, c.order_type, c.energy_cost)
	for g: CwGeneralDef in generals:
		s.register_general(g.id, g.combat_factor, g.loss_reduction)
	s.add_city(&"city.home", &"player", grid.tiles_with_letter("H"),
			scenario.home_troops, scenario.home_food,
			scenario.home_production_per_day, 1.0)
	s.add_city(&"city.enemy", &"enemy", grid.tiles_with_letter("E"),
			scenario.enemy_troops, scenario.enemy_food,
			scenario.enemy_production_per_day, scenario.enemy_wall_factor)
	var deck: Array[StringName] = []
	for card_id: Variant in scenario.deck:
		for i: int in int(scenario.deck[card_id]):
			deck.append(StringName(card_id))
	s.set_deck(deck)
	return s
```

- [ ] **Step 4: Write the content .tres files**

All card files follow this exact template (repo skill `add-content-definition`); shown in full for the first, then the varying fields for the rest.

`game/content/cards/card.march.tres`:

```text
[gd_resource type="Resource" script_class="CwCardDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://modules/card_war/sim/cw_card_def.gd" id="1_def"]

[resource]
script = ExtResource("1_def")
id = &"card.march"
display_name = "March"
energy_cost = 2
order_type = &"march"
```

The other five cards — same file body, changing only `id`, `display_name`, `energy_cost`, `order_type`:

| file | id | display_name | energy_cost | order_type |
|---|---|---|---|---|
| card.gather_food.tres | `card.gather_food` | Gather Food | 1 | `gather_food` |
| card.build_camp.tres | `card.build_camp` | Build Camp | 1 | `build_camp` |
| card.transport.tres | `card.transport` | Transport Food | 1 | `transport` |
| card.assault.tres | `card.assault` | Assault | 3 | `assault` |
| card.feast.tres | `card.feast` | Victory Feast | 1 | `feast` |

`game/content/generals/general.asun.tres`:

```text
[gd_resource type="Resource" script_class="CwGeneralDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://modules/card_war/sim/cw_general_def.gd" id="1_def"]

[resource]
script = ExtResource("1_def")
id = &"general.asun"
display_name = "Marshal Asun"
general_class = &"warrior"
combat_factor = 1.0
loss_reduction = 0.25
```

`game/content/terrains/terrain.plains.tres`:

```text
[gd_resource type="Resource" script_class="CwTerrainDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://modules/card_war/sim/cw_terrain_def.gd" id="1_def"]

[resource]
script = ExtResource("1_def")
id = &"terrain.plains"
display_name = "Plains"
letter = "P"
move_cost = 2
```

The other five terrains — same body, changing `id`, `display_name`, `letter`, `move_cost`:

| file | id | display_name | letter | move_cost |
|---|---|---|---|---|
| terrain.forest.tres | `terrain.forest` | Forest | F | 3 |
| terrain.river.tres | `terrain.river` | River | R | 0 |
| terrain.mountain.tres | `terrain.mountain` | Mountains | M | 0 |
| terrain.city_home.tres | `terrain.city_home` | City ground (home) | H | 2 |
| terrain.city_enemy.tres | `terrain.city_enemy` | City ground (enemy) | E | 2 |

`game/content/maps/map.tutorial_01.tres` (16 rows x 16 chars; home 2x2 south, enemy 1 tile north, river row 8 with fords at x=6 and x=13, forest patches, mountain border):

```text
[gd_resource type="Resource" script_class="CwMapDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://modules/card_war/sim/cw_map_def.gd" id="1_def"]

[resource]
script = ExtResource("1_def")
id = &"map.tutorial_01"
rows = PackedStringArray("MMMMMMMMMMMMMMMM", "MPPPPPPPPPPPPPPM", "MPPPPPPPEPPPPPPM", "MPPPPFFPPPFFPPPM", "MPPPPFFPPPFFPPPM", "MPPPPPPPPPPPPPPM", "MPPPPPPPPPPPPPPM", "MPPPPPPPPPPPPPPM", "MRRRRRPRRRRRRPRM", "MPPPPPPPPPPPPPPM", "MPPPPPPPPPPPPPPM", "MPPPFFPPPPPFFPPM", "MPPPFFPPPPPFFPPM", "MPPPPPPHHPPPPPPM", "MPPPPPPHHPPPPPPM", "MMMMMMMMMMMMMMMM")
```

`game/content/scenarios/scenario.tutorial_01.tres` (only non-default exports written; the defaults in `CwScenarioDef` already match the design table):

```text
[gd_resource type="Resource" script_class="CwScenarioDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://modules/card_war/sim/cw_scenario_def.gd" id="1_def"]

[resource]
script = ExtResource("1_def")
id = &"scenario.tutorial_01"
map_id = &"map.tutorial_01"
deck = {
"card.assault": 3,
"card.build_camp": 3,
"card.feast": 3,
"card.gather_food": 3,
"card.march": 3,
"card.transport": 3
}
general_ids = PackedStringArray("general.asun")
```

- [ ] **Step 5: Update the content integrity test**

In `game/tests/demo/test_content.gd`:
- `test_content_scans_without_errors`: expected count `5` → `20`.
- `test_expected_ids_present`: extend the id list with all 15 new ids from the Interfaces block above.

- [ ] **Step 6: Run tests to verify they pass**

Single-suite with `test_playthrough.gd`, then `res://tests/demo/test_content.gd`. Expected: PASS both. If the playthrough's path-length assertions fail (arrival turn != 5), print `s.map.find_path(Vector2i(7,13), Vector2i(8,3))` and fix the MAP (not the test): the map must give a 26-point route.

- [ ] **Step 7: Verify + commit**

```bash
bash tools/check.sh
git add game/content game/modules/card_war/sim/cw_builder.gd* game/tests docs/contracts/TASK-2026-07-02-109.yaml
git commit -m "feat(card_war): tutorial content defs, state builder, scripted playthrough

TASK-2026-07-02-109. Evidence: CHECK: PASS (tools/check.sh)."
```

---

### Task 10: Battle scene — map rendering, HUD, end turn, report, boot wiring

**Files:**
- Create: `game/modules/card_war/ui/cw_map_view.gd`, `game/modules/card_war/ui/battle.gd`, `game/modules/card_war/ui/battle.tscn`
- Create: `game/content/scenes/card_war_battle.tres`
- Modify: `game/project.godot` (`app/start_scene_id` → `"scene.card_war_battle"`)
- Modify: `game/tests/demo/test_content.gd` (count 20 → 21; add `scene.card_war_battle` to ids and to the scene-path check)
- Test: `game/tests/card_war/test_battle_scene.gd`

**Interfaces:**
- Consumes: `CwBuilder.build(...)` (Task 9), `CwResolver.resolve(...)` (Task 5), `CwState` HUD getters (Task 3), Registry/EventBus/SceneFlow autoloads (core).
- Produces (Task 11 builds on these exact members of `battle.gd`):
  - `var state: CwState`, `var map_view: CwMapView`
  - UI nodes: `_hud_label`, `_status_label`, `_order_info: Label`, `_troops_spin`, `_food_spin: SpinBox`, `_confirm_btn`, `_end_turn_btn: Button`, `_hand_box: VBoxContainer`, `_report_panel: PanelContainer`, `_report_text: RichTextLabel`, `_result_label: Label`
  - `_card_names: Dictionary` (card id → display name), `_refresh()`, `_add_hand_entry(card)`, `_end_turn()`, `_event_text(e: Dictionary) -> String`, `_show_tile_info(tile)`
  - `CwMapView`: `var state: CwState`, `signal tile_clicked(tile: Vector2i)`, `refresh()`, `const TILE := 40`
  - EventBus topics published on game end: `&"card_war.victory"`, `&"card_war.defeat"` with `{"turn": int}`.

- [ ] **Step 1: Write the failing test**

`game/tests/card_war/test_battle_scene.gd`:

```gdscript
extends GdUnitTestSuite

func test_battle_scene_builds_state_from_content() -> void:
	var scene: PackedScene = load("res://modules/card_war/ui/battle.tscn")
	var battle: Node2D = auto_free(scene.instantiate())
	add_child(battle)
	var s: CwState = battle.state
	assert_object(s).is_not_null()
	assert_int(s.cities.size()).is_equal(2)
	assert_int(s.hand.size()).is_equal(5)
	assert_that(s.map.size).is_equal(Vector2i(16, 16))
	remove_child(battle)


func test_end_turn_resolves_and_reports() -> void:
	var scene: PackedScene = load("res://modules/card_war/ui/battle.tscn")
	var battle: Node2D = auto_free(scene.instantiate())
	add_child(battle)
	var s: CwState = battle.state
	battle._end_turn()
	assert_int(s.turn).is_equal(2)
	assert_bool(battle._report_panel.visible).is_true()
	assert_bool(battle._report_text.text.length() > 0).is_true()
	remove_child(battle)
```

- [ ] **Step 2: Run test to verify it fails**

Single-suite command with `test_battle_scene.gd`. Expected: FAIL (scene missing).

- [ ] **Step 3: Implement CwMapView**

`game/modules/card_war/ui/cw_map_view.gd`:

```gdscript
class_name CwMapView
extends Node2D
## Placeholder renderer: colored tile grid + entity markers, click to select.
## Pure view: reads CwState, never mutates it.

signal tile_clicked(tile: Vector2i)

const TILE := 40
const COLORS := {
	"P": Color(0.55, 0.75, 0.45), "F": Color(0.22, 0.48, 0.28),
	"R": Color(0.35, 0.55, 0.85), "M": Color(0.5, 0.48, 0.45),
	"H": Color(0.9, 0.85, 0.5), "E": Color(0.85, 0.45, 0.4),
}

var state: CwState
var highlight := Vector2i(-1, -1)


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	if state == null:
		return
	var font := ThemeDB.fallback_font
	for y: int in state.map.size.y:
		for x: int in state.map.size.x:
			var p := Vector2i(x, y)
			var color: Color = COLORS.get(state.map.letter_at(p), Color.BLACK)
			draw_rect(Rect2(x * TILE, y * TILE, TILE - 1, TILE - 1), color)
	for c: CwCity in state.cities.values():
		var owner_color := Color.GOLD if c.owner_side == &"player" else Color.CRIMSON
		for t: Vector2i in c.tiles:
			draw_rect(Rect2(t.x * TILE, t.y * TILE, TILE - 1, TILE - 1),
					owner_color, false, 3.0)
	for camp: CwCamp in state.camps.values():
		draw_rect(Rect2(camp.pos.x * TILE + 8, camp.pos.y * TILE + 8,
				TILE - 16, TILE - 16), Color.ORANGE)
	for v: CwConvoy in state.convoys.values():
		draw_rect(Rect2(v.pos.x * TILE + 12, v.pos.y * TILE + 12,
				TILE - 24, TILE - 24), Color.CYAN)
	for a: CwArmy in state.armies.values():
		draw_rect(Rect2(a.pos.x * TILE + 6, a.pos.y * TILE + 6,
				TILE - 12, TILE - 12), Color.WHITE)
		draw_string(font, Vector2(a.pos.x * TILE + 4, a.pos.y * TILE + 30),
				str(a.troops), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.BLACK)
	if highlight.x >= 0:
		draw_rect(Rect2(highlight.x * TILE, highlight.y * TILE, TILE - 1, TILE - 1),
				Color.WHITE, false, 2.0)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var local := get_local_mouse_position()
	if local.x < 0.0 or local.y < 0.0:
		return
	var tile := Vector2i(int(local.x) / TILE, int(local.y) / TILE)
	if state != null and state.map.in_bounds(tile):
		highlight = tile
		queue_redraw()
		tile_clicked.emit(tile)
```

- [ ] **Step 4: Implement battle.gd (state build, HUD, end turn, report)**

`game/modules/card_war/ui/battle.gd`:

```gdscript
extends Node2D
## Tutorial Mission 1 battle screen. Builds CwState from Registry content and
## runs the four spec phases: issue orders -> commit -> resolution -> report.
## Order interaction (hand buttons, targeting) is added on top in Task 11.

const SCENARIO_ID := &"scenario.tutorial_01"

@onready var map_view: CwMapView = $MapView

var state: CwState
var _card_names := {}

var _hud_label: Label
var _status_label: Label
var _order_info: Label
var _troops_spin: SpinBox
var _food_spin: SpinBox
var _confirm_btn: Button
var _hand_box: VBoxContainer
var _end_turn_btn: Button
var _report_panel: PanelContainer
var _report_text: RichTextLabel
var _result_label: Label


func _ready() -> void:
	var registry := get_node_or_null("/root/Registry")
	if registry == null:
		push_error("battle: Registry autoload missing")
		return
	if not registry.has_def(SCENARIO_ID):
		registry.scan("res://content")
	state = _build_state(registry)
	map_view.state = state
	map_view.tile_clicked.connect(_on_tile_clicked)
	_build_ui()
	_refresh()


func _build_state(registry: Node) -> CwState:
	var scenario: CwScenarioDef = registry.get_def(SCENARIO_ID)
	var map_def: CwMapDef = registry.get_def(scenario.map_id)
	var terrains: Array[CwTerrainDef] = []
	for id: StringName in registry.ids_with_prefix("terrain."):
		terrains.append(registry.get_def(id))
	var cards: Array[CwCardDef] = []
	for id: StringName in registry.ids_with_prefix("card."):
		var card: CwCardDef = registry.get_def(id)
		cards.append(card)
		_card_names[card.id] = card.display_name
	var generals: Array[CwGeneralDef] = []
	for gid: String in scenario.general_ids:
		generals.append(registry.get_def(StringName(gid)))
	return CwBuilder.build(scenario, map_def, terrains, cards, generals, randi())


func _build_ui() -> void:
	var ui: CanvasLayer = $UI
	var panel := VBoxContainer.new()
	panel.position = Vector2(680, 16)
	panel.custom_minimum_size = Vector2(580, 688)
	ui.add_child(panel)
	_hud_label = Label.new()
	panel.add_child(_hud_label)
	_status_label = Label.new()
	_status_label.text = "Click a tile for info. Play a card, or end the turn."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_status_label)
	_order_info = Label.new()
	_order_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_order_info)
	_troops_spin = SpinBox.new()
	_troops_spin.min_value = 100
	_troops_spin.max_value = 10000
	_troops_spin.step = 100
	_troops_spin.value = 2000
	_troops_spin.prefix = "Troops"
	_troops_spin.visible = false
	panel.add_child(_troops_spin)
	_food_spin = SpinBox.new()
	_food_spin.min_value = 30
	_food_spin.max_value = 5000
	_food_spin.step = 30
	_food_spin.value = 300
	_food_spin.prefix = "Food"
	_food_spin.visible = false
	panel.add_child(_food_spin)
	_confirm_btn = Button.new()
	_confirm_btn.text = "Confirm order"
	_confirm_btn.visible = false
	_confirm_btn.pressed.connect(_confirm_order)
	panel.add_child(_confirm_btn)
	var hand_title := Label.new()
	hand_title.text = "Hand:"
	panel.add_child(hand_title)
	_hand_box = VBoxContainer.new()
	panel.add_child(_hand_box)
	_end_turn_btn = Button.new()
	_end_turn_btn.text = "End turn (commit orders)"
	_end_turn_btn.pressed.connect(_end_turn)
	panel.add_child(_end_turn_btn)
	_report_panel = PanelContainer.new()
	_report_panel.position = Vector2(160, 160)
	_report_panel.custom_minimum_size = Vector2(480, 360)
	_report_panel.visible = false
	ui.add_child(_report_panel)
	var report_box := VBoxContainer.new()
	_report_panel.add_child(report_box)
	_report_text = RichTextLabel.new()
	_report_text.custom_minimum_size = Vector2(460, 300)
	report_box.add_child(_report_text)
	var close_btn := Button.new()
	close_btn.text = "Close report"
	close_btn.pressed.connect(func() -> void: _report_panel.visible = false)
	report_box.add_child(close_btn)
	_result_label = Label.new()
	_result_label.position = Vector2(120, 40)
	_result_label.add_theme_font_size_override("font_size", 64)
	_result_label.visible = false
	ui.add_child(_result_label)


func _refresh() -> void:
	_hud_label.text = "Turn %d | Energy %d | Food %d | Morale %.0f" % [state.turn,
			state.energy, state.total_player_food(), state.avg_player_morale()]
	for child: Node in _hand_box.get_children():
		child.queue_free()
	for card: StringName in state.hand:
		_add_hand_entry(card)
	map_view.refresh()


## Display-only in this task; Task 11 turns entries into order buttons.
func _add_hand_entry(card: StringName) -> void:
	var label := Label.new()
	label.text = "%s (%d)" % [_card_names.get(card, String(card)), state.card_cost(card)]
	_hand_box.add_child(label)


## Tile info only in this task; Task 11 extends it with order targeting.
func _on_tile_clicked(tile: Vector2i) -> void:
	_show_tile_info(tile)


func _show_tile_info(tile: Vector2i) -> void:
	var bits: Array[String] = []
	bits.append("Tile %s (%s)" % [str(tile), state.map.letter_at(tile)])
	var c: CwCity = state.city_at(tile)
	if c != null:
		bits.append("%s: troops %d, food %d, morale %.0f" % [c.id, c.troops, c.food, c.morale])
	var a: CwArmy = state.army_at(tile)
	if a != null:
		bits.append("Army %d: troops %d, food %d, morale %.0f" % [a.id, a.troops, a.food, a.morale])
	var camp: CwCamp = state.camp_at(tile)
	if camp != null:
		bits.append("Camp %d: troops %d, food %d" % [camp.id, camp.troops, camp.food])
	_status_label.text = " | ".join(bits)


func _end_turn() -> void:
	if state.result != &"":
		return
	var events: Array[Dictionary] = CwResolver.resolve(state)
	var lines: Array[String] = []
	for e: Dictionary in events:
		lines.append(_event_text(e))
	_report_text.text = "\n".join(lines)
	_report_panel.visible = true
	_refresh()
	if state.result != &"":
		_result_label.text = "VICTORY!" if state.result == &"victory" else "DEFEAT"
		_result_label.visible = true
		_end_turn_btn.disabled = true
		var bus := get_node_or_null("/root/EventBus")
		if bus:
			bus.publish(StringName("card_war." + String(state.result)), {"turn": state.turn})


func _event_text(e: Dictionary) -> String:
	match e["t"]:
		&"order_started":
			return "Order underway (%s)." % String(e.get("type", &""))
		&"army_moved":
			return "Army %d moved to %s." % [e["id"], str(e["pos"])]
		&"army_arrived":
			return "Army %d arrived at %s and holds position." % [e["id"], str(e["pos"])]
		&"army_returning":
			return "Army %d is heading home." % e["id"]
		&"army_returned":
			return "Army %d returned and merged into the city." % e["id"]
		&"army_disbanded":
			return "An army has disbanded!"
		&"camp_built":
			return "Camp built (%d-tile footprint)." % e["footprint"]
		&"camp_lost":
			return "A camp was lost."
		&"convoy_arrived":
			var okd: bool = e["delivered"]
			return "Convoy arrived (%s)." % ("delivered" if okd else "food lost")
		&"food_gathered":
			return "Gathered %d food at %s." % [e["amount"], e["city"]]
		&"feast_held":
			return "Victory feast held — morale restored."
		&"assault":
			var suffix: String = " — CITY CAPTURED!" if e["captured"] else ""
			return "Assault on %s: defenders -%d, attackers -%d%s" % [e["city"],
					e["def_losses"], e["att_losses"], suffix]
		&"starving":
			return "%s %s is starving!" % [String(e["kind"]), str(e["id"])]
		&"city_surrendered":
			return "City %s surrendered to the %s side!" % [e["id"], String(e["to"])]
		&"victory":
			return "The enemy city has fallen. VICTORY!"
		&"defeat":
			return "The campaign is lost."
		&"turn_ended":
			return "— Turn %d begins —" % e["turn"]
	return String(e["t"])


# --- Order flow: implemented in Task 11 ------------------------------------------

func _confirm_order() -> void:
	pass  # Task 11
```

- [ ] **Step 5: Create battle.tscn + scene def + boot wiring**

`game/modules/card_war/ui/battle.tscn` (write by hand; Godot will add uids on import):

```text
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://modules/card_war/ui/battle.gd" id="1_battle"]
[ext_resource type="Script" path="res://modules/card_war/ui/cw_map_view.gd" id="2_map"]

[node name="Battle" type="Node2D"]
script = ExtResource("1_battle")

[node name="MapView" type="Node2D" parent="."]
position = Vector2(16, 16)
script = ExtResource("2_map")

[node name="UI" type="CanvasLayer" parent="."]
```

`game/content/scenes/card_war_battle.tres`:

```text
[gd_resource type="Resource" script_class="SceneDef" load_steps=2 format=3]

[ext_resource type="Script" path="res://core/scene_flow/scene_def.gd" id="1_def"]

[resource]
script = ExtResource("1_def")
id = &"scene.card_war_battle"
scene_path = "res://modules/card_war/ui/battle.tscn"
```

In `game/project.godot`, change one line:

```text
[app]

start_scene_id="scene.card_war_battle"
```

In `game/tests/demo/test_content.gd`: count 20 → 21; add `&"scene.card_war_battle"` to the expected-ids list and to `test_scene_defs_point_at_existing_scenes`.

- [ ] **Step 6: Run tests to verify they pass**

Single-suite with `test_battle_scene.gd` and `res://tests/demo/test_content.gd`. Expected: PASS. Then full `bash tools/check.sh` — the boot smoke now boots INTO the battle scene headless; it must stay clean (no SCRIPT ERROR) and keep the `boot: ok` / `boot: content scanned` markers.

- [ ] **Step 7: Verify + commit**

```bash
bash tools/check.sh
git add game/modules/card_war/ui game/content/scenes game/project.godot game/tests docs/contracts/TASK-2026-07-02-110.yaml
git commit -m "feat(card_war): battle scene with map view, HUD, resolution report; boot into it

TASK-2026-07-02-110. Evidence: CHECK: PASS (tools/check.sh)."
```

---

### Task 11: Hand buttons and order targeting flow

**Files:**
- Modify: `game/modules/card_war/ui/battle.gd` (replace `_add_hand_entry`, `_on_tile_clicked`, `_confirm_order`; add flow vars + helpers)
- Modify: `game/modules/card_war/sim/cw_state.gd` (add `free_generals()`)
- Test: `game/tests/card_war/test_battle_scene.gd` (add flow test)

**Interfaces:**
- Consumes: Task 10 UI members; `CwState.play_card` (Task 4).
- Produces:
  - `CwState.free_generals() -> Array[StringName]` — registered generals not busy, sorted.
  - Flow: click hand button → per-card-type prompts (design doc "Order targeting flow") → preview (march shows turns + food budget) → Confirm → `play_card` → status shows rejection reason or queues.

- [ ] **Step 1: Write the failing test**

Append to `game/tests/card_war/test_battle_scene.gd`:

```gdscript
func test_march_order_flow_queues_order() -> void:
	var scene: PackedScene = load("res://modules/card_war/ui/battle.tscn")
	var battle: Node2D = auto_free(scene.instantiate())
	add_child(battle)
	var s: CwState = battle.state
	s.hand.clear()
	s.hand.append(&"card.march")
	battle._refresh()
	battle._begin_card(&"card.march")
	battle._troops_spin.value = 2000
	battle._on_tile_clicked(Vector2i(8, 3))
	battle._confirm_order()
	assert_int(s.pending.size()).is_equal(1)
	assert_int(s.energy).is_equal(1)  # 3 - march cost 2
	var o: CwOrder = s.pending[0]
	assert_that(o.params["to"]).is_equal(Vector2i(8, 3))
	assert_int(int(o.params["troops"])).is_equal(2000)
	remove_child(battle)


func test_rejected_order_reports_reason_and_keeps_state() -> void:
	var scene: PackedScene = load("res://modules/card_war/ui/battle.tscn")
	var battle: Node2D = auto_free(scene.instantiate())
	add_child(battle)
	var s: CwState = battle.state
	s.hand.clear()
	s.hand.append(&"card.march")
	battle._begin_card(&"card.march")
	battle._troops_spin.value = 9000  # more than the city holds
	battle._on_tile_clicked(Vector2i(8, 3))
	battle._confirm_order()
	assert_int(s.pending.size()).is_equal(0)
	assert_int(s.energy).is_equal(3)
	assert_bool(battle._status_label.text.contains("rejected")).is_true()
	remove_child(battle)
```

- [ ] **Step 2: Run test to verify it fails**

Single-suite with `test_battle_scene.gd`. Expected: FAIL (`_begin_card` missing).

- [ ] **Step 3: Implement the flow**

Add to `game/modules/card_war/sim/cw_state.gd`:

```gdscript
func free_generals() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in _generals.keys():
		if not is_general_busy(id):
			out.append(id)
	out.sort()
	return out
```

In `game/modules/card_war/ui/battle.gd`, add flow vars after `_card_names`:

```gdscript
var _card: StringName = &""
var _stage: StringName = &""  # pick_dest | pick_army | pick_enemy_city | pick_target | pick_feast
var _params: Dictionary = {}
```

Replace `_add_hand_entry` (labels → buttons):

```gdscript
func _add_hand_entry(card: StringName) -> void:
	var b := Button.new()
	b.text = "%s (%d)" % [_card_names.get(card, String(card)), state.card_cost(card)]
	b.disabled = state.energy < state.card_cost(card) or state.result != &""
	b.pressed.connect(_begin_card.bind(card))
	_hand_box.add_child(b)
```

Add the flow methods (and replace `_on_tile_clicked` / `_confirm_order`):

```gdscript
func _begin_card(card: StringName) -> void:
	_cancel_order()
	_card = card
	match state.card_type(card):
		&"march":
			var free: Array[StringName] = state.free_generals()
			if free.is_empty():
				_status_label.text = "No free general to lead the march."
				_card = &""
				return
			_params["general_id"] = free[0]
			_params["from_city"] = _first_player_city()
			_stage = &"pick_dest"
			_troops_spin.visible = true
			_status_label.text = "March: set troops, then click a destination tile."
		&"gather_food":
			_params["city"] = _first_player_city()
			_order_info.text = "Gather food at %s." % _params["city"]
			_confirm_btn.visible = true
		&"build_camp":
			_stage = &"pick_army"
			_status_label.text = "Build camp: click one of your armies."
		&"transport":
			_params["from_city"] = _first_player_city()
			_stage = &"pick_target"
			_food_spin.visible = true
			_status_label.text = "Transport: set amount, then click a camp or army."
		&"assault":
			_stage = &"pick_army"
			_status_label.text = "Assault: click your army, then the enemy city."
		&"feast":
			_stage = &"pick_feast"
			_status_label.text = "Feast: click a victorious army or a captured city."


func _on_tile_clicked(tile: Vector2i) -> void:
	if _card == &"":
		_show_tile_info(tile)
		return
	match _stage:
		&"pick_dest":
			_params["to"] = tile
			_update_march_preview()
		&"pick_army":
			var a: CwArmy = state.army_at(tile)
			if a == null:
				_status_label.text = "No army on that tile."
				return
			_params["army_id"] = a.id
			if state.card_type(_card) == &"assault":
				_stage = &"pick_enemy_city"
				_status_label.text = "Now click the enemy city."
			else:
				_order_info.text = "Build camp at %s." % str(a.pos)
				_confirm_btn.visible = true
		&"pick_enemy_city":
			var c: CwCity = state.city_at(tile)
			if c == null or c.owner_side != &"enemy":
				_status_label.text = "Click an enemy city tile."
				return
			_params["city"] = c.id
			_order_info.text = "Assault %s." % c.id
			_confirm_btn.visible = true
		&"pick_target":
			var camp: CwCamp = state.camp_at(tile)
			var army: CwArmy = state.army_at(tile)
			if camp != null:
				_params["target_kind"] = &"camp"
				_params["target_id"] = camp.id
			elif army != null:
				_params["target_kind"] = &"army"
				_params["target_id"] = army.id
			else:
				_status_label.text = "Click a camp or an army."
				return
			_order_info.text = "Send %d food." % int(_food_spin.value)
			_confirm_btn.visible = true
		&"pick_feast":
			var fa: CwArmy = state.army_at(tile)
			var fc: CwCity = state.city_at(tile)
			if fa != null:
				_params["target_kind"] = &"army"
				_params["target_id"] = fa.id
			elif fc != null and fc.owner_side == &"player":
				_params["target_kind"] = &"city"
				_params["target_id"] = fc.id
			else:
				_status_label.text = "Click an army or one of your cities."
				return
			_order_info.text = "Hold a victory feast."
			_confirm_btn.visible = true


func _update_march_preview() -> void:
	var city: CwCity = state.cities[_params["from_city"]]
	var path: Array[Vector2i] = state.map.find_path(state.spawn_tile(city), _params["to"])
	if path.is_empty():
		_order_info.text = "That destination is unreachable."
		_confirm_btn.visible = false
		return
	var troops := int(_troops_spin.value)
	var turns := state.map.turns_for_path(path, state.tuning.move_points_per_turn)
	var food := state.march_food_needed(troops, path)
	_order_info.text = "March %d troops: %d turn(s) to arrive, %d food budget." % [
			troops, turns, food]
	_confirm_btn.visible = true


func _confirm_order() -> void:
	if _card == &"":
		return
	var o := CwOrder.new()
	o.card_id = _card
	o.type = state.card_type(_card)
	if o.type == &"march":
		_params["troops"] = int(_troops_spin.value)
	if o.type == &"transport":
		_params["food"] = int(_food_spin.value)
	o.params = _params.duplicate()
	var err: Error = state.play_card(o)
	if err != OK:
		_status_label.text = "Order rejected (err %d): check troops, food, energy and target." % err
		return
	_status_label.text = "Order queued for this turn."
	_cancel_order()
	_refresh()


func _cancel_order() -> void:
	_card = &""
	_stage = &""
	_params = {}
	_order_info.text = ""
	_troops_spin.visible = false
	_food_spin.visible = false
	_confirm_btn.visible = false


func _first_player_city() -> StringName:
	for c: CwCity in state.cities.values():
		if c.owner_side == &"player":
			return c.id
	return &""
```

Also make `_end_turn` cancel any half-built order — add `_cancel_order()` as its first statement after the result guard.

- [ ] **Step 4: Run tests to verify they pass**

Single-suite with `test_battle_scene.gd` (4 tests now). Expected: PASS.

- [ ] **Step 5: Verify + commit**

```bash
bash tools/check.sh
git add game/modules/card_war game/tests/card_war/test_battle_scene.gd* docs/contracts/TASK-2026-07-02-111.yaml
git commit -m "feat(card_war): hand buttons and card-order targeting flow

TASK-2026-07-02-111. Evidence: CHECK: PASS (tools/check.sh)."
```

---

### Task 12: Domain doc, final verification, play gate

**Files:**
- Create: `docs/memory/domains/card_war.md`

**Interfaces:** none new — this task closes the slice.

- [ ] **Step 1: Write the domain doc**

`docs/memory/domains/card_war.md`:

```markdown
# Domain: card_war (module)

- Owner role: Architect
- Last verified: <today's date>

Turn-based card-war slice (Tutorial Mission 1). Spec:
`docs/superpowers/specs/2026-07-02-card-war-vertical-slice-design.md`.

**Invariants**
- `sim/` is pure: RefCounted, plain values, no Registry/EventBus/scene access.
  `CwBuilder` is the only sim file that reads Definition resources (passed in).
- State mutates only via `CwState.play_card` (atomic: reject = zero change,
  with pending-order reservations) and `CwResolver.resolve` (7 fixed phases:
  orders, movement, combat, production, consumption, morale, end-check).
- Food formula is locked: `ceili(troops / 100.0 * 3.0)` per turn (1 thach =
  100 troops x 1 day; 1 turn = 3 days). All other numbers live in
  `CwScenarioDef` (.tres), never in code.
- Ids: `card.* general.* terrain.* map.* scenario.*` (+ `scene.card_war_battle`).
- Map letters: P/F/R/M terrain, H/E are home/enemy city ground (cost 2).
- EventBus topics published: `card_war.victory`, `card_war.defeat` {turn}.
- Resolver events (`{"t": ...}`) are the only UI-facing change feed.

**Gotchas**
- Seeded shuffle: sim tests that need specific cards stuff `state.hand`
  directly instead of relying on draws.
- Generals stay busy while their army OR camp exists; freed on merge-home,
  disband, or camp loss.
- Boot starts `scene.card_war_battle` (project.godot `app/start_scene_id`);
  demo scenes remain but are unreached.
- Convoys are abstract (no escort/interception yet — next iterations add
  scouting/ambush per the full spec).
```

- [ ] **Step 2: Full verification run**

```bash
bash tools/check.sh
```

Expected output ends with `CHECK: PASS`, test summary shows all card_war suites green (10 suites), boot smoke boots into the battle scene with `boot: ok` + `boot: content scanned`.

- [ ] **Step 3: Commit**

```bash
git add docs/memory/domains/card_war.md docs/contracts/TASK-2026-07-02-112.yaml
git commit -m "docs(card_war): domain doc for the card-war slice

TASK-2026-07-02-112. Evidence: CHECK: PASS (tools/check.sh)."
```

- [ ] **Step 4: Play gate (human)**

Per workflow `new-game.md` step 8 — an agent cannot pass this gate. Ask the owner to run the game (Godot editor F5, or the exported binary) and play Mission 1: march ~4000 troops north past the river ford, assault the enemy city twice, win. Owner decides: continue (add scouting/visibility next), adjust numbers, or re-cut the slice.

---

## Plan Self-Review Notes

- **Spec coverage:** playable loop (orders→commit→resolve→report) Tasks 5–11; win/lose Task 5/7; 6 cards Tasks 4–8; Asun passive Task 7; food formula Tasks 3–6; morale Task 6; footprint Task 8; provisional numbers as content Task 9; boot wiring Task 10. Deliberately out (per design doc): scouting, visibility levels, ambush, siege, feint, weather, AI, general cards.
- **Numbers cross-check:** march 4000 → path 13 tiles / 26 pts / 5 turns; budget 120 × 12 = 1440; assault ratios 2.667 → 800/225 losses, second assault captures; home ledger 2000 − 1440 + 7×90 = 1190 (asserted in Task 9).
- **Type consistency:** event field names (`t/id/pos/city/army/amount/delivered/captured/att_losses/def_losses/footprint/kind/to/turn`) match between resolver (Tasks 5–8) and `_event_text` (Task 10); `CwState` member names match across Tasks 3–11.
