class_name GridRenderer
extends Node2D

# Modern, high-contrast visual theme
const COLOR_BLOCKED := Color("1e1e2e") # Deep dark navy/charcoal for walls
const COLOR_FLOOR := Color("f1f5f9")   # Clean light slate/white for walkable floor
const COLOR_COSTLY := Color("fbbf24")  # Warm amber/gold for high-cost terrain (mud)
const COLOR_LINES := Color(0, 0, 0, 0.12) # Soft, subtle grid lines

const COST_TINT_RANGE := 9.0
const LINES_MIN_ZOOM := 0.05

@export var grid: GridData

var _image: Image
var _texture: ImageTexture
var _texture_dirty := false
var _palette := PackedColorArray()
var _last_xf := Transform2D()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_palette()
	
	if not grid:
		grid = GridData.new()
	setup(grid)


func setup(p_grid: GridData) -> void:
	grid = p_grid
	_image = Image.create_empty(Config.GRID_W, Config.GRID_H, false, Image.FORMAT_RGBA8)
	_texture = ImageTexture.create_from_image(_image)
	
	if not grid.cell_changed.is_connected(_on_cell_changed):
		grid.cell_changed.connect(_on_cell_changed)
	if not grid.grid_reset.is_connected(redraw_all):
		grid.grid_reset.connect(redraw_all)
		
	redraw_all()


func redraw_all() -> void:
	if grid == null or _image == null:
		return
	for y in Config.GRID_H:
		for x in Config.GRID_W:
			_image.set_pixel(x, y, _palette[grid.get_cost(x, y)])
	_texture_dirty = true


func _on_cell_changed(x: int, y: int) -> void:
	if _image == null:
		return
	_image.set_pixel(x, y, _palette[grid.get_cost(x, y)])
	_texture_dirty = true


func _process(_delta: float) -> void:
	if grid == null or _texture == null:
		return
	if _texture_dirty:
		_texture.update(_image)
		_texture_dirty = false
		queue_redraw()
		
	var xf := get_global_transform_with_canvas()
	if xf != _last_xf:
		_last_xf = xf
		queue_redraw()


func _draw() -> void:
	if _texture == null:
		return
	var world_rect := Rect2(0, 0, Config.WORLD_W, Config.WORLD_H)
	draw_texture_rect(_texture, world_rect, false)
	if show_grid_lines:
		_draw_grid_lines()


var show_grid_lines := true:
	set(value):
		show_grid_lines = value
		queue_redraw()


func _draw_grid_lines() -> void:
	var xf := get_global_transform_with_canvas()
	if xf.get_scale().x < LINES_MIN_ZOOM:
		return
	var visible := xf.affine_inverse() * get_viewport_rect()
	var t := float(Config.TILE_SIZE)
	var x0 := clampi(floori(visible.position.x / t), 0, Config.GRID_W)
	var x1 := clampi(ceili(visible.end.x / t), 0, Config.GRID_W)
	var y0 := clampi(floori(visible.position.y / t), 0, Config.GRID_H)
	var y1 := clampi(ceili(visible.end.y / t), 0, Config.GRID_H)

	var pts := PackedVector2Array()
	for x in range(x0, x1 + 1):
		pts.append(Vector2(x * t, y0 * t))
		pts.append(Vector2(x * t, y1 * t))
	for y in range(y0, y1 + 1):
		pts.append(Vector2(x0 * t, y * t))
		pts.append(Vector2(x1 * t, y * t))
	draw_multiline(pts, COLOR_LINES, -1.0)


func _build_palette() -> void:
	_palette.resize(256)
	_palette[GridData.BLOCKED] = COLOR_BLOCKED
	for c in range(1, 256):
		var t := clampf((c - 1) / COST_TINT_RANGE, 0.0, 1.0)
		_palette[c] = COLOR_FLOOR.lerp(COLOR_COSTLY, t)
