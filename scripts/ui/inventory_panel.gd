extends VBoxContainer
## Arsenal composition, owned-item filters and equipment updates without rebuilding the page.
signal filter_changed(slot: String)
signal forge_requested
signal back_requested
const ART := preload("res://scripts/ui/wild_theme.gd")
const ORBIT := preload("res://scripts/ui/equipment_orbit.gd")
const HOME := preload("res://scripts/ui/menu/home_screen.gd")
const RECORDS := preload("res://scripts/ui/menu/records_screen.gd")
const ICON := preload("res://scripts/ui/equipment_icon.gd")
const FILTER_SLOTS := ["", "weapon", "helmet", "armor", "boots", "ring", "amulet"]
const FILTER_NAMES := ["Todos", "Armas", "Elmos", "Armaduras", "Botas", "Anéis", "Amuletos"]
const RARITY_NAMES := {"common": "COMUM", "uncommon": "INCOMUM", "rare": "RARA", "epic": "ÉPICA", "legendary": "LENDÁRIA", "demigod": "SEMIDEUS", "divine": "DEUS"}
var class_id := "warrior"
var selected_slot := ""
var body: BoxContainer
var hero_column: VBoxContainer
var inventory_column: VBoxContainer
var divider: VSeparator
var orbit: Control
var filter_dropdown: OptionButton
var count_label: Label
var item_scroll: Control
var page_index := 0
var page_size := 3
var previous_page: Button
var next_page: Button
var page_label: Label
var section_row: HBoxContainer
var section_index := 0
var hero_frame: PanelContainer
var inventory_frame: PanelContainer
var item_list: VBoxContainer
var visible_item_ids: Array[String] = []
var compact_rows := false

func _ready() -> void:
	name = "InventoryPanel"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	_build_header()
	_build_sections()
	var frame := ArsenalFrame.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var surface := ART.panel(Color("#10221e", 0.95), 12)
	surface.border_color = Color("#6a714d")
	frame.add_theme_stylebox_override("panel", surface)
	add_child(frame)
	body = BoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.add_child(body)
	hero_column = VBoxContainer.new()
	hero_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_column.size_flags_stretch_ratio = 0.48
	hero_column.add_theme_constant_override("separation", 8)
	hero_frame = ArsenalFrame.new()
	hero_frame.size_flags_horizontal = SIZE_EXPAND_FILL
	hero_frame.size_flags_stretch_ratio = 0.48
	hero_frame.add_theme_stylebox_override("panel", ART.panel(Color("#071410", 0.96), 8))
	body.add_child(hero_frame)
	hero_frame.add_child(hero_column)
	var equipment_title := _label("EQUIPAMENTO", 16, ART.TEXT)
	equipment_title.add_theme_font_override("font", ART.title_font())
	equipment_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_column.add_child(equipment_title)
	var tab_line := HSeparator.new()
	var line := StyleBoxLine.new()
	line.color = Color(ART.GOLD, 0.6)
	line.thickness = 1
	tab_line.add_theme_stylebox_override("separator", line)
	hero_column.add_child(tab_line)
	orbit = ORBIT.new()
	orbit.class_id = class_id
	orbit.selected_slot = selected_slot
	orbit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	orbit.slot_pressed.connect(select_filter)
	hero_column.add_child(orbit)
	var inscription := _label("Cada peça carrega uma história.", 12, ART.MUTED)
	inscription.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inscription.add_theme_font_override("font", ART.title_font())
	hero_column.add_child(inscription)
	divider = VSeparator.new()
	body.add_child(divider)
	inventory_column = VBoxContainer.new()
	inventory_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_column.size_flags_stretch_ratio = 0.56
	inventory_column.add_theme_constant_override("separation", 10)
	inventory_frame = ArsenalFrame.new()
	inventory_frame.size_flags_horizontal = SIZE_EXPAND_FILL
	inventory_frame.size_flags_stretch_ratio = 0.52
	inventory_frame.add_theme_stylebox_override("panel", ART.panel(Color("#071410", 0.96), 10))
	body.add_child(inventory_frame)
	inventory_frame.add_child(inventory_column)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	inventory_column.add_child(heading)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 0)
	heading.add_child(title_box)
	var title := _label("Inventário", 23, ART.TEXT)
	title.add_theme_font_override("font", ART.title_font())
	title_box.add_child(title)
	count_label = _label("", 11, ART.GOLD)
	title_box.add_child(count_label)
	filter_dropdown = OptionButton.new()
	filter_dropdown.name = "InventoryFilter"
	filter_dropdown.custom_minimum_size = Vector2(140, 38)
	filter_dropdown.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	filter_dropdown.fit_to_longest_item = false
	filter_dropdown.tooltip_text = "Filtrar os itens do personagem por espaço de equipamento."
	for category in FILTER_NAMES:
		filter_dropdown.add_item(category)
	filter_dropdown.select(maxi(0, FILTER_SLOTS.find(selected_slot)))
	filter_dropdown.item_selected.connect(_filter_index_selected)
	heading.add_child(filter_dropdown)
	item_scroll = PanelContainer.new()
	item_scroll.name = "OwnedItems"
	item_scroll.custom_minimum_size.y = 336
	item_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(item_scroll as PanelContainer).add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	inventory_column.add_child(item_scroll)
	item_list = VBoxContainer.new()
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation", 8)
	item_scroll.add_child(item_list)
	_build_pagination()
	inventory_column.add_child(_label("Clique nos espaços do personagem para filtrar. Use EQUIPAR para trocar o item.", 11, ART.MUTED))
	var forge := _button("IR PARA A FORJA", false)
	forge.pressed.connect(func() -> void: forge_requested.emit())
	inventory_column.add_child(forge)
	resized.connect(_layout)
	_refresh_items()
	_layout()

