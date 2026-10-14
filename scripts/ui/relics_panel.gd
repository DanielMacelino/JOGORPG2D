extends VBoxContainer
## Paginated relic cabinet: list, equipment slots and contextual details, without scrolling.
signal back_requested
const ART := preload("res://scripts/ui/wild_theme.gd")
const HOME := preload("res://scripts/ui/menu/home_screen.gd")
const RECORDS := preload("res://scripts/ui/menu/records_screen.gd")
const COPY := preload("res://scripts/ui/relics_presentation.gd")
const RARITIES := {"common": "COMUM", "uncommon": "INCOMUM", "rare": "RARA", "epic": "ÉPICA", "legendary": "LENDÁRIA"}
var draft: Dictionary = {}
var selected_id := ""
var page_index := 0
var page_size := 6
var section_index := 0
var narrow := false
var compact := false
var slots: GridContainer
var body: HBoxContainer
var list_column: VBoxContainer
var detail_frame: PanelContainer
var section_tabs: HBoxContainer
var card_list: VBoxContainer
var detail_column: VBoxContainer
var pager: HBoxContainer
var count_label: Label
var status_label: Label
var visible_ids: Array[String] = []

func _ready() -> void:
	name = "RelicsPanel"
	size_flags_horizontal = SIZE_EXPAND_FILL
	var extent := get_viewport_rect().size
	compact = extent.y < 600 or (extent.x < 600 and extent.y < 720)
	narrow = extent.x < 850 or compact
	page_size = 2 if compact else (4 if narrow else 6)
	page_index = maxi(0, int(draft.get("page", 0)))
	section_index = clampi(int(draft.get("section", 0)), 0, 1)
	selected_id = str(draft.get("selected", ""))
	if ContentCatalog.get_relic(selected_id).is_empty():
		selected_id = str(ContentCatalog.relics[0].id)
		for relic in ContentCatalog.relics:
			if SaveManager.has_relic(str(relic.id)):
				selected_id = str(relic.id)
				break
	add_theme_constant_override("separation", 4 if compact else 9)
	_build_header()
	_build_slots()
	section_tabs = HBoxContainer.new()
	section_tabs.name = "RelicSections"
	section_tabs.visible = narrow
	add_child(section_tabs)
	for index in 2:
		var tab := _button("RELÍQUIAS" if index == 0 else "DETALHES", false, 28)
		tab.size_flags_horizontal = SIZE_EXPAND_FILL
		tab.pressed.connect(_set_section.bind(index))
		section_tabs.add_child(tab)
	body = HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	add_child(body)
	list_column = VBoxContainer.new()
	list_column.name = "RelicList"
	list_column.size_flags_horizontal = SIZE_EXPAND_FILL
	list_column.size_flags_stretch_ratio = 0.72
	list_column.add_theme_constant_override("separation", 5 if compact else 8)
	body.add_child(list_column)
	count_label = _label("", 12 if compact else 14, ART.GOLD, true)
	list_column.add_child(count_label)
	card_list = VBoxContainer.new()
	card_list.add_theme_constant_override("separation", 5 if compact else 8)
	list_column.add_child(card_list)
	pager = HBoxContainer.new()
	pager.alignment = BoxContainer.ALIGNMENT_CENTER
	list_column.add_child(pager)
	detail_frame = RelicFrame.new()
	detail_frame.name = "RelicDetails"
	detail_frame.size_flags_horizontal = SIZE_EXPAND_FILL
	detail_frame.size_flags_stretch_ratio = 0.28
	detail_frame.size_flags_vertical = SIZE_FILL
	detail_frame.add_theme_stylebox_override("panel", _frame_style(ART.GOLD, 8 if compact else 15))
	body.add_child(detail_frame)
	detail_column = VBoxContainer.new()
	detail_column.add_theme_constant_override("separation", 4 if compact else 8)
	detail_frame.add_child(detail_column)
	_refresh()

