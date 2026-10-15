extends Control
const ART := preload("res://scripts/ui/wild_theme.gd")
const PORTRAITS := preload("res://scripts/ui/menu_portrait.gd")
var members: Array[Dictionary] = []
var text := ""
var font: Font
func _ready() -> void:
	name = "PartyHUD"
	font = ART.body_font()
	mouse_filter = MOUSE_FILTER_IGNORE
	texture_filter = TEXTURE_FILTER_NEAREST
	set_anchors_preset(PRESET_BOTTOM_LEFT)
	resized.connect(queue_redraw)
	_fit()
func update_members(value: Array[Dictionary]) -> void:
	members = value
	_fit()
	queue_redraw()
func _fit() -> void:
	var screen := get_viewport_rect().size
	var height := 38.0 if screen.y < 500 else 43.0
	offset_left = 10
	offset_right = minf(270, screen.x * 0.48)
	offset_bottom = -14
	offset_top = -14 - maxi(1, members.size()) * (height + 4)
func _draw() -> void:
	if font == null: return
	var height := 38.0 if get_viewport_rect().size.y < 500 else 43.0
	for index in members.size():
		var row: Dictionary = members[index]
		var y := index * (height + 4)
		var style := ART.panel(Color("#061714", 0.92), 0)
		style.border_color = Color(ART.GOLD, 0.45)
		draw_style_box(style, Rect2(0, y, size.x, height))
		var portrait: Texture2D = PORTRAITS.texture_for(str(row.get("class_id", "warrior")), true)
		var extent := portrait.get_size() * minf(30.0 / portrait.get_width(), (height - 4.0) / portrait.get_height())
		draw_texture_rect(portrait, Rect2(Vector2(4, y + 2) + (Vector2(30, height - 4) - extent) * 0.5, extent), false)
		var dead := bool(row.get("dead", false))
		draw_string(font, Vector2(39, y + 14), str(row.get("name", "Viajante")), HORIZONTAL_ALIGNMENT_LEFT, size.x - 44, 11, ART.GOLD)
		var bar := Rect2(39, y + 20, maxf(10, size.x - 47), 6)
		draw_rect(bar, Color("#2d3431"))
		var fraction := float(row.get("revive", 0)) if dead else clampf(float(row.get("health", 0)) / maxf(1, float(row.get("maximum", 1))), 0, 1)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * fraction, bar.size.y)), ART.GOLD if dead else Color("#8cd9ae"))
		var status := "REANIMAR %d%%" % roundi(fraction * 100) if dead else "%d / %d" % [row.get("health", 0), row.get("maximum", 0)]
		draw_string(font, Vector2(39, y + height - 3), status, HORIZONTAL_ALIGNMENT_LEFT, size.x - 44, 9, ART.MUTED)
