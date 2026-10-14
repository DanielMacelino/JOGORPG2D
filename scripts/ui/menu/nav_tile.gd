extends Button
const STYLE := preload("res://scripts/ui/wild_theme.gd")
var symbol := ""
var is_featured := false
var page := ""
func setup(title: String, icon_mark: String, featured: bool = false) -> void:
	text = title.capitalize()
	symbol = icon_mark
	is_featured = featured
	custom_minimum_size = Vector2(0, 58)
	alignment = HORIZONTAL_ALIGNMENT_LEFT
func _ready() -> void:
	STYLE.apply_button(self)
	icon = load("res://assets/art/icons/" + page + ".svg")
	expand_icon = true
	add_theme_constant_override("icon_max_width", 22)
	add_theme_constant_override("h_separation", 12)
	add_theme_color_override("icon_normal_color", STYLE.GOLD)
	add_theme_color_override("icon_hover_color", STYLE.TEXT)
	add_theme_font_size_override("font_size", 13)