func _build_header() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	add_child(row)
	var back := _button("←  VOLTAR", false, 32 if compact else 42)
	back.name = "RelicsBack"
	back.custom_minimum_size.x = 104 if compact else 132
	back.size_flags_vertical = SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: back_requested.emit())
	row.add_child(back)
	var emblem := RECORDS.CompassEmblem.new()
	emblem.custom_minimum_size = Vector2(54, 54)
	emblem.visible = not compact and get_viewport_rect().size.x >= 600
	row.add_child(emblem)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 0)
	row.add_child(titles)
	var title := _label("RELÍQUIAS", 22 if compact else 34, ART.GOLD, true)
	title.name = "RelicsTitle"
	_single_line(title)
	titles.add_child(title)
	var subtitle := _label("Modificadores poderosos que alteram as regras de cada expedição.", 13, ART.TEXT)
	subtitle.visible = not compact
	titles.add_child(subtitle)
	if not compact: add_child(RECORDS.Rule.new())
	var currencies := HFlowContainer.new()
	currencies.add_theme_constant_override("h_separation", 20)
	currencies.add_theme_constant_override("v_separation", 2)
	add_child(currencies)
	for text in ["OURO DE VÉSPERA  %d" % int(SaveManager.data.gold), "CRISTAIS  %d" % int(SaveManager.data.crystals)]:
		var currency := _label(text, 11 if compact else 12, ART.GOLD)
		currency.name = "RelicCurrency" + str(currencies.get_child_count())
		currency.autowrap_mode = TextServer.AUTOWRAP_OFF
		currencies.add_child(currency)

func _build_slots() -> void:
	var frame := RelicFrame.new()
	frame.name = "ActiveRelicSlots"
	frame.add_theme_stylebox_override("panel", _frame_style(ART.GOLD.darkened(0.45), 5 if compact else 8))
	add_child(frame)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	frame.add_child(row)
	var caption := _label("SLOTS ATIVOS", 12, ART.TEXT, true)
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	caption.visible = get_viewport_rect().size.x >= 700 and not compact
	caption.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(caption)
	slots = GridContainer.new()
	slots.name = "RelicSlots"
	slots.columns = 3
	slots.size_flags_horizontal = SIZE_EXPAND_FILL
	slots.add_theme_constant_override("h_separation", 8)
	row.add_child(slots)
	status_label = _label("", 11, ART.MUTED)
	status_label.custom_minimum_size.x = 130
	status_label.visible = not narrow
	status_label.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(status_label)

func _refresh() -> void:
	_refresh_slots()
	_refresh_cards()
	_refresh_detail()
	_apply_section()
	_store()

func _refresh_slots() -> void:
	_clear(slots)
	var equipped: Array = SaveManager.get_equipped_relics()
	for index in 3:
		var id := str(equipped[index]) if index < equipped.size() else ""
		var data: Dictionary = ContentCatalog.get_relic(id)
		var slot := _button(str(data.get("name", "◇  VAZIO")), id == selected_id, 30 if compact else 38)
		slot.name = "RelicSlot%d" % index
		slot.size_flags_horizontal = SIZE_EXPAND_FILL
		slot.custom_minimum_size.x = 0
		slot.clip_text = true
		slot.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		slot.add_theme_font_size_override("font_size", 11 if narrow else 13)
		slot.tooltip_text = str(data.get("name", "Espaço vazio — equipe uma relíquia da coleção."))
		if not id.is_empty():
			slot.icon = COPY.texture(id)
			slot.expand_icon = true
			slot.add_theme_constant_override("icon_max_width", 24)
			slot.pressed.connect(select_relic.bind(id, true))
		else:
			slot.disabled = true
		slots.add_child(slot)
		# OrnateAction applies its defaults in _ready; constrain slot text afterwards.
		slot.clip_text = true
		slot.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_label.text = "%d/3 relíquias equipadas" % equipped.size()

