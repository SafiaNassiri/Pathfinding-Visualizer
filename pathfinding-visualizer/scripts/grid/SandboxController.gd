class_name SandboxController
extends Node2D

@export var grid_renderer: GridRenderer

enum Tool { PAINT_WALL, ERASE, PAINT_COST, SET_START, SET_GOAL }

var current_tool: Tool = Tool.PAINT_WALL
var grid: GridData
var _last_cell := Vector2i(-1, -1)
var _is_dragging := false

const COLOR_START := Color("4ade80")
const COLOR_GOAL := Color("f87171")


func _ready() -> void:
	# Find GridRenderer automatically in the current scene.
	var scene := get_tree().current_scene

	if scene == null:
		push_error("SandboxController: No current scene found.")
		set_process_input(false)
		return

	# Check whether this node itself is a GridRenderer.
	if scene is GridRenderer:
		grid_renderer = scene as GridRenderer
	else:
		# Search descendants for a node using the GridRenderer script.
		for node in scene.find_children("*", "", true, false):
			if node is GridRenderer:
				grid_renderer = node as GridRenderer
				break

	if grid_renderer == null:
		push_error(
			"SandboxController: Could not find a node using GridRenderer.gd. "
			+ "Check that GridRenderer.gd is attached to the GridRenderer node "
			+ "and that the script has no errors."
		)
		set_process_input(false)
		return

	# Use the exact same GridData resource as the renderer.
	if grid_renderer.grid == null:
		grid_renderer.setup(GridData.new())
	else:
		# Reconnect/rebuild safely in case the renderer already initialized.
		grid_renderer.setup(grid_renderer.grid)

	grid = grid_renderer.grid

	if grid == null:
		push_error("SandboxController: GridData could not be initialized.")
		set_process_input(false)
		return

	if not grid.grid_reset.is_connected(_on_grid_reset):
		grid.grid_reset.connect(_on_grid_reset)

	queue_redraw()

	print("SandboxController ready. Keys: 1 wall, 2 erase, 3 cost, 4 start, 5 goal, R randomize, C clear, S save, L load.")

func _input(event: InputEvent) -> void:
	if grid == null:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_set_tool(Tool.PAINT_WALL, "Paint wall")
			KEY_2:
				_set_tool(Tool.ERASE, "Erase")
			KEY_3:
				_set_tool(Tool.PAINT_COST, "Costly terrain")
			KEY_4:
				_set_tool(Tool.SET_START, "Set start")
			KEY_5:
				_set_tool(Tool.SET_GOAL, "Set goal")
			KEY_R:
				randomize_map()
			KEY_C:
				clear_grid()
			KEY_S:
				save_map()
			KEY_L:
				load_map()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_dragging = true
			_apply_tool(get_global_mouse_position())
		else:
			_is_dragging = false
			_last_cell = Vector2i(-1, -1)

	elif event is InputEventMouseMotion and _is_dragging:
		_apply_tool(get_global_mouse_position())


func _set_tool(tool: Tool, label: String) -> void:
	current_tool = tool
	_last_cell = Vector2i(-1, -1)
	print("Tool selected: ", label, ". Now click or drag on the grid.")


func _apply_tool(mouse_world: Vector2) -> void:
	if grid == null or grid_renderer == null:
		return

	var mouse_local: Vector2 = grid_renderer.to_local(mouse_world)
	var cell: Vector2i = GridData.world_to_cell(mouse_local)

	if not GridData.in_bounds(cell.x, cell.y):
		_last_cell = Vector2i(-1, -1)
		return

	if cell == _last_cell:
		return
	_last_cell = cell

	match current_tool:
		Tool.PAINT_WALL:
			if cell != grid.start_pos and cell != grid.goal_pos:
				grid.set_blocked(cell.x, cell.y)
		Tool.ERASE:
			if cell != grid.start_pos and cell != grid.goal_pos:
				grid.clear_cell(cell.x, cell.y)
		Tool.PAINT_COST:
			if cell != grid.start_pos and cell != grid.goal_pos:
				grid.set_walkable(cell.x, cell.y, 10)
		Tool.SET_START:
			if cell != grid.goal_pos and grid.is_walkable(cell.x, cell.y):
				grid.start_pos = cell
				queue_redraw()
		Tool.SET_GOAL:
			if cell != grid.start_pos and grid.is_walkable(cell.x, cell.y):
				grid.goal_pos = cell
				queue_redraw()


