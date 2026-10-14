extends Button
const STYLE := preload("res://scripts/ui/wild_theme.gd")
const ICON_ART := preload("res://scripts/ui/ability_art.gd")
const CARD_ART := preload("res://assets/art/records-background.png")

var ability: AbilityData
var current_rank := 0
var compact_layout := false
var accent := Color("#91cb7a")
var hovered := false
var text_content: VBoxContainer
var fit_to_slot := false
var fit_queued := false
var fitting := false
var text_scale := 1.0
var fitted_size := Vector2.ZERO
var slot_icon := Rect2(12, 12, 40, 40)
var vertical_card := false
var choose_box := Rect2()
var serif_font: Font
var hover_strength := 0.0
var fitted_preference := -1.0

func configure(data: AbilityData, rank: int) -> void:
	ability = data
	current_rank = rank
	accent = STYLE.RARITY_COLORS.get(str(data.rarity), STYLE.GOLD)

func _ready() -> void:
	var width := get_viewport_rect().size.x
	serif_font = STYLE.title_font()
	compact_layout = width < 880.0
	custom_minimum_size.y = 0 if fit_to_slot else (192 if width < 520.0 else 176)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_ALL
	for state in ["normal", "hover", "pressed", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_build_text()
	resized.connect(_fit_text_height)
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	focus_entered.connect(_set_hovered.bind(true))
	focus_exited.connect(_set_hovered.bind(false))

func _build_text() -> void:
	var width := get_viewport_rect().size.x
	var content := VBoxContainer.new()
	text_content = content
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 94 if width < 520.0 else 112
	content.offset_top = 13
	content.offset_right = -25
	content.offset_bottom = -13
	content.add_theme_constant_override("separation", 4 if compact_layout else 6)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	var title_size := (18 if width < 760 else 23) if fit_to_slot else (16 if width < 520.0 else (18 if compact_layout else 19))
	var detail_size := 10 if width < 520.0 else (11 if compact_layout else 12)
	var body_size := 13 if width < 520.0 else (14 if compact_layout else 14)
	var title := _make_label(ability.display_name, title_size, STYLE.TEXT)
	if fit_to_slot: title.add_theme_font_override("font", serif_font)
	content.add_child(title)
	var tag := "NÍVEL %d → %d" % [current_rank, current_rank + 1]
	var scope := "COMPARTILHADA" if ability.class_ids.is_empty() else "DA CLASSE"
	var rarity_line := "◆  %s  ·  %s  ·  %s" % [_rarity_name(str(ability.rarity)).to_upper(), tag, scope]
	if fit_to_slot:
		rarity_line = "%s · %s · %s" % [tag, _rarity_name(str(ability.rarity)), "GERAL" if ability.class_ids.is_empty() else "CLASSE"]
	content.add_child(_make_label(rarity_line, detail_size, accent))
	content.add_child(_make_label(ability.rank_description(current_rank + 1), body_size, STYLE.TEXT))
	content.minimum_size_changed.connect(_fit_text_height)

func _fit_text_height() -> void:
	if fit_to_slot:
		if not fitting and not fit_queued:
			fit_queued = true
			call_deferred("_fit_slot")
		return
	if text_content != null:
		custom_minimum_size.y = maxf(192.0 if get_viewport_rect().size.x < 520.0 else 176.0, text_content.get_combined_minimum_size().y + 26.0)

func _fit_slot() -> void:
	fit_queued = false
	if text_content == null or not is_inside_tree() or is_queued_for_deletion() or size.x <= 0 or size.y <= 0:
		return
	var preferred := clampf(float(SaveManager.data.settings.get("ui_scale", 1)), 0.85, 1.2)
	if fitted_size == size and is_equal_approx(fitted_preference, preferred):
		return
	fitting = true
	var vertical := size.y >= 300 and size.x < 500
	vertical_card = vertical
	var compact := size.y < 170
	var narrow_footer := compact and size.x < 400
	var reserve := 58.0 if vertical else (32.0 if narrow_footer else (0.0 if compact else 42.0))
	var icon_size := clampf(size.y * 0.29, 88, 142) if vertical else clampf(size.y * (0.20 if compact else 0.26), 28, 54)
	slot_icon = Rect2((size.x - icon_size) * 0.5 if vertical else 12, 22 if vertical else (size.y - reserve - icon_size) * 0.5, icon_size, icon_size)
	var left := 16.0 if vertical else icon_size + 24
	var top := icon_size + 36 if vertical else (8.0 if compact else 10.0)
	var available := maxf(1, size.y - top - (8 if compact else 10) - reserve)
	fitted_size = size
	fitted_preference = preferred
	text_content.set_anchors_preset(Control.PRESET_TOP_LEFT)
	text_content.position = Vector2(left, top)
	var text_width := maxf(1, size.x - left - (80 if compact and not narrow_footer else 20))
	text_content.get_child(0).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if vertical else HORIZONTAL_ALIGNMENT_LEFT
	text_content.get_child(1).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if vertical else HORIZONTAL_ALIGNMENT_LEFT
	var lower := 0.35
	var upper := preferred
	for step in 8:
		var candidate := (lower + upper) * 0.5
		var required := _measure_text_height(text_width / candidate)
		if required * candidate <= available: lower = candidate
		else: upper = candidate
	text_scale = lower
	for child in text_content.get_children(): child.size.x = text_width / text_scale
	text_content.scale = Vector2.ONE * text_scale
	var required := _measure_text_height(text_width / text_scale)
	text_content.size = Vector2(text_width / text_scale, required)
	if vertical:
		text_content.position.y = top
	else:
		text_content.position.y = maxf(8 if compact else 10, (size.y - reserve - required * text_scale) * 0.5)
	choose_box = Rect2(size.x - 78, (size.y - 24) * 0.5, 66, 24) if compact else Rect2(18, size.y - 49, size.x - 36, 32)
	if narrow_footer: choose_box = Rect2(12, size.y - 32, size.x - 24, 24)
	fitting = false
	queue_redraw()

func _measure_text_height(width: float) -> float:
	var result := float(text_content.get_theme_constant("separation") * (text_content.get_child_count() - 1))
	for child in text_content.get_children():
		var label := child as Label
		var font: Font = label.get_theme_font("font")
		var pixels: int = label.get_theme_font_size("font_size")
		var extent := font.get_multiline_string_size(label.text, label.horizontal_alignment, width, pixels)
		var lines := maxi(1, roundi(extent.y / maxf(1, font.get_height(pixels))))
		result += extent.y + float(label.get_theme_constant("line_spacing") * (lines - 1)) + 2
	return result
func _make_label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _process(delta: float) -> void:
	var previous_hover := hover_strength
	hover_strength = move_toward(hover_strength, 1.0 if hovered or has_focus() else 0.0, delta * 6)
	if not is_equal_approx(previous_hover, hover_strength): queue_redraw()
	if fit_to_slot:
		_fit_slot()

func _draw() -> void:
	if ability == null:
		return
	if fit_to_slot:
		_draw_choice_card()
		return
	var active := hovered or has_focus()
	var style := STYLE.panel(Color("#24382c") if active else STYLE.SURFACE, 0)
	style.border_color = accent if active else STYLE.LINE
	style.set_border_width_all(2 if str(ability.rarity) in ["epic", "legendary", "demigod", "divine"] else 1)
	if str(ability.rarity) in ["epic", "legendary", "demigod", "divine"]:
		style.bg_color = Color("#251a30") if str(ability.rarity) == "epic" else Color("#302513")
	draw_style_box(style, Rect2(Vector2(1, 1), size - Vector2(2, 2)))
	draw_line(Vector2(2, 10), Vector2(2, size.y - 10), accent, 2, true)
	var icon_size := slot_icon.size.x if fit_to_slot else (62.0 if get_viewport_rect().size.x < 520 else 76.0)
	var icon_box := slot_icon if fit_to_slot else Rect2(16, (size.y - icon_size) * 0.5, icon_size, icon_size)
	draw_style_box(STYLE.panel(Color("#111e18"), 0), icon_box)
	draw_set_transform(icon_box.get_center(), 0, Vector2.ONE * (icon_size / 86.0))
	ICON_ART.draw_icon(self, ability.visual_id(), Vector2.ZERO, accent, hovered)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var x := size.x - 20
	draw_polyline(PackedVector2Array([Vector2(x - 5, size.y * 0.5 - 5), Vector2(x, size.y * 0.5), Vector2(x - 5, size.y * 0.5 + 5)]), STYLE.GOLD if active else STYLE.MUTED, 1.5, true)

func _draw_choice_card() -> void:
	var bounds := Rect2(Vector2.ONE * 3, size - Vector2.ONE * 6)
	var frame := STYLE.panel(Color("#060e10"), 0)
	frame.border_color = accent.lerp(Color.WHITE, hover_strength * 0.25)
	frame.set_border_width_all(2)
	draw_style_box(frame, bounds)
	if vertical_card:
		var art_box := Rect2(7, 7, size.x - 14, size.y * 0.48)
		var crop := Vector2(CARD_ART.get_width() * 0.50, CARD_ART.get_height() * 0.52)
		draw_texture_rect_region(CARD_ART, art_box, Rect2(Vector2(0, CARD_ART.get_height() * 0.22), crop), Color(accent.lightened(0.3), 0.40))
		for index in 20:
			var fraction := float(index) / 19
			draw_rect(Rect2(7, 7 + fraction * art_box.size.y, art_box.size.x, art_box.size.y / 19 + 1), Color("#061210", fraction * 0.95))
	for corner in [Vector2(10, 10), Vector2(size.x - 10, 10), Vector2(10, size.y - 10), size - Vector2(10, 10)]:
		var axis := Vector2(1 if corner.x < size.x * 0.5 else -1, 1 if corner.y < size.y * 0.5 else -1)
		draw_polyline(PackedVector2Array([corner + Vector2(0, axis.y * 16), corner, corner + Vector2(axis.x * 16, 0), corner + axis * 7, corner + Vector2(0, axis.y * 16)]), accent, 1, true)
	var center := slot_icon.get_center()
	var radius := slot_icon.size.x * 0.56
	var diamond := PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0)])
	draw_circle(center, radius, Color(accent, 0.06 + hover_strength * 0.07))
	draw_colored_polygon(diamond, Color("#04100e", 0.90))
	var outline := diamond.duplicate()
	outline.append(diamond[0])
	draw_polyline(outline, accent, 2, true)
	draw_set_transform(center, 0, Vector2.ONE * slot_icon.size.x / 86)
	ICON_ART.draw_icon(self, ability.visual_id(), Vector2.ZERO, accent, hovered)
	draw_set_transform(Vector2.ZERO)
	_draw_metadata_tag()
	if choose_box.size.x <= 0: return
	var cut := 10.0 if choose_box.size.x > 100 else 5.0
	var p := choose_box.position
	var s := choose_box.size
	var shape := PackedVector2Array([p + Vector2(cut, 0), p + Vector2(s.x - cut, 0), p + Vector2(s.x, s.y * 0.5), p + Vector2(s.x - cut, s.y), p + Vector2(cut, s.y), p + Vector2(0, s.y * 0.5)])
	draw_colored_polygon(shape, Color(accent, 0.07 + hover_strength * 0.15))
	var border := shape.duplicate()
	border.append(shape[0])
	draw_polyline(border, accent, 1.5, true)
	var pixels := 15 if choose_box.size.x > 100 else 9
	draw_string(serif_font, p + Vector2(0, s.y * 0.5 + pixels * 0.34), "ESCOLHER", HORIZONTAL_ALIGNMENT_CENTER, s.x, pixels, STYLE.TEXT)

