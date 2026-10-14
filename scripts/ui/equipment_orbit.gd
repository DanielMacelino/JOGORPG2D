extends Control
## Six equipment cards arranged around the class portrait.
signal slot_pressed(slot: String)
const ART := preload("res://scripts/ui/wild_theme.gd")
const ICON := preload("res://scripts/ui/equipment_icon.gd")
const SLOT_ORDER := ["helmet", "weapon", "ring", "boots", "armor", "amulet"]
const SLOT_NAMES := {"weapon": "ARMA", "helmet": "ELMO", "armor": "ARMADURA", "boots": "BOTAS", "ring": "ANEL", "amulet": "AMULETO"}
var class_id := "warrior"
var selected_slot := ""
var portrait: Control
var name_label: Label
var stats_label: Label
const BACKGROUND := preload("res://assets/art/home-portal.png")
var slot_buttons: Dictionary = {}

func _ready() -> void:
	custom_minimum_size = Vector2(240, 450)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait = preload("res://scripts/ui/menu_portrait.gd").new()
	portrait.class_id = class_id
	add_child(portrait)
	name_label = Label.new()
	name_label.text = "%s · Nv %d" % [ContentCatalog.classes[class_id].display_name, TalentManager.character_level(class_id)]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_override("font", ART.title_font())
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", ART.GOLD)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_label)
	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 11)
	stats_label.add_theme_color_override("font_color", ART.TEXT)
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stats_label)
	for slot in SLOT_ORDER:
		var button := SlotCard.new()
		button.slot = slot
		button.class_id = class_id
		button.pressed.connect(_on_slot_pressed.bind(str(slot)))
		add_child(button)
		slot_buttons[slot] = button
	resized.connect(_layout_parts)
	refresh()
	_layout_parts()

func refresh() -> void:
	for slot in slot_buttons:
		var button: SlotCard = slot_buttons[slot]
		button.item = EquipmentManager.equipped_item(class_id, str(slot))
		button.selected = selected_slot == str(slot)
		button.refresh()
	var actor := SurvivorPlayer.new()
	actor.configure(class_id, {})
	stats_label.text = "VIDA  %d\n\nDANO  %d\n\nVEL.  %d\n\nDEFESA  %d" % [roundi(actor.max_health), roundi(actor.damage), roundi(actor.move_speed), roundi(actor.defense)]
	actor.free()
	queue_redraw()

func _layout_parts() -> void:
	if portrait == null or size.x < 1.0:
		return
	var margin := 8.0
	var width := clampf(size.x * 0.22, 65.0, 112.0)
	var hero_width := size.x * 0.44
	portrait.position = Vector2(size.x * 0.245, 18)
	portrait.size = Vector2(hero_width, 315)
	name_label.position = Vector2(size.x * 0.71, 70)
	name_label.size = Vector2(size.x * 0.28 - 4, 70)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.text = "%s\nNv. %d" % [ContentCatalog.classes[class_id].display_name, TalentManager.character_level(class_id)]
	stats_label.position = Vector2(size.x * 0.72, 156)
	stats_label.size = Vector2(size.x * 0.27 - 4, 175)
	var bottom_width := (size.x - margin * 2 - 16) / 3
	var rects := {
		"helmet": Rect2(margin, 8, width, 100),
		"weapon": Rect2(margin, 116, width, 100),
		"ring": Rect2(margin, 224, width, 100),
		"boots": Rect2(margin, 344, bottom_width, 100),
		"armor": Rect2(margin + bottom_width + 8, 344, bottom_width, 100),
		"amulet": Rect2(margin + (bottom_width + 8) * 2, 344, bottom_width, 100)}
	for slot in slot_buttons:
		var button: SlotCard = slot_buttons[slot]
		var bounds: Rect2 = rects[slot]
		button.position = bounds.position
		button.size = bounds.size
		button.set_vertical(true)
	queue_redraw()

