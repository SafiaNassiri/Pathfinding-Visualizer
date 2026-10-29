class_name CameraController
extends Camera2D

@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.125
@export var max_zoom: float = 4.0
@export var pan_speed: float = 1.0

var _is_panning: bool = false

func _ready() -> void:
	# Automatically center the camera on the middle of the grid
	position = Vector2(Config.WORLD_W, Config.WORLD_H) * 0.5
	# Set a clean initial zoom so the entire grid is in view
	zoom = Vector2(0.8, 0.8)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE or (event.button_index == MOUSE_BUTTON_RIGHT and Input.is_key_pressed(KEY_SHIFT)):
			_is_panning = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_zoom(zoom_speed, get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_zoom(-zoom_speed, get_global_mouse_position())

	elif event is InputEventMouseMotion and _is_panning:
		position -= event.relative * pan_speed / zoom.x

func _adjust_zoom(delta: float, center: Vector2) -> void:
	var old_zoom = zoom.x
	var new_zoom = clamp(old_zoom + delta * old_zoom, min_zoom, max_zoom)
	
	var world_pos_before = center
	zoom = Vector2(new_zoom, new_zoom)
	var world_pos_after = center
	position += (world_pos_before - world_pos_after)
