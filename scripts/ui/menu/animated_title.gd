extends Control
const STYLE := preload("res://scripts/ui/wild_theme.gd")
var _font: Font
var _body: Font
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_font = STYLE.title_font()
	_body = STYLE.body_font()
func _draw() -> void:
	if _font == null:
		return
	var title_size := 30 if size.x < 400 else 34
	draw_string(_font, Vector2(0, 37), "ASHENWILD", HORIZONTAL_ALIGNMENT_LEFT, size.x, title_size, STYLE.TEXT)
	draw_string(_body, Vector2(2, 58), "R I F T B O U N D   S U R V I V O R S", HORIZONTAL_ALIGNMENT_LEFT, size.x, 10, STYLE.MUTED)

