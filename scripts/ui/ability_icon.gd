extends Control
const ART := preload("res://scripts/ui/ability_art.gd")
var ability_id := ""
var accent := Color("#c6aa72")
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(44, 44)
func _draw() -> void:
	draw_set_transform(size * 0.5, 0, Vector2.ONE * minf(size.x, size.y) / 84.0)
	var data: AbilityData = ContentCatalog.abilities.get(ability_id)
	ART.draw_icon(self, data.visual_id() if data != null else ability_id, Vector2.ZERO, accent)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
