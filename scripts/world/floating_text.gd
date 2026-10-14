extends Node2D

var text := ""
var color := Color.WHITE
var lifetime := 0.62
var elapsed := 0.0

func _process(delta: float) -> void:
	elapsed += delta
	position.y -= 30.0 * delta
	queue_redraw()
	if elapsed >= lifetime:
		queue_free()

func _draw() -> void:
	var alpha := clampf(1.0 - elapsed / lifetime, 0.0, 1.0)
	var font := ThemeDB.fallback_font
	var size := 15
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size).x
	draw_string(font, Vector2(-width * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, Color(color, alpha))