func randomize_map(fill_probability: float = 0.25) -> void:
	if grid == null:
		push_error("Cannot randomize: GridData is missing.")
		return

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	fill_probability = clampf(fill_probability, 0.0, 1.0)

	# Fill the data directly and send one refresh signal after the whole map is built.
	grid.cost.resize(Config.GRID_W * Config.GRID_H)
	grid.cost.fill(GridData.WALKABLE_DEFAULT)

	for y in range(Config.GRID_H):
		for x in range(Config.GRID_W):
			var cell := Vector2i(x, y)
			if cell == grid.start_pos or cell == grid.goal_pos:
				continue
			if rng.randf() < fill_probability:
				grid.cost[grid.get_index(x, y)] = GridData.BLOCKED

	grid.grid_reset.emit()
	_last_cell = Vector2i(-1, -1)
	queue_redraw()
	print("Map randomized.")


func clear_grid() -> void:
	if grid == null:
		push_error("Cannot clear: GridData is missing.")
		return

	grid.cost.resize(Config.GRID_W * Config.GRID_H)
	grid.cost.fill(GridData.WALKABLE_DEFAULT)
	grid.grid_reset.emit()
	_last_cell = Vector2i(-1, -1)
	queue_redraw()
	print("Grid cleared.")


func save_map(path: String = "user://saved_map.tres") -> void:
	if grid == null:
		push_error("Cannot save: GridData is missing.")
		return

	var error := ResourceSaver.save(grid, path)
	if error != OK:
		push_error("Failed to save map. Error code: %s" % error)
	else:
		print("Map saved: ", path)


func load_map(path: String = "user://saved_map.tres") -> void:
	if grid == null:
		push_error("Cannot load: GridData is missing.")
		return
	if not ResourceLoader.exists(path):
		push_warning("No saved map found at: " + path)
		return

	var loaded := ResourceLoader.load(path) as GridData
	if loaded == null:
		push_error("Could not load the saved file as GridData.")
		return
	if loaded.cost.size() != Config.GRID_W * Config.GRID_H:
		push_error("Saved map has an invalid grid size.")
		return

	grid.cost = loaded.cost.duplicate()
	grid.start_pos = loaded.start_pos
	grid.goal_pos = loaded.goal_pos

	if not GridData.in_bounds(grid.start_pos.x, grid.start_pos.y):
		grid.start_pos = Vector2i(5, 32)
	if not GridData.in_bounds(grid.goal_pos.x, grid.goal_pos.y):
		grid.goal_pos = Vector2i(58, 32)

	# Ensure start and goal are walkable.
	grid.cost[grid.get_index(grid.start_pos.x, grid.start_pos.y)] = GridData.WALKABLE_DEFAULT
	grid.cost[grid.get_index(grid.goal_pos.x, grid.goal_pos.y)] = GridData.WALKABLE_DEFAULT

	grid.grid_reset.emit()
	_last_cell = Vector2i(-1, -1)
	queue_redraw()
	print("Map loaded: ", path)


func _on_grid_reset() -> void:
	_last_cell = Vector2i(-1, -1)
	queue_redraw()


func _draw() -> void:
	if grid == null:
		return

	var tile_size := float(Config.TILE_SIZE)
	var start_local := to_local(grid_renderer.to_global(Vector2(grid.start_pos) * tile_size))
	var goal_local := to_local(grid_renderer.to_global(Vector2(grid.goal_pos) * tile_size))
	var start_rect := Rect2(start_local, Vector2(tile_size, tile_size))
	var goal_rect := Rect2(goal_local, Vector2(tile_size, tile_size))
	draw_rect(start_rect, COLOR_START, true)
	draw_rect(goal_rect, COLOR_GOAL, true)