func _draw_metadata_tag() -> void:
	var metadata := text_content.get_child(1) as Label
	var tag_position := text_content.position + metadata.position * text_scale
	var tag_width := text_content.size.x * text_scale
	if metadata.get_line_count() == 1:
		tag_width = minf(tag_width, metadata.get_theme_font("font").get_string_size(metadata.text, HORIZONTAL_ALIGNMENT_LEFT, -1, metadata.get_theme_font_size("font_size")).x * text_scale + 14)
		if vertical_card: tag_position.x += (text_content.size.x * text_scale - tag_width) * 0.5
	var tag := STYLE.panel(Color("#0b171e"), 0)
	tag.border_color = accent
	tag.set_corner_radius_all(1)
	draw_style_box(tag, Rect2(tag_position - Vector2(4, 2), Vector2(tag_width + 8, metadata.size.y * text_scale + 4)))


func _set_hovered(value: bool) -> void:
	hovered = value
	queue_redraw()

func _rarity_name(id: String) -> String:
	return {"common":"BÁSICA", "uncommon":"MÉDIA", "rare":"AVANÇADA", "epic":"ÉPICA", "legendary":"LENDÁRIA", "demigod":"SEMIDEUS", "divine":"DEUS"}.get(id, id.to_upper())

func _rarity_color(id: String) -> Color:
	return STYLE.RARITY_COLORS.get(id, STYLE.GOLD)