func _refresh_cards() -> void:
	_clear(card_list)
	_clear(pager)
	visible_ids.clear()
	var relics: Array = ContentCatalog.relics
	var pages := maxi(1, ceili(float(relics.size()) / page_size))
	page_index = clampi(page_index, 0, pages - 1)
	var owned_count := 0
	for data in relics:
		if SaveManager.has_relic(str(data.id)): owned_count += 1
	count_label.text = "RELÍQUIAS DISPONÍVEIS   %d/%d" % [owned_count, relics.size()]
	for index in range(page_index * page_size, mini(relics.size(), (page_index + 1) * page_size)):
		var data: Dictionary = relics[index]
		var id := str(data.id)
		visible_ids.append(id)
		var owned: bool = SaveManager.has_relic(id)
		var equipped: bool = SaveManager.is_relic_equipped(id)
		var color := _color(data) if owned else Color("#766e7b")
		var card := RelicFrame.new()
		card.name = "RelicCard_" + id
		card.accent = color
		card.selected = id == selected_id
		card.add_theme_stylebox_override("panel", _frame_style(color, 6, id == selected_id))
		card_list.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8 if compact else 12)
		card.add_child(row)
		var pick := Button.new()
		pick.name = "Select_" + id
		pick.icon = COPY.texture(id, owned)
		pick.expand_icon = true
		pick.custom_minimum_size = Vector2(46 if compact else 52, 46 if compact else 52)
		pick.add_theme_constant_override("icon_max_width", 46 if compact else 52)
		for state in ["normal", "hover", "pressed"]: pick.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		pick.tooltip_text = "Ver relíquia: " + str(data.name) if owned else "Ver condição de desbloqueio"
		pick.pressed.connect(select_relic.bind(id, true))
		row.add_child(pick)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = SIZE_EXPAND_FILL
		info.size_flags_vertical = SIZE_SHRINK_CENTER
		info.add_theme_constant_override("separation", 1 if compact else 3)
		# Clicking the copy selects the card; the equipment action remains independent.
		info.mouse_filter = MOUSE_FILTER_STOP
		info.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				select_relic(id, true))
		info.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		row.add_child(info)
		var heading := HBoxContainer.new()
		info.add_child(heading)
		var title := _label(str(data.name) + ("  ✓" if equipped else "") if owned else "Relíquia desconhecida", 15 if compact else 17, ART.TEXT if owned else ART.GOLD, true)
		_single_line(title)
		title.size_flags_horizontal = SIZE_EXPAND_FILL
		title.tooltip_text = str(data.name) if owned else "Complete a conquista para revelar esta relíquia."
		heading.add_child(title)
		if owned and not compact and not narrow: heading.add_child(_badge(str(data.rarity), color))
		var description := _label(str(data.desc) if owned else "Desbloqueie completando conquistas e derrotando chefes.", 11 if compact else 12, ART.TEXT if owned else ART.MUTED)
		description.max_lines_visible = 2
		description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		info.add_child(description)
		if not compact:
			var condition := _label(_condition(data) if owned else "Selecione para consultar a conquista.", 11, ART.MUTED)
			_single_line(condition)
			info.add_child(condition)
		var action := _button("REMOVER" if equipped else ("EQUIPAR" if owned else "VER"), owned and not equipped, 30 if compact else 36)
		action.name = "RelicAction_" + id
		action.custom_minimum_size.x = 72 if narrow else 94
		action.size_flags_vertical = SIZE_SHRINK_CENTER
		action.add_theme_font_size_override("font_size", 11 if narrow else 12)
		if owned:
			action.disabled = not equipped and SaveManager.get_equipped_relics().size() >= 3
			action.tooltip_text = "Remova uma relíquia ativa para liberar um espaço." if action.disabled else ""
			action.pressed.connect(toggle_relic.bind(id))
		else:
			action.pressed.connect(select_relic.bind(id, true))
		row.add_child(action)
	var previous := _button("←", false, 26)
	previous.name = "PreviousRelics"
	previous.disabled = page_index == 0
	previous.pressed.connect(_change_page.bind(-1))
	pager.add_child(previous)
	var page_label := _label("%d / %d" % [page_index + 1, pages], 12, ART.MUTED)
	page_label.custom_minimum_size.x = 65
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.size_flags_vertical = SIZE_SHRINK_CENTER
	pager.add_child(page_label)
	var next := _button("→", false, 26)
	next.name = "NextRelics"
	next.disabled = page_index >= pages - 1
	next.pressed.connect(_change_page.bind(1))
	pager.add_child(next)

