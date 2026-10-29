extends Node2D
## THROWAWAY smoke test: left-drag blocks cells, right-drag clears them,
## middle-drag paints "mud" (cost 5). Replace with the real brush tool next.

@onready var renderer: GridRenderer = $GridRenderer

var grid := GridData.new()


func _ready() -> void:
	renderer.setup(grid)
	# A wall with a gap, so there's something to look at immediately.
	for x in range(100, 160):
		if x != 130:
			grid.set_blocked(x, 128)
	# A patch of mud to check the cost tinting.
	for y in range(120, 127):
		for x in range(100, 110):
			grid.set_walkable(x, y, 5)


func _process(_delta: float) -> void:
	var c := GridData.world_to_cell(renderer.get_local_mouse_position())
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		grid.set_blocked(c.x, c.y)
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		grid.clear_cell(c.x, c.y)
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		grid.set_walkable(c.x, c.y, 5)
