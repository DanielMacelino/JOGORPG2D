extends Control
const STYLE := preload("res://scripts/ui/wild_theme.gd")
var gold := 0
var crystals := 0
var _font: Font
func _ready() -> void:
	custom_minimum_size = Vector2(196, 38)
	_font = STYLE.body_font()
func update_values(g: int, c: int) -> void:
	gold = g
	crystals = c
	queue_redraw()
func _draw() -> void:
	if _font == null:
		return
	var y := size.y * 0.5
	draw_circle(Vector2(14, y), 5, STYLE.GOLD)
	draw_circle(Vector2(14, y), 2.5, STYLE.INK)
	draw_string(_font, Vector2(29, y + 5), str(gold), HORIZONTAL_ALIGNMENT_LEFT, 66, 14, STYLE.TEXT)
	draw_line(Vector2(97, y - 8), Vector2(97, y + 8), STYLE.LINE)
	draw_polyline(PackedVector2Array([Vector2(117, y - 6), Vector2(122, y), Vector2(117, y + 6), Vector2(112, y), Vector2(117, y - 6)]), STYLE.GREEN, 1.5, true)
	draw_string(_font, Vector2(134, y + 5), str(crystals), HORIZONTAL_ALIGNMENT_LEFT, 60, 14, STYLE.TEXT)

