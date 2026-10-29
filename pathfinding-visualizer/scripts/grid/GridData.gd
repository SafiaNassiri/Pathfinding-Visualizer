class_name GridData
extends Resource

signal cell_changed(x: int, y: int)
signal grid_reset()

const BLOCKED := 0
const WALKABLE_DEFAULT := 1

@export var cost: PackedByteArray = PackedByteArray()
@export var start_pos: Vector2i = Vector2i(5, 32)
@export var goal_pos: Vector2i = Vector2i(58, 32)

func _init() -> void:
	if cost.size() != Config.GRID_W * Config.GRID_H:
		reset()

func reset() -> void:
	cost.resize(Config.GRID_W * Config.GRID_H)
	cost.fill(WALKABLE_DEFAULT)
	grid_reset.emit()

func get_index(x: int, y: int) -> int:
	return y * Config.GRID_W + x

func get_cost(x: int, y: int) -> int:
	if not in_bounds(x, y):
		return BLOCKED
	return cost[get_index(x, y)]

func set_blocked(x: int, y: int) -> void:
	if not in_bounds(x, y):
		return
	cost[get_index(x, y)] = BLOCKED
	cell_changed.emit(x, y)

func clear_cell(x: int, y: int) -> void:
	if not in_bounds(x, y):
		return
	cost[get_index(x, y)] = WALKABLE_DEFAULT
	cell_changed.emit(x, y)

func set_walkable(x: int, y: int, c: int) -> void:
	if not in_bounds(x, y):
		return
	cost[get_index(x, y)] = clampi(c, 1, 255)
	cell_changed.emit(x, y)

func is_walkable(x: int, y: int) -> bool:
	return get_cost(x, y) > BLOCKED

static func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < Config.GRID_W and y >= 0 and y < Config.GRID_H

static func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / Config.TILE_SIZE),
		floori(world_pos.y / Config.TILE_SIZE)
	)