func _layout() -> void:
	if body == null or size.x < 1.0:
		return
	body.vertical = size.x < 820.0
	divider.visible = not body.vertical
	section_row.visible = body.vertical
	hero_frame.visible = not body.vertical or section_index == 0
	inventory_frame.visible = not body.vertical or section_index == 1
	for index in section_row.get_child_count():
		section_row.get_child(index).disabled = index == section_index
	var narrow := size.x < 460.0
	if narrow != compact_rows:
		compact_rows = narrow
		_refresh_items()

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", roundi(font_size * clampf(float(SaveManager.data.settings.get("ui_scale", 1.0)), 0.85, 1.2)))
	label.add_theme_color_override("font_color", color)
	return label

func _button(value: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 48
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ART.apply_button(button, primary)
	return button

func owned_items() -> Array[EquipmentData]:
	var items: Array[EquipmentData] = []
	var owned := {}
	for id in SaveManager.data.equipment: owned[str(id)] = true
	for key in ContentCatalog.equipment:
		var item: EquipmentData = ContentCatalog.equipment[key]
		if owned.has(str(item.id)) and (item.class_id == &"" or str(item.class_id) == class_id):
			items.append(item)
	items.sort_custom(_sort_items)
	return items

func _sort_items(a: EquipmentData, b: EquipmentData) -> bool:
	var loadout := SaveManager.loadout_for(class_id)
	var a_equipped := str(loadout.get(str(a.slot), "")) == str(a.id)
	var b_equipped := str(loadout.get(str(b.slot), "")) == str(b.id)
	if a_equipped != b_equipped:
		return a_equipped
	var a_slot: int = FILTER_SLOTS.find(str(a.slot))
	var b_slot: int = FILTER_SLOTS.find(str(b.slot))
	return a_slot < b_slot if a_slot != b_slot else a.display_name.naturalnocasecmp_to(b.display_name) < 0

func select_filter(slot: String) -> void:
	if not FILTER_SLOTS.has(slot):
		return
	selected_slot = slot
	filter_dropdown.select(FILTER_SLOTS.find(slot))
	orbit.selected_slot = slot
	orbit.refresh()
	page_index = 0
	if body.vertical: section_index = 1
	_layout()
	_refresh_items()
	filter_changed.emit(slot)

func _filter_index_selected(index: int) -> void:
	select_filter(str(FILTER_SLOTS[index]))

func _refresh_items() -> void:
	if item_list == null:
		return
	for child in item_list.get_children():
		item_list.remove_child(child)
		child.queue_free()
	visible_item_ids.clear()
	var items := owned_items()
	for item in items:
		if not selected_slot.is_empty() and str(item.slot) != selected_slot:
			continue
		visible_item_ids.append(str(item.id))

	var pages := maxi(1, ceili(float(visible_item_ids.size()) / page_size))
	page_index = clampi(page_index, 0, pages - 1)
	for index in range(page_index * page_size, mini(visible_item_ids.size(), (page_index + 1) * page_size)):
		_add_item(ContentCatalog.equipment[visible_item_ids[index]])
	previous_page.disabled = page_index == 0
	next_page.disabled = page_index >= pages - 1
	page_label.text = "%d / %d" % [page_index + 1, pages]
	count_label.text = "%d itens" % items.size() if selected_slot.is_empty() else "%d de %d itens" % [visible_item_ids.size(), items.size()]
	if visible_item_ids.is_empty():
		var empty_box := VBoxContainer.new()
		empty_box.alignment = BoxContainer.ALIGNMENT_CENTER
		empty_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		empty_box.add_theme_constant_override("separation", 12)
		item_list.add_child(empty_box)
		var icon := ICON.new()
		icon.slot = "amulet" if selected_slot.is_empty() else selected_slot
		icon.class_id = class_id
		icon.empty = true
		icon.custom_minimum_size = Vector2(64, 64)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		empty_box.add_child(icon)
		var title := _label("Nenhum item nesta categoria", 16, ART.TEXT)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_box.add_child(title)
		var help := _label("Encontre equipamentos ao subir de nível na expedição, derrotar chefes ou visitar a forja.", 13, ART.MUTED)
		help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_box.add_child(help)

func _add_item(item: EquipmentData) -> void:
	var active := str(SaveManager.loadout_for(class_id).get(str(item.slot), "")) == str(item.id)
	var rarity := str(item.rarity)
	var accent: Color = ART.RARITY_COLORS.get(rarity, ART.GOLD)
	var card := PanelContainer.new()
	card.set_meta("item_id", str(item.id))
	var style := ART.panel(Color("#10281f") if active else Color("#081712"), 10)
	style.border_color = ART.GREEN if active else accent
	style.border_width_left = 2
	card.add_theme_stylebox_override("panel", style)
	item_list.add_child(card)
	var row := BoxContainer.new()
	row.vertical = false
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var item_heading := HBoxContainer.new()
	item_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_heading.add_theme_constant_override("separation", 10)
	row.add_child(item_heading)
	var icon := ICON.new()
	icon.item = item
	icon.class_id = class_id
	icon.framed = true
	icon.custom_minimum_size = Vector2(40, 50) if compact_rows else Vector2(60, 70)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	item_heading.add_child(icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 3)
	item_heading.add_child(copy)
	copy.add_child(_label(item.display_name + ("  ✓" if active else ""), 12 if compact_rows else 16, ART.TEXT))
	copy.add_child(_label("%s · %s%s" % [ORBIT.SLOT_NAMES.get(str(item.slot), str(item.slot).to_upper()), RARITY_NAMES.get(rarity, rarity.to_upper()), " · EQUIPADO" if active else ""], 10, ART.GREEN if active else accent))
	copy.add_child(_label(item.description, 11 if compact_rows else 12, ART.TEXT))
	if item.region_id != &"" and ContentCatalog.maps.has(str(item.region_id)):
		copy.add_child(_label("ACHADO DE " + ContentCatalog.maps[str(item.region_id)].display_name.to_upper(), 9, ART.GOLD))
	var equip := _button("EM USO ✓" if active else "EQUIPAR", not active)
	equip.name = "EquipItem"
	equip.set_meta("item_id", str(item.id))
	equip.custom_minimum_size.x = 64 if compact_rows else 94
	equip.size_flags_horizontal = Control.SIZE_SHRINK_END
	equip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	equip.disabled = active
	equip.pressed.connect(equip_item.bind(str(item.id)))
	row.add_child(equip)

func equip_item(id: String) -> bool:
	var item: EquipmentData = ContentCatalog.equipment.get(id)
	if item == null or not SaveManager.is_class_unlocked(class_id) or not EquipmentManager.equip(str(item.slot), id, class_id):
		return false
	orbit.refresh()
	_refresh_items()
	AudioManager.feedback("talent")
	return true

class ArsenalFrame extends PanelContainer:
	func _draw() -> void:
		var edge := Color("#b4a36b", 0.75)
		for corner in [Vector2(2, 2), Vector2(size.x - 2, 2), Vector2(2, size.y - 2), size - Vector2(2, 2)]:
			var horizontal := 1.0 if corner.x < size.x * 0.5 else -1.0
			var vertical := 1.0 if corner.y < size.y * 0.5 else -1.0
			var points := PackedVector2Array([corner + Vector2(0, vertical * 18), corner + Vector2(0, vertical * 7), corner + Vector2(horizontal * 7, 0), corner + Vector2(horizontal * 18, 0)])
			draw_polyline(points, edge, 1.0, true)

func _build_header() -> void:
	var header := GridContainer.new()
	header.columns = 2 if get_viewport_rect().size.x >= 620 else 1
	header.add_theme_constant_override("h_separation", 18)
	add_child(header)
	var back := HOME.OrnateAction.new()
	back.text = "← VOLTAR"
	back.name = "ArsenalBack"
	back.custom_minimum_size = Vector2(120, 44)
	back.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(text)
	var title := _label("ARSENAL", 30, ART.TEXT)
	title.add_theme_font_override("font", ART.title_font())
	text.add_child(title)
	text.add_child(_label("Vista os achados da expedição. Cada classe guarda seu próprio equipamento.", 12, ART.TEXT))
	add_child(RECORDS.Rule.new())
	var currencies := HFlowContainer.new()
	currencies.add_theme_constant_override("h_separation", 20)
	add_child(currencies)
	for value in ["OURO DE VÉSPERA  %d" % int(SaveManager.data.gold), "CRISTAIS  %d" % int(SaveManager.data.crystals)]:
		var label := _label(value, 12, ART.GOLD)
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		currencies.add_child(label)

func _build_sections() -> void:
	section_row = HBoxContainer.new()
	section_row.add_theme_constant_override("separation", 8)
	add_child(section_row)
	for index in 2:
		var button := _button("PERSONAGEM" if index == 0 else "INVENTÁRIO", false)
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void:
			section_index = index
			_layout())
		section_row.add_child(button)

func _build_pagination() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	inventory_column.add_child(row)
	previous_page = _button("←", false)
	previous_page.name = "InventoryPreviousPage"
	previous_page.custom_minimum_size.x = 48
	previous_page.pressed.connect(_change_page.bind(-1))
	row.add_child(previous_page)
	page_label = _label("", 11, ART.GOLD)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(page_label)
	next_page = _button("→", false)
	next_page.name = "InventoryNextPage"
	next_page.custom_minimum_size.x = 48
	next_page.pressed.connect(_change_page.bind(1))
	row.add_child(next_page)

func _change_page(direction: int) -> void:
	page_index += direction
	_refresh_items()
