
extends Node2D

@export var renderer: GridRenderer

var grid: GridData
var _last_cell := Vector2i(-1, -1)


func _ready() -> void:
	# Find GridRenderer if it wasn't assigned in the Inspector.
	if renderer == null:
		renderer = get_node_or_null("../GridRenderer") as GridRenderer

	if renderer == null:
		push_error("SandboxSmokeTest: GridRenderer was not found.")
		set_process(false)
		return

	# Reuse the grid already used by the renderer, if possible.
	grid = renderer.grid

	if grid == null:
		grid = GridData.new()
		renderer.setup(grid)

	# Create a wall with a gap inside the 64 x 64 grid.
	for x in range(10, 50):
		if x != 30:
			grid.set_blocked(x, 32)

	# Add a small patch of costly terrain.
	for y in range(20, 25):
		for x in range(10, 15):
			grid.set_walkable(x, y, 5)


func _process(_delta: float) -> void:
	if grid == null or renderer == null:
		return

	# Convert the mouse position into the renderer's local coordinates.
	var mouse_world: Vector2 = get_global_mouse_position()
	var mouse_local: Vector2 = renderer.to_local(mouse_world)
	var cell: Vector2i = GridData.world_to_cell(mouse_local)

	if not GridData.in_bounds(cell.x, cell.y):
		_last_cell = Vector2i(-1, -1)
		return

	# Only edit a cell once until the mouse moves to another cell.
	if cell == _last_cell:
		return

	var editing := false

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		grid.set_blocked(cell.x, cell.y)
		editing = true
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		grid.clear_cell(cell.x, cell.y)
		editing = true
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		grid.set_walkable(cell.x, cell.y, 5)
		editing = true

	if editing:
		_last_cell = cell
