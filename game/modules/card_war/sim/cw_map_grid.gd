class_name CwMapGrid
extends RefCounted
## Grid of terrain letters with move costs.
## Pure logic: no scene tree, no autoloads. Dijkstra over 4-neighbours.

const DIRECTIONS: Array[Vector2i] = [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.UP,
]

var size: Vector2i = Vector2i.ZERO
var _letters: Array[String] = []
var _costs: Array[int] = []


static func from_rows(rows: PackedStringArray, letter_cost: Dictionary) -> CwMapGrid:
	var g: CwMapGrid = CwMapGrid.new()
	g.size = Vector2i(rows[0].length() if rows.size() > 0 else 0, rows.size())
	for row: String in rows:
		for i: int in range(row.length()):
			var letter: String = row[i]
			g._letters.append(letter)
			g._costs.append(int(letter_cost.get(letter, 0)))
	return g


func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < size.x and p.y < size.y


func letter_at(p: Vector2i) -> String:
	if not in_bounds(p):
		return ""
	return _letters[p.y * size.x + p.x]


func move_cost(p: Vector2i) -> int:
	if not in_bounds(p):
		return 0
	return _costs[p.y * size.x + p.x]


func tiles_with_letter(letter: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in range(size.y):
		for x: int in range(size.x):
			if _letters[y * size.x + x] == letter:
				out.append(Vector2i(x, y))
	return out


## Cheapest path. Excludes `from`, includes `to`. [] if unreachable.
func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if not in_bounds(from) or not in_bounds(to) or move_cost(from) == 0 or move_cost(to) == 0:
		return empty
	if from == to:
		return empty

	var dist: Dictionary = {from: 0}
	var prev: Dictionary = {}
	var frontier: Array[Vector2i] = [from]
	while not frontier.is_empty():
		var best_i: int = 0
		for i: int in range(frontier.size()):
			var candidate_dist: int = int(dist[frontier[i]])
			var best_dist: int = int(dist[frontier[best_i]])
			if candidate_dist < best_dist:
				best_i = i

		var cur: Vector2i = frontier[best_i]
		frontier.remove_at(best_i)
		if cur == to:
			break

		for d: Vector2i in DIRECTIONS:
			var nxt: Vector2i = cur + d
			var c: int = move_cost(nxt)
			if c == 0:
				continue

			var nd: int = int(dist[cur]) + c
			if not dist.has(nxt) or nd < int(dist[nxt]):
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
		node = prev[node] as Vector2i
	return path


func turns_for_path(path: Array[Vector2i], points_per_turn: int) -> int:
	var turns: int = 0
	var points: int = 0
	for p: Vector2i in path:
		var c: int = move_cost(p)
		if points < c:
			turns += 1
			points = points_per_turn
		points -= c
	return turns
