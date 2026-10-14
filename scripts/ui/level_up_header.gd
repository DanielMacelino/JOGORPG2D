extends Control
const STYLE := preload("res://scripts/ui/wild_theme.gd")
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	custom_minimum_size.y = 106
	var stack := VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.offset_top = 26
	stack.add_theme_constant_override("separation", 8)
	stack.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(stack)
	var title := Label.new()
	title.text = "A centelha cresce"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", STYLE.title_font())
	title.add_theme_font_size_override("font_size", 27 if get_viewport_rect().size.x >= 520 else 23)
	title.add_theme_color_override("font_color", STYLE.TEXT)
	stack.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Escolha uma melhoria para esta expedição."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", STYLE.MUTED)
	stack.add_child(subtitle)
func _draw() -> void:
	var center := size.x * 0.5
	draw_line(Vector2(center - 54, 12), Vector2(center - 12, 12), STYLE.LINE)
	draw_line(Vector2(center + 12, 12), Vector2(center + 54, 12), STYLE.LINE)
	draw_polyline(PackedVector2Array([Vector2(center, 6), Vector2(center + 5, 12), Vector2(center, 18), Vector2(center - 5, 12), Vector2(center, 6)]), STYLE.GOLD, 1, true)

