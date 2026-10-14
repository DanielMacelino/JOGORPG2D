extends Control
const FOREST := preload("res://assets/art/forest_panorama.svg")
const HOME := preload("res://assets/art/home-portal.png")
var home := true
var records := false
var records_art: Texture2D
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
func _draw() -> void:
	if records:
		if records_art == null: records_art = load("res://assets/art/records-background.png")
		if records_art != null:
			var factor := maxf(size.x / records_art.get_width(), size.y / records_art.get_height())
			var extent := records_art.get_size() * factor
			draw_texture_rect(records_art, Rect2((size - extent) * 0.5, extent), false)
			draw_rect(Rect2(Vector2.ZERO, size), Color("#02100e", 0.10 if size.x > 700 else 0.36))
			return
	if home:
		var factor := maxf(size.x / HOME.get_width(), size.y / HOME.get_height())
		var extent := HOME.get_size() * factor
		var origin := (size - extent) * 0.5
		if size.x < 700:
			origin.x = clampf(size.x * 0.72 - extent.x * 0.78, size.x - extent.x, 0)
		draw_texture_rect(HOME, Rect2(origin, extent), false)
		if size.x < 700:
			draw_rect(Rect2(Vector2.ZERO, size), Color("#03100d", 0.48))
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#101a18"))
	var factor := maxf(size.x / FOREST.get_width(), size.y / FOREST.get_height())
	var extent := FOREST.get_size() * factor
	draw_texture_rect(FOREST, Rect2((size - extent) * 0.5, extent), false, Color(0.5, 0.6, 0.5, 0.16))
	draw_rect(Rect2(Vector2.ZERO, size), Color("#0b1412", 0.55))

