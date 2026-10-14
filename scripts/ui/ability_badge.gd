extends Control
const ART := preload("res://scripts/ui/wild_theme.gd")
const ICON := preload("res://scripts/ui/ability_art.gd")
var ability_id := ""
var rank := 1
var font: Font
var clock := 0.0
func _ready() -> void:
	font = ART.body_font()
	custom_minimum_size = Vector2(24, 28)
	var data: AbilityData = ContentCatalog.abilities[ability_id]
	tooltip_text = "%s · %s · Nível %d/5" % [data.display_name, {"common":"Básica", "uncommon":"Média", "rare":"Avançada", "epic":"Épica", "legendary":"Lendária", "demigod":"Semideus", "divine":"Deus"}.get(str(data.rarity), "Básica"), rank]
func _process(delta: float) -> void:
	clock += delta
	queue_redraw()
func _draw() -> void:
	var data: AbilityData = ContentCatalog.abilities.get(ability_id)
	if data == null or font == null: return
	var color: Color = ART.RARITY_COLORS.get(str(data.rarity), ART.GOLD)
	var special := data.rarity in [&"epic", &"legendary", &"demigod", &"divine"]
	draw_rect(Rect2(1, 1, 22, 26), Color("#071614", 0.94))
	draw_rect(Rect2(1, 1, 22, 26), Color(color, 0.8 + sin(clock * 2) * 0.15 if special else 0.65), false, 2 if special else 1)
	draw_set_transform(Vector2(12, 11), 0, Vector2.ONE * 0.22)
	ICON.draw_icon(self, data.visual_id(), Vector2.ZERO, color, special)
	draw_set_transform(Vector2.ZERO)
	draw_string(font, Vector2(2, 25), str(rank), HORIZONTAL_ALIGNMENT_CENTER, 20, 8, color)
