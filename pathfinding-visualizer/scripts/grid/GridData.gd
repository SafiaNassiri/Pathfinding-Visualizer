class_name GridData
extends Resource
## Flat, one-byte-per-cell grid.
##   0      = blocked (not walkable)
##   1..255 = walkable, value is the movement cost multiplier (1 = normal)

signal cell_changed(x: int, y: int)
signal grid_reset

@export var cost := PackedByteArray()
@export var start_pos: Vector2i = Vector2i(5, 32)
@export var goal_pos: Vector2i = Vector2i(58, 32)

const BLOCKED := 0
const COST_DEFAULT := 1
const COST_MAX := 255

## One byte per chunk; 1 = chunk (or a border it shares) changed since last consume.
var dirty_chunks := PackedByteArray()


func _init() -> void:
	assert(Config.GRID_W == 1 << Config.GRID_SHIFT, "GRID_W must equal 1 << GRID_SHIFT")
	assert(Config.CHUNK_SIZE == 1 << Config.CHUNK_SHIFT, "CHUNK_SIZE must equal 1 << CHUNK_SHIFT")
	cost.resize(Config.GRID_W * Config.GRID_H)
	dirty_chunks.resize(Config.CHUNKS_X * Config.CHUNKS_Y)
	reset()


func reset() -> void:
	cost.fill(COST_DEFAULT)
	dirty_chunks.fill(1)
	grid_reset.emit()


# --- Indexing ---------------------------------------------------------------

static func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < Config.GRID_W and y < Config.GRID_H


static func index(x: int, y: int) -> int:
	return (y << Config.GRID_SHIFT) | x


static func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i((world_pos / Config.TILE_SIZE).floor())


## Top-left corner of the cell in world space.
static func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * Config.TILE_SIZE


## Center of the cell in world space (where agents should aim).
static func cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * Config.TILE_SIZE


# --- Queries ----------------------------------------------------------------

## Out-of-bounds cells report BLOCKED, so neighbor checks need no extra guard.
func get_cost(x: int, y: int) -> int:
	if not in_bounds(x, y):
		return BLOCKED
	return cost[index(x, y)]


func is_walkable(x: int, y: int) -> bool:
	return get_cost(x, y) != BLOCKED


# --- Mutation ---------------------------------------------------------------

## Returns true if the cell actually changed.
func set_cost(x: int, y: int, value: int) -> bool:
	if not in_bounds(x, y):
		return false
	value = clampi(value, BLOCKED, COST_MAX)
	var i := index(x, y)
	if cost[i] == value:
		return false
	cost[i] = value
	_mark_dirty(x, y)
	cell_changed.emit(x, y)
	return true


func set_blocked(x: int, y: int) -> bool:
	return set_cost(x, y, BLOCKED)


## Make a cell walkable with the given cost (default 1).
func set_walkable(x: int, y: int, move_cost: int = COST_DEFAULT) -> bool:
	return set_cost(x, y, maxi(move_cost, 1))

func set_start(x: int, y: int) -> bool:
	if not in_bounds(x, y) or get_cost(x, y) == BLOCKED:
		return false
	start_pos = Vector2i(x, y)
	cell_changed.emit(x, y)
	return true

func set_goal(x: int, y: int) -> bool:
	if not in_bounds(x, y) or get_cost(x, y) == BLOCKED:
		return false
	goal_pos = Vector2i(x, y)
	cell_changed.emit(x, y)
	return true

## Reset a cell to plain walkable ground.
func clear_cell(x: int, y: int) -> bool:
	return set_cost(x, y, COST_DEFAULT)


# --- Dirty chunk tracking (used by the hierarchical layer later) -------------

## Returns indices of dirty chunks and clears the flags.
func consume_dirty_chunks() -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in dirty_chunks.size():
		if dirty_chunks[i] != 0:
			out.append(i)
			dirty_chunks[i] = 0
	return out


func _mark_dirty(x: int, y: int) -> void:
	var cx := x >> Config.CHUNK_SHIFT
	var cy := y >> Config.CHUNK_SHIFT
	_mark_chunk(cx, cy)
	# A cell on a chunk border also changes the neighbor's portals.
	var mask := Config.CHUNK_SIZE - 1
	var lx := x & mask
	var ly := y & mask
	if lx == 0:
		_mark_chunk(cx - 1, cy)
	elif lx == mask:
		_mark_chunk(cx + 1, cy)
	if ly == 0:
		_mark_chunk(cx, cy - 1)
	elif ly == mask:
		_mark_chunk(cx, cy + 1)


func _mark_chunk(cx: int, cy: int) -> void:
	if cx < 0 or cy < 0 or cx >= Config.CHUNKS_X or cy >= Config.CHUNKS_Y:
		return
	dirty_chunks[cy * Config.CHUNKS_X + cx] = 1