func _draw() -> void:
	var crop := Rect2(BACKGROUND.get_width() * 0.28, BACKGROUND.get_height() * 0.08, BACKGROUND.get_width() * 0.55, BACKGROUND.get_height() * 0.86)
	draw_texture_rect_region(BACKGROUND, Rect2(0, 0, size.x, 336), crop, Color(0.55, 0.62, 0.53))
	draw_rect(Rect2(size.x * 0.70, 0, size.x * 0.30, 336), Color("#07130f", 0.8))
	var center := Vector2(size.x * 0.835, 36)
	draw_arc(center, 24, 0, TAU, 32, ART.GOLD, 1, true)
	draw_polyline(PackedVector2Array([center + Vector2(0, -27), center + Vector2(18, 0), center + Vector2(0, 27), center + Vector2(-18, 0), center + Vector2(0, -27)]), ART.GOLD, 1.5, true)
	draw_line(Vector2(8, 336), Vector2(size.x - 8, 336), ART.GOLD, 1, true)

func _on_slot_pressed(slot: String) -> void:
	slot_pressed.emit(slot)

class SlotCard extends Button:
	const PALETTE := preload("res://scripts/ui/wild_theme.gd")
	const ITEM_ICON := preload("res://scripts/ui/equipment_icon.gd")
	var slot := "weapon"
	var class_id := "warrior"
	var item: EquipmentData
	var selected := false
	var box: BoxContainer
	var item_icon: Control
	var copy: VBoxContainer
	var category_label: Label
	var item_label: Label

	func _ready() -> void:
		focus_mode = Control.FOCUS_ALL
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		box = BoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_theme_constant_override("separation", 5)
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		add_child(box)
		item_icon = ITEM_ICON.new()
		item_icon.class_id = class_id
		item_icon.slot = slot
		item_icon.custom_minimum_size = Vector2(32, 32)
		item_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		item_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		box.add_child(item_icon)
		copy = VBoxContainer.new()
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		copy.add_theme_constant_override("separation", 3)
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_child(copy)
		category_label = _label(str(SLOT_NAMES[slot]), 10, PALETTE.GOLD)
		copy.add_child(category_label)
		item_label = _label("", 11, PALETTE.MUTED)
		item_label.max_lines_visible = 2
		item_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		copy.add_child(item_label)
		resized.connect(_layout_card)
		refresh()
		_layout_card()

	func _label(value: String, font_size: int, color: Color) -> Label:
		var label := Label.new()
		label.text = value
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", color)
		return label

	func set_vertical(value: bool) -> void:
		if box == null:
			return
		box.vertical = value
		for label in [category_label, item_label]:
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if value else HORIZONTAL_ALIGNMENT_LEFT
		_layout_card()

	func _layout_card() -> void:
		if box != null:
			box.position = Vector2(7, 5)
			box.size = size - Vector2(14, 14)

	func refresh() -> void:
		if item_icon == null:
			return
		item_icon.item = item
		item_icon.empty = item == null
		item_icon.queue_redraw()
		item_label.text = item.display_name if item != null else "Escolher item"
		item_label.add_theme_color_override("font_color", PALETTE.TEXT if item != null else PALETTE.MUTED)
		tooltip_text = str(SLOT_NAMES[slot]) + " · " + (item.display_name + "\n" + item.description if item != null else "Sem equipamento. Clique para ver os itens deste espaço.")
		var edge: Color = PALETTE.GOLD if selected or item != null else Color("#697556")
		var normal := PALETTE.panel(Color("#1d3028") if selected else Color("#10221e"), 0)
		normal.border_color = edge
		normal.set_border_width_all(2 if selected else 1)
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color("#263b2d")
		hover.border_color = PALETTE.GOLD.lightened(0.18)
		var focus := PALETTE.panel(Color(0, 0, 0, 0), 0)
		focus.border_color = PALETTE.TEXT
		for state in ["normal", "hover", "pressed", "focus"]:
			add_theme_stylebox_override(state, focus if state == "focus" else (normal if state == "normal" else hover))
		queue_redraw()

	func _draw() -> void:
		var color := Color(PALETTE.GOLD, 0.8 if selected or item != null else 0.35)
		for point in [Vector2(4, 4), Vector2(size.x - 4, size.y - 4)]:
			var sign_value := 1.0 if point.x < size.x * 0.5 else -1.0
			draw_line(point, point + Vector2(7 * sign_value, 0), color, 1.0, true)
			draw_line(point, point + Vector2(0, 7 * sign_value), color, 1.0, true)