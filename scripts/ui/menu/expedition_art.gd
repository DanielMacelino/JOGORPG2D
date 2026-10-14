extends Control
const FOREST := preload("res://assets/art/forest_panorama.svg")
var shade: GradientTexture2D
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	clip_contents = true
	shade = GradientTexture2D.new()
	shade.width = 256
	shade.height = 8
	shade.fill_from = Vector2.ZERO
	shade.fill_to = Vector2.RIGHT
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0, 0.38, 0.80, 1])
	ramp.colors = PackedColorArray([Color("#15211b"), Color("#15211b", 0.96), Color("#15211b", 0), Color("#15211b", 0)])
	shade.gradient = ramp
func _draw() -> void:
	var factor := maxf(size.x * 0.74 / FOREST.get_width(), size.y / FOREST.get_height())
	var extent := FOREST.get_size() * factor
	draw_texture_rect(FOREST, Rect2(Vector2(size.x - extent.x, (size.y - extent.y) * 0.5), extent), false)
	if shade != null:
		draw_texture_rect(shade, Rect2(Vector2.ZERO, size), false)
	draw_rect(Rect2(Vector2.ZERO, size), Color("#687957", 0.38), false, 1)

