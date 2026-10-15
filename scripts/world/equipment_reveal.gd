extends Node2D
## Cosmetic pickup reveal. Equipment is credited atomically before this effect starts.
const ICON := preload("res://scripts/ui/equipment_icon.gd")
const ART := preload("res://scripts/ui/wild_theme.gd")
var item_id := ""
var elapsed := 0.0
var accent := ART.GOLD
var icon: Control

func _ready() -> void:
	var item: EquipmentData = ContentCatalog.equipment.get(item_id)
	if item == null:
		queue_free()
		return
	accent = ART.RARITY_COLORS.get(str(item.rarity), ART.GOLD)
	icon = ICON.new()
	icon.item = item
	icon.size = Vector2(38, 38)
	icon.position = Vector2(-19, -44)
	add_child(icon)
	z_index = 12

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed > 1.6:
		queue_free()
		return
	if is_instance_valid(icon): icon.position.y = -44 - elapsed * 28
	modulate.a = minf(1.0, (1.6 - elapsed) * 2)
	queue_redraw()

func _draw() -> void:
	for index in 3:
		draw_arc(Vector2.ZERO, 10 + elapsed * 22 + index * 6, 0, TAU, 40, Color(accent, 0.45 - index * 0.1), 1.5, true)
	draw_line(Vector2(0, 5), Vector2(0, -80 - elapsed * 10), Color(accent, 0.3), 8, true)
