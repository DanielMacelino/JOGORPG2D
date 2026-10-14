extends Button
const STYLE := preload("res://scripts/ui/wild_theme.gd")
var is_primary := false
func _ready() -> void:
	STYLE.apply_button(self, is_primary)
	text = STYLE.clean_text(text)
	add_theme_font_size_override("font_size", roundi(13 * clampf(float(SaveManager.data.settings.get("ui_scale", 1.0)), 0.85, 1.2)))
	mouse_entered.connect(func() -> void:
		if not disabled: create_tween().tween_property(self, "modulate", Color(1.08, 1.08, 1.08), 0.12))
	mouse_exited.connect(func() -> void: create_tween().tween_property(self, "modulate", Color.WHITE, 0.12))

