class_name SandboxController
extends Node2D

@export var grid_renderer: Node2D

enum Tool { PAINT_WALL, ERASE, PAINT_COST, SET_START, SET_GOAL }
var current_tool: Tool = Tool.PAINT_WALL

var grid: GridData
var _last_cell := Vector2i(-1, -1)
var _is_dragging := false

const COLOR_START := Color("4ade80") # Bright green
const COLOR_GOAL := Color("f87171")  # Bright red

func _ready() -> void:
	# 1. Try to find GridRenderer automatically if unassigned
	if not grid_renderer:
		grid_renderer = get_node_or_null("../GridRenderer") as Node2D
		if not grid_renderer:
			grid_renderer = get_node_or_null("GridRenderer") as Node2D
	
	# 2. Fallback: Search children of Main scene if still not found
	if not grid_renderer:
		for child in get_parent().get_children():
			if child.name == "GridRenderer":
				grid_renderer = child as Node2D
				break

	await get_tree().process_frame # Wait one frame for GridRenderer to finish initializing its grid

	if grid_renderer:
		# Access grid safely via property check
		if "grid" in grid_renderer and grid_renderer.grid != null:
			grid = grid_renderer.grid
		else:
			# If the renderer hasn't initialized its grid yet, create a shared one
			grid = GridData.new()
			if "grid" in grid_renderer:
				grid_renderer.grid = grid
				if grid_renderer.has_method("setup"):
					grid_renderer.setup(grid)
	
	if grid == null:
		printerr("SandboxController: GridRenderer or Grid not found!")

func _unhandled_input(event: InputEvent) -> void:
	if grid == null:
		return

	# Tool hotkeys (1-5)
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: current_tool = Tool.PAINT_WALL; print("Tool: Paint Wall")
			KEY_2: current_tool = Tool.ERASE; print("Tool: Erase")
			KEY_3: current_tool = Tool.PAINT_COST; print("Tool: Paint Cost (Mud)")
			KEY_4: current_tool = Tool.SET_START; print("Tool: Set Start")
			KEY_5: current_tool = Tool.SET_GOAL; print("Tool: Set Goal")
			KEY_R: randomize_map(); print("Action: Randomize Map")
			KEY_C: clear_grid(); print("Action: Clear Grid")
			KEY_S: save_map(); print("Action: Save Map")
			KEY_L: load_map(); print("Action: Load Map")

	# Mouse interactions
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_dragging = true
			_apply_tool(get_global_mouse_position())
		else:
			_is_dragging = false
			_last_cell = Vector2i(-1, -1)

	elif event is InputEventMouseMotion and _is_dragging:
		_apply_tool(get_global_mouse_position())

func _apply_tool(world_pos: Vector2) -> void:
	var c := GridData.world_to_cell(world_pos)
	if not GridData.in_bounds(c.x, c.y):
		return
	if c == _last_cell:
		return
	_last_cell = c

	match current_tool:
		Tool.PAINT_WALL:
			if c != grid.start_pos and c != grid.goal_pos:
				grid.set_blocked(c.x, c.y)
		Tool.ERASE:
			if c != grid.start_pos and c != grid.goal_pos:
				grid.clear_cell(c.x, c.y)
		Tool.PAINT_COST:
			if c != grid.start_pos and c != grid.goal_pos:
				grid.set_walkable(c.x, c.y, 10)
		Tool.SET_START:
			if c != grid.goal_pos and grid.is_walkable(c.x, c.y):
				grid.set_start(c.x, c.y)
				queue_redraw()
		Tool.SET_GOAL:
			if c != grid.start_pos and grid.is_walkable(c.x, c.y):
				grid.set_goal(c.x, c.y)
				queue_redraw()

func randomize_map(fill_probability: float = 0.25) -> void:
	if grid == null:
		return
	grid.reset()
	var rng := RandomNumberGenerator.new()
	for y in range(Config.GRID_H):
		for x in range(Config.GRID_W):
			var pos := Vector2i(x, y)
			if pos == grid.start_pos or pos == grid.goal_pos:
				continue
			if rng.randf() < fill_probability:
				grid.set_blocked(x, y)
	if grid_renderer and grid_renderer.has_method("redraw_all"):
		grid_renderer.redraw_all()
	queue_redraw()

func clear_grid() -> void:
	if grid == null:
		return
	grid.reset()
	if grid_renderer and grid_renderer.has_method("redraw_all"):
		grid_renderer.redraw_all()
	queue_redraw()

func save_map(path: String = "user://saved_map.tres") -> void:
	if grid == null:
		return
	ResourceSaver.save(grid, path)
	print("Map saved successfully to: ", path)

func load_map(path: String = "user://saved_map.tres") -> void:
	if ResourceLoader.exists(path):
		var loaded = ResourceLoader.load(path) as GridData
		if loaded and grid:
			grid.cost = loaded.cost
			grid.start_pos = loaded.start_pos
			grid.goal_pos = loaded.goal_pos
			if grid_renderer and grid_renderer.has_method("redraw_all"):
				grid_renderer.redraw_all()
			queue_redraw()
			print("Map loaded successfully from: ", path)
	else:
		print("No saved map found at: ", path)

func _draw() -> void:
	if grid == null:
		return
	
	var t := float(Config.TILE_SIZE)
	var start_rect = Rect2(Vector2(grid.start_pos) * t, Vector2(t, t))
	var goal_rect = Rect2(Vector2(grid.goal_pos) * t, Vector2(t, t))
	
	draw_rect(start_rect, COLOR_START, true)
	draw_rect(goal_rect, COLOR_GOAL, true)
