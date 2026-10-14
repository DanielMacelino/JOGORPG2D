extends Control
const ART := preload("res://scripts/ui/wild_theme.gd")
const PORTRAITS := preload("res://scripts/ui/menu_portrait.gd").PORTRAITS
var class_id := "warrior"
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
func _draw() -> void:
	var texture: Texture2D = PORTRAITS.get(class_id, PORTRAITS.warrior)
	var frame := ART.panel(Color("#071611"), 0)
	frame.border_color = Color(ART.GOLD, 0.65)
	draw_style_box(frame, Rect2(Vector2.ONE, size - Vector2.ONE * 2))
	var region := Rect2(texture.get_size() * Vector2(0.27, 0.06), texture.get_size() * Vector2(0.46, 0.38))
	draw_texture_rect_region(texture, Rect2(Vector2.ONE * 4, size - Vector2.ONE * 8), region)