func _refresh_detail() -> void:
	_clear(detail_column)
	var data: Dictionary = ContentCatalog.get_relic(selected_id)
	if data.is_empty(): return
	var owned: bool = SaveManager.has_relic(selected_id)
	var equipped: bool = SaveManager.is_relic_equipped(selected_id)
	var color := _color(data) if owned else Color("#9987a7")
	var stage := RelicStage.new()
	stage.name = "RelicIllustration"
	stage.texture = COPY.texture(selected_id, owned)
	stage.accent = color
	stage.custom_minimum_size.y = 50 if compact else (130 if narrow else 150)
	detail_column.add_child(stage)
	var heading := HBoxContainer.new()
	detail_column.add_child(heading)
	var title := _label(str(data.name) if owned else "Relíquia desconhecida", 18 if compact else 23, ART.TEXT, true)
	title.name = "SelectedRelicTitle"
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	title.max_lines_visible = 2
	heading.add_child(title)
	if owned: heading.add_child(_badge(str(data.rarity), color))
	var description := _label(str(data.desc) if owned else "Um poder ainda oculto. Complete a conquista abaixo para revelar esta relíquia.", 12 if compact else 13, ART.TEXT)
	description.name = "SelectedRelicDescription"
	detail_column.add_child(description)
	var condition := _label(_condition(data), 11 if compact else 12, ART.GOLD)
	condition.name = "RelicUnlockCondition"
	detail_column.add_child(condition)
	if not owned:
		var achievement: Dictionary = ContentCatalog.get_achievement(str(data.get("unlock", "")))
		detail_column.add_child(_label(str(achievement.get("desc", "Complete conquistas durante as expedições.")), 12, ART.MUTED))
	elif not compact:
		detail_column.add_child(RECORDS.Rule.new())
		detail_column.add_child(_label("EFEITOS", 12, ART.GOLD, true))
		for effect in COPY.EFFECTS.get(selected_id, []):
			detail_column.add_child(_label("◇  " + str(effect), 12, ART.TEXT))
	if not compact:
		detail_column.add_child(RECORDS.Rule.new())
		var quote := _label("“%s”" % str(COPY.QUOTES.get(selected_id, "")) if owned else "Cada conquista abre um novo caminho.", 12, ART.GOLD, true)
		quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail_column.add_child(quote)
	var space := Control.new()
	space.size_flags_vertical = SIZE_EXPAND_FILL
	detail_column.add_child(space)
	var action_text := "REMOVER RELÍQUIA" if equipped else ("EQUIPAR" if owned else "BLOQUEADA")
	var full: bool = not equipped and SaveManager.get_equipped_relics().size() >= 3
	if owned and full: action_text = "3/3 ESPAÇOS OCUPADOS"
	var action := _button(action_text, owned and not equipped, 32 if compact else 40)
	action.name = "SelectedRelicAction"
	action.disabled = not owned or full
	action.tooltip_text = "Remova uma relíquia ativa para liberar um espaço." if full else ""
	action.pressed.connect(toggle_relic.bind(selected_id))
	detail_column.add_child(action)

func select_relic(id: String, show_detail: bool = false) -> void:
	if ContentCatalog.get_relic(id).is_empty(): return
	selected_id = id
	if show_detail and narrow: section_index = 1
	_refresh()

func toggle_relic(id: String) -> void:
	if not SaveManager.has_relic(id): return
	selected_id = id
	if SaveManager.is_relic_equipped(id):
		SaveManager.unequip_relic(id)
	else:
		SaveManager.equip_relic(id)
	_refresh()

func _change_page(delta: int) -> void:
	page_index += delta
	_refresh_cards()
	_store()

func _set_section(index: int) -> void:
	section_index = index
	_apply_section()
	_store()

func _apply_section() -> void:
	list_column.visible = not narrow or section_index == 0
	detail_frame.visible = not narrow or section_index == 1
	for index in section_tabs.get_child_count():
		section_tabs.get_child(index).modulate = Color.WHITE if index == section_index else Color("#a1aaa2")

func _store() -> void:
	draft.selected = selected_id
	draft.page = page_index
	draft.section = section_index

func _condition(data: Dictionary) -> String:
	var achievement: Dictionary = ContentCatalog.get_achievement(str(data.get("unlock", "")))
	return "Conquista: " + str(achievement.get("title", "Exploração")).capitalize()

func _color(data: Dictionary) -> Color:
	return ART.RARITY_COLORS.get(str(data.get("rarity", "common")), ART.GOLD)

func _badge(rarity: String, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = SIZE_SHRINK_CENTER
	var style := ART.panel(Color(color, 0.07), 5)
	style.border_color = Color(color, 0.65)
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	panel.add_theme_stylebox_override("panel", style)
	var label := _label(str(RARITIES.get(rarity, rarity.to_upper())), 10, color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	panel.add_child(label)
	return panel

func _button(text: String, primary: bool, height: float) -> Button:
	var button := HOME.OrnateAction.new()
	button.text = text
	button.primary = primary
	button.action_font_size = 12
	button.custom_minimum_size.y = height
	return button

func _label(text: String, pixels: int, color: Color, serif: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", ART.title_font() if serif else ART.body_font())
	label.add_theme_font_size_override("font_size", pixels)
	label.add_theme_color_override("font_color", color)
	return label

func _single_line(label: Label) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

func _frame_style(color: Color, margin: float, active: bool = false) -> StyleBoxFlat:
	var style := ART.panel(Color("#061411", 0.95).lerp(Color(color.darkened(0.83), 0.96), 0.7 if active else 0.25), margin)
	style.border_color = color if active else Color(color, 0.55)
	style.set_border_width_all(2 if active else 1)
	style.set_corner_radius_all(2)
	if active:
		style.shadow_color = Color(color, 0.18)
		style.shadow_size = 6
	return style

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

class RelicFrame extends PanelContainer:
	var accent := ART.GOLD
	var selected := false
	func _draw() -> void:
		var ink := Color(accent, 0.9 if selected else 0.65)
		for corner in [Vector2(3, 3), Vector2(size.x - 3, 3), Vector2(size.x - 3, size.y - 3), Vector2(3, size.y - 3)]:
			var axis := Vector2(1 if corner.x < size.x * 0.5 else -1, 1 if corner.y < size.y * 0.5 else -1)
			draw_polyline(PackedVector2Array([corner + Vector2(0, axis.y * 13), corner, corner + Vector2(axis.x * 13, 0), corner + axis * 5, corner]), ink, 1, true)
		if selected:
			draw_line(Vector2(20, 3), Vector2(size.x - 20, 3), Color(accent, 0.4), 1, true)

class RelicStage extends Control:
	var texture: Texture2D
	var accent := ART.GOLD
	var clock := 0.0
	func _ready() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _process(delta: float) -> void:
		clock += delta
		queue_redraw()
	func _draw() -> void:
		var center := Vector2(size.x * 0.5, size.y * 0.48)
		var radius := minf(size.x * 0.38, size.y * 0.5)
		if size.y > 80:
			var base := Vector2(center.x, size.y - 12)
			var extent := minf(size.x * 0.38, 110)
			draw_colored_polygon(PackedVector2Array([base + Vector2(-extent, -9), base + Vector2(-extent * 0.72, -21), base + Vector2(extent * 0.72, -21), base + Vector2(extent, -9), base + Vector2(extent * 0.86, 6), base + Vector2(-extent * 0.86, 6)]), Color("#293533"))
			draw_line(base + Vector2(-extent, -9), base + Vector2(extent, -9), Color("#657063"), 1, true)
			draw_line(base + Vector2(-extent * 0.72, -21), base + Vector2(extent * 0.72, -21), Color(accent, 0.25), 1, true)
		for index in range(6, 0, -1):
			draw_circle(center, radius * (0.5 + index * 0.13), Color(accent, 0.009), true, -1, true)
		if texture != null:
			var diameter := minf(size.x * 0.8, size.y * 1.04)
			draw_texture_rect(texture, Rect2(center - Vector2.ONE * diameter * 0.5 + Vector2(0, sin(clock * 1.5) * 2), Vector2.ONE * diameter), false)
		if size.y > 80:
			for index in 7:
				var t := fposmod(clock * 0.12 + index * 0.143, 1.0)
				var x := center.x + sin(index * 9.1) * radius
				draw_circle(Vector2(x, size.y * (1 - t)), 1, Color(accent, sin(t * PI) * 0.65), true, -1, true)
