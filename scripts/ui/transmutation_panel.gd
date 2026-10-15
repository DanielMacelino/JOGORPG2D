extends VBoxContainer
signal back_requested
const ART := preload("res://scripts/ui/wild_theme.gd")
const HOME := preload("res://scripts/ui/menu/home_screen.gd")
const ICON := preload("res://scripts/ui/equipment_icon.gd")
const CABINET := preload("res://scripts/ui/relics_panel.gd")
const RECORDS := preload("res://scripts/ui/menu/records_screen.gd")
var class_id := "warrior"
var draft: Dictionary = {}
var body: VBoxContainer
var back: Button
var tab_buttons: Array[Button] = []
var tabs: GridContainer
var result_popup
var empty_label: Label
var rarity_transition: Label
var panes: BoxContainer
var inputs_frame: PanelContainer
var ritual_frame: PanelContainer
var subnav: HBoxContainer
var item_grid: GridContainer
var inventory_filters: GridContainer
var sockets: Control
var preview_frame: PanelContainer
var preview: VBoxContainer
var status: Label
var chance_label: Label
var progress_label: Label
var progress: ProgressBar
var fuse: Button
var circle: RitualCircle
var page_label: Label
var previous: Button
var next: Button
var selected: Array[String] = []
var eligible: Array[EquipmentData] = []
var page_size := 15
var busy := false
var elapsed := 0.0
var last_result: Dictionary = {}
var compact := false
var milestones_box: VBoxContainer
var milestones_toggle: Button
var auto_select: Button
var wager_panel: Control

func _ready() -> void:
	name = "TransmutationPanel"
	size_flags_horizontal = SIZE_EXPAND_FILL
	compact = get_viewport_rect().size.y < 650
	add_theme_constant_override("separation", 8)
	for pair in [["tab", 0], ["owner", class_id], ["rarity", "common"], ["page", 0], ["pane", 0], ["milestone_page", 0], ["selected", []]]:
		if not draft.has(pair[0]): draft[pair[0]] = pair[1]
	if not SaveManager.is_class_unlocked(str(draft.owner)): draft.owner = class_id
	selected.assign(draft.selected)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	add_child(header)
	back = HOME.OrnateAction.new()
	back.text = "←  VOLTAR"
	back.name = "TransmutationBack"
	back.custom_minimum_size = Vector2(100, 32 if compact else 42)
	back.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back)
	var emblem := RECORDS.CompassEmblem.new()
	emblem.custom_minimum_size = Vector2(54, 54)
	emblem.visible = not compact and get_viewport_rect().size.x >= 700
	header.add_child(emblem)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(titles)
	var heading := _label("TRANSMUTAÇÃO", 20 if compact else 30, ART.GOLD)
	heading.add_theme_font_override("font", ART.title_font())
	heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.clip_text = true
	heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	titles.add_child(heading)
	var subtitle := _label("Combine equipamentos para criar algo ainda mais forte.", 11, ART.TEXT)
	subtitle.visible = not compact
	titles.add_child(subtitle)
	tabs = GridContainer.new()
	tabs.columns = 4
	tabs.add_theme_constant_override("h_separation", 8)
	tabs.add_theme_constant_override("v_separation", 6)
	add_child(tabs)
	for index in 4:
		var button := _button(["FUSÃO", "APOSTA", "TROCAS", "COMO FUNCIONA"][index])
		button.name = ["FusionTab", "WagerTab", "ExchangeTab", "FusionHelpTab"][index]
		button.set_meta("ritual_tab", true)
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.pressed.connect(_tab.bind(index))
		tabs.add_child(button)
		tab_buttons.append(button)
	body = VBoxContainer.new()
	body.size_flags_horizontal = SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	add_child(body)
	compact = get_viewport_rect().size.y < 650
	resized.connect(_layout)
	_render()

func _label(text: String, font_size: int = 12, color: Color = ART.TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", roundi(font_size * clampf(float(SaveManager.data.settings.get("ui_scale", 1.0)), 0.85, 1.2)))
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, primary := false) -> Button:
	var button := RitualAction.new()
	button.text = text
	button.primary = primary
	button.action_font_size = 11 if compact else 12
	button.tight = compact
	button.custom_minimum_size.y = 30 if compact else 38
	button.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	return button

func _frame(parent: Node, title: String) -> VBoxContainer:
	var panel := CABINET.RelicFrame.new()
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	var style := ART.panel(Color("#111315"), 6 if compact else 10)
	style.border_color = Color("#a49678")
	style.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 3 if compact else 7)
	panel.add_child(column)
	column.add_child(_label(title, 12 if compact else 15, Color("#d4c9ac")))
	return column

func _tab(index: int) -> void:
	if busy or is_instance_valid(result_popup): return
	draft.tab = index
	_render()

func _render() -> void:
	add_theme_constant_override("separation", 4 if compact or int(draft.tab) == 1 else 8)
	for node in body.get_children():
		body.remove_child(node)
		node.queue_free()
	panes = null
	wager_panel = null
	milestones_box = null
	milestones_toggle = null
	for index in tab_buttons.size(): tab_buttons[index].disabled = index == int(draft.tab)
	body.add_theme_constant_override("separation", 8)
	if int(draft.tab) == 1:
		draft.owner = str(SaveManager.data.selected_class)
		wager_panel = preload("res://scripts/ui/equipment_wager_panel.gd").new()
		wager_panel.host = self
		wager_panel.draft = draft
		body.add_child(wager_panel)
	elif int(draft.tab) == 2:
		var exchange := preload("res://scripts/ui/equipment_exchange_panel.gd").new()
		exchange.draft = draft
		body.add_child(exchange)
	elif int(draft.tab) == 3:
		_build_help()
	else:
		_build_fusion()
	_layout()
	if bool(SaveManager.data.transmutation.last_result.get("pending", false)):
		last_result = SaveManager.data.transmutation.last_result.duplicate(true)
		_show_result()

func _build_fusion() -> void:
	subnav = HBoxContainer.new()
	subnav.add_theme_constant_override("separation", 8)
	body.add_child(subnav)
	for index in 3:
		var button := _button(["ITENS", "RITUAL", "DETALHES"][index])
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void:
			draft.pane = index
			_layout())
		subnav.add_child(button)
	panes = BoxContainer.new()
	panes.add_theme_constant_override("separation", 12)
	body.add_child(panes)
	var inventory := _frame(panes, "EQUIPAMENTOS DISPONÍVEIS")
	inputs_frame = inventory.get_parent()
	var filters := GridContainer.new()
	inventory_filters = filters
	filters.columns = 3 if get_viewport_rect().size.x >= 560 else 2
	filters.add_theme_constant_override("separation", 8)
	inventory.add_child(filters)
	var owner_picker := OptionButton.new()
	owner_picker.name = "FusionClass"
	owner_picker.fit_to_longest_item = false
	owner_picker.custom_minimum_size = Vector2(90, 30 if compact else 36)
	owner_picker.autowrap_mode = TextServer.AUTOWRAP_OFF
	owner_picker.clip_text = true
	owner_picker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	owner_picker.size_flags_horizontal = SIZE_EXPAND_FILL
	for id in ContentCatalog.CLASS_ORDER:
		if not SaveManager.is_class_unlocked(str(id)): continue
		owner_picker.add_item(ContentCatalog.classes[id].display_name)
		owner_picker.set_item_metadata(owner_picker.item_count - 1, str(id))
		if str(id) == str(draft.owner): owner_picker.select(owner_picker.item_count - 1)
	owner_picker.item_selected.connect(func(index: int) -> void:
		draft.owner = str(owner_picker.get_item_metadata(index))
		_reset_selection()
		_render())
	filters.add_child(owner_picker)
	var rarity_picker := OptionButton.new()
	rarity_picker.name = "FusionRarity"
	rarity_picker.fit_to_longest_item = false
	rarity_picker.custom_minimum_size = Vector2(90, 30 if compact else 36)
	rarity_picker.autowrap_mode = TextServer.AUTOWRAP_OFF
	rarity_picker.clip_text = true
	rarity_picker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	rarity_picker.size_flags_horizontal = SIZE_EXPAND_FILL
	for rarity in ItemTiers.ORDER:
		rarity_picker.add_item(ItemTiers.label(rarity))
		rarity_picker.set_item_metadata(rarity_picker.item_count - 1, rarity)
		if rarity == str(draft.rarity): rarity_picker.select(rarity_picker.item_count - 1)
		rarity_picker.set_item_disabled(rarity_picker.item_count - 1, rarity == ItemTiers.ORDER.back())
	rarity_picker.item_selected.connect(func(index: int) -> void:
		draft.rarity = str(rarity_picker.get_item_metadata(index))
		_reset_selection()
		_render())
	filters.add_child(rarity_picker)
	var category := OptionButton.new()
	category.name = "FusionCategory"
	category.fit_to_longest_item = false
	category.clip_text = true
	category.size_flags_horizontal = SIZE_EXPAND_FILL
	category.custom_minimum_size.y = 30 if compact else 36
	for entry in [["Todos", "all"], ["Armas", "weapon"], ["Armaduras", "armor"], ["Acessórios", "accessories"]]:
		category.add_item(str(entry[0]))
		category.set_item_metadata(category.item_count - 1, entry[1])
		if str(entry[1]) == str(draft.get("category", "all")): category.select(category.item_count - 1)
	category.item_selected.connect(func(index: int) -> void:
		draft.category = str(category.get_item_metadata(index))
		draft.page = 0
		_refresh_inventory())
	filters.add_child(category)
	var caption := _label("Favoritos, equipados e iniciais protegidos.", 11, ART.MUTED)
	caption.max_lines_visible = 1
	inventory.add_child(caption)
	item_grid = GridContainer.new()
	item_grid.name = "FusionItems"
	item_grid.columns = 5
	item_grid.add_theme_constant_override("h_separation", 6)
	item_grid.add_theme_constant_override("v_separation", 6)
	inventory.add_child(item_grid)
	empty_label = _label("Nenhum item livre nesta raridade. Troque o filtro ou obtenha equipamentos nas expedições.", 12, ART.MUTED)
	empty_label.name = "FusionEmptyState"
	empty_label.custom_minimum_size.y = 72
	empty_label.size_flags_horizontal = SIZE_EXPAND_FILL
	inventory.add_child(empty_label)
	var pages := HBoxContainer.new()
	pages.add_theme_constant_override("separation", 8)
	inventory.add_child(pages)
	previous = _button("←")
	previous.name = "FusionPrevious"
	previous.custom_minimum_size.x = 42
	previous.pressed.connect(_page.bind(-1))
	pages.add_child(previous)
	page_label = _label("")
	page_label.size_flags_horizontal = SIZE_EXPAND_FILL
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pages.add_child(page_label)
	next = _button("→")
	next.name = "FusionNext"
	next.custom_minimum_size.x = 42
	next.pressed.connect(_page.bind(1))
	pages.add_child(next)
	var automatic := _button("SELECIONAR 4 MAIS FRACOS", true)
	automatic.name = "FusionAutoSelect"
	automatic.pressed.connect(_auto_select)
	var spacer := Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	inventory.add_child(spacer)
	inventory.size_flags_vertical = SIZE_EXPAND_FILL
	auto_select = automatic
	inventory.add_child(automatic)
	var ritual := _frame(panes, "RITUAL DE FUSÃO")
	ritual_frame = ritual.get_parent()
	circle = RitualCircle.new()
	circle.custom_minimum_size.y = 92 if get_viewport_rect().size.y < 470 else (148 if compact else 190)
	circle.size_flags_vertical = SIZE_EXPAND_FILL
	circle.mouse_filter = MOUSE_FILTER_IGNORE
	ritual.add_child(circle)
	sockets = Control.new()
	sockets.name = "FusionSockets"
	sockets.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	circle.add_child(sockets)
	circle.resized.connect(_position_sockets)
	chance_label = _label("", 14, ART.GOLD)
	chance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chance_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	chance_label.size_flags_horizontal = SIZE_EXPAND_FILL
	ritual.add_child(chance_label)
	rarity_transition = _label("", 12, ART.TEXT)
	rarity_transition.name = "FusionRarityTransition"
	rarity_transition.autowrap_mode = TextServer.AUTOWRAP_OFF
	rarity_transition.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	rarity_transition.clip_text = true
	rarity_transition.size_flags_horizontal = SIZE_EXPAND_FILL
	rarity_transition.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ritual.add_child(rarity_transition)
	progress_label = _label("", 11, ART.TEXT)
	progress_label.visible = get_viewport_rect().size.y >= 470
	ritual.add_child(progress_label)
	progress = ProgressBar.new()
	progress.show_percentage = false
	progress.custom_minimum_size.y = 8
	progress.add_theme_stylebox_override("fill", ART.panel(ART.GOLD, 0))
	ritual.add_child(progress)
	status = _label("", 11, ART.MUTED)
	status.name = "FusionStatus"
	status.max_lines_visible = 1 if compact else 2
	ritual.add_child(status)
	fuse = _button("FUNDIR 4 ITENS", true)
	fuse.name = "PerformFusion"
	fuse.custom_minimum_size.y = 30 if compact else 40
	fuse.pressed.connect(_begin_fusion)
	var actions := HBoxContainer.new()
	ritual.add_child(actions)
	fuse.text = "FUNDIR"
	fuse.size_flags_horizontal = SIZE_EXPAND_FILL
	actions.add_child(fuse)
	var clear := _button("LIMPAR SELEÇÃO")
	clear.text = "LIMPAR"
	clear.size_flags_horizontal = SIZE_EXPAND_FILL
	clear.pressed.connect(func() -> void:
		_reset_selection()
		_refresh_inventory()
		_update_ritual())
	actions.add_child(clear)
	preview = _frame(panes, "EQUIPAMENTO")
	preview_frame = preview.get_parent()
	inputs_frame.size_flags_stretch_ratio = 0.48
	ritual_frame.size_flags_stretch_ratio = 0.28
	preview_frame.size_flags_stretch_ratio = 0.24
	milestones_toggle = _button("RECOMPENSAS GARANTIDAS  ▾")
	milestones_toggle.name = "FusionMilestonesToggle"
	milestones_toggle.pressed.connect(func() -> void:
		draft.show_milestones = not bool(draft.get("show_milestones", false))
		_layout())
	body.add_child(milestones_toggle)
	milestones_box = VBoxContainer.new()
	milestones_box.name = "FusionMilestones"
	body.add_child(milestones_box)
	_build_milestones()
	_refresh_inventory()
	_update_ritual()
	_layout()

func _reset_selection(reset_page: bool = true) -> void:
	selected.clear()
	draft.selected = []
	if reset_page: draft.page = 0

func _page(direction: int) -> void:
	if busy: return
	draft.page = int(draft.page) + direction
	_refresh_inventory()

func _refresh_inventory() -> void:
	eligible = TransmutationRules.eligible_items(SaveManager.data, str(draft.owner), str(draft.rarity))
	var all_eligible := eligible.duplicate()
	var category := str(draft.get("category", "all"))
	if category != "all":
		eligible = eligible.filter(func(item: EquipmentData) -> bool:
			if category == "armor": return str(item.slot) in ["helmet", "armor", "boots"]
			if category == "accessories": return str(item.slot) in ["ring", "amulet"]
			return str(item.slot) == category)
	var allowed := {}
	for item in all_eligible: allowed[str(item.id)] = SaveManager.equipment_quantity(str(item.id))
	var retained: Array[String] = []
	for id in selected:
		if retained.size() < 4 and retained.count(id) < int(allowed.get(id, 0)):
			retained.append(id)
	selected = retained
	draft.selected = selected.duplicate()
	for child in item_grid.get_children():
		item_grid.remove_child(child)
		child.queue_free()
	var pages := maxi(1, ceili(float(eligible.size()) / page_size))
	draft.page = clampi(int(draft.page), 0, pages - 1)
	for index in range(int(draft.page) * page_size, mini(eligible.size(), (int(draft.page) + 1) * page_size)):
		var item := eligible[index]
		var quantity := SaveManager.equipment_quantity(str(item.id))
		var used := selected.count(str(item.id))
		var button := _icon_button(item, 44 if compact else 64)
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.name = "FusionIngredient"
		button.set_meta("item_id", str(item.id))
		button.set_meta("selected_input", used > 0)
		button.disabled = used >= quantity or selected.size() >= 4
		button.tooltip_text = "%s\n%s\nPoder %.1f · Disponíveis: %d\nClique para adicionar uma cópia." % [item.display_name, item.description, item.power_score(), quantity - used]
		var count := _label("%d/%d" % [used, quantity] if used > 0 else "×%d" % quantity, 10, ART.GOLD)
		count.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
		count.offset_top = -17
		count.offset_bottom = 0
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_child(count)
		button.pressed.connect(_select.bind(str(item.id)))
		item_grid.add_child(button)
	empty_label.visible = eligible.is_empty()
	item_grid.visible = not eligible.is_empty()
	page_label.text = "%d / %d · %d tipos" % [int(draft.page) + 1, pages, eligible.size()]
	previous.disabled = int(draft.page) == 0
	next.disabled = int(draft.page) == pages - 1

func _icon_button(item: EquipmentData, side: float) -> Button:
	var button := _button("")
	button.custom_minimum_size = Vector2(side, side + 6)
	var style := ART.panel(Color("#10271f"), 3)
	style.border_color = ART.RARITY_COLORS.get(str(item.rarity), ART.GOLD)
	button.set_meta("item_accent", style.border_color)
	button.add_theme_stylebox_override("normal", style)
	var icon := ICON.new()
	icon.item = item
	icon.class_id = str(draft.owner)
	icon.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	icon.offset_left = 6
	icon.offset_top = 4
	icon.offset_right = -6
	icon.offset_bottom = -8
	button.add_child(icon)
	return button

func _select(id: String) -> void:
	if busy or selected.size() >= 4 or selected.count(id) >= SaveManager.equipment_quantity(id): return
	selected.append(id)
	AudioManager.feedback("socket")
	draft.selected = selected.duplicate()
	if selected.size() == 4: draft.pane = 1
	_refresh_inventory()
	_update_ritual()
	_layout()

func _remove(index: int) -> void:
	if busy: return
	selected.remove_at(index)
	draft.selected = selected.duplicate()
	_refresh_inventory()
	_update_ritual()

func _auto_select() -> void:
	if busy: return
	selected.clear()
	for item in eligible:
		for copy_index in mini(4 - selected.size(), SaveManager.equipment_quantity(str(item.id))):
			selected.append(str(item.id))
		if selected.size() == 4: break
	draft.selected = selected.duplicate()
	if selected.size() == 4: draft.pane = 1
	_refresh_inventory()
	_update_ritual()
	_layout()

func _update_ritual() -> void:
	for child in sockets.get_children():
		sockets.remove_child(child)
		child.queue_free()
	for index in 4:
		var button: Button
		if index < selected.size():
			var item: EquipmentData = ContentCatalog.equipment[selected[index]]
			button = _icon_button(item, 28 if compact else 48)
			button.tooltip_text = item.display_name + "\nClique para retirar da seleção."
			button.pressed.connect(_remove.bind(index))
		else:
			button = _button("+")
			button.custom_minimum_size = Vector2(28, 34) if compact else Vector2(48, 54)
			button.disabled = true
		sockets.add_child(button)
	var rarity := str(draft.rarity)
	var tier := ItemTiers.index(rarity)
	var higher: String = ItemTiers.ORDER[mini(tier + 1, ItemTiers.ORDER.size() - 1)]
	var percent := roundi(TransmutationRules.chance(SaveManager.data, rarity) * 100.0)
	chance_label.text = "%d%% DE CHANCE" % percent
	rarity_transition.text = "%s → %s" % [ItemTiers.label(rarity), ItemTiers.label(higher)]
	var count := int(SaveManager.data.transmutation.attempts.get(rarity, 0))
	var interval := TransmutationRules.milestone_interval(rarity)
	progress.max_value = interval
	progress.value = count % interval
	progress_label.text = "MARCO %d/%d · +1 %s em %d fusões" % [count % interval, interval, ItemTiers.label(higher), interval - count % interval]
	status.text = "%d/4 selecionados. Consome os quatro e entrega um item; sem melhora, mantém a raridade." % selected.size()
	fuse.disabled = selected.size() != 4 or GameManager.run_active or NetworkSession.running
	circle.accent = Color("#67e5dc").lerp(ART.RARITY_COLORS.get(higher, ART.GOLD), 0.25)
	circle.selected_count = selected.size()
	circle.queue_redraw()
	chance_label.tooltip_text = progress_label.text + "\nSem custo de ouro ou cristais."
	call_deferred("_position_sockets")
	_refresh_preview()

func _position_sockets() -> void:
	if not is_instance_valid(circle) or not is_instance_valid(sockets): return
	var radius := Vector2(minf(circle.size.y * 0.42, circle.size.x * 0.27), circle.size.y * 0.28)
	for index in sockets.get_child_count():
		var button: Control = sockets.get_child(index)
		button.size = button.custom_minimum_size
		button.position = circle.size * Vector2(0.5, 0.45) + Vector2.UP.rotated(index * TAU / 4) * radius - button.size * 0.5

func _refresh_preview() -> void:
	if not is_instance_valid(preview): return
	for index in range(preview.get_child_count() - 1, 0, -1):
		var child := preview.get_child(index)
		preview.remove_child(child)
		child.queue_free()
	var id: String = str(selected.back()) if not selected.is_empty() else (str(eligible[0].id) if not eligible.is_empty() else "")
	if id.is_empty():
		preview.add_child(_label("Selecione equipamentos para iniciar o ritual. Favoritos permanecem protegidos.", 12, ART.MUTED))
		return
	var item: EquipmentData = ContentCatalog.equipment[id]
	var icon := ICON.new()
	icon.item = item
	icon.framed = true
	icon.custom_minimum_size.y = 44 if compact else 78
	preview.add_child(icon)
	var title := _label(item.display_name, 14 if compact else 18, ART.TEXT)
	title.add_theme_font_override("font", ART.title_font())
	title.max_lines_visible = 2
	title.tooltip_text = item.display_name
	title.mouse_filter = MOUSE_FILTER_PASS
	preview.add_child(title)
	preview.add_child(_label(ItemTiers.label(str(item.rarity)).to_upper(), 11, ART.RARITY_COLORS.get(str(item.rarity), ART.GOLD)))
	var stats := _label(item.description, 11 if compact else 12, ART.TEXT)
	stats.max_lines_visible = 3 if compact else 5
	stats.tooltip_text = item.description
	stats.mouse_filter = MOUSE_FILTER_PASS
	preview.add_child(stats)
	var forecast := _label("APÓS A FUSÃO", 11, ART.GOLD)
	preview.add_child(forecast)
	var next_tier: String = str(ItemTiers.ORDER[mini(ItemTiers.index(str(draft.rarity)) + 1, ItemTiers.ORDER.size() - 1)])
	var summary := _label("%s com %d%% de chance.\nCaso contrário: %s.\nAtributos sorteados. Sem custo de ouro ou cristais." % [ItemTiers.label(next_tier), roundi(TransmutationRules.chance(SaveManager.data, str(draft.rarity)) * 100), ItemTiers.label(str(draft.rarity))], 11, ART.MUTED)
	summary.max_lines_visible = 3 if compact else 5
	preview.add_child(summary)

func _available_width() -> float:
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor.name == "OnlineViewport" and ancestor is Control:
			return maxf(1.0, ancestor.size.x)
		ancestor = ancestor.get_parent()
	return maxf(1.0, get_viewport_rect().size.x - 48)

func _layout() -> void:
	var width := _available_width()
	if tabs != null: tabs.columns = 4 if width >= 560 else 2
	if panes == null or not is_instance_valid(panes) or item_grid == null or ritual_frame == null: return
	var narrow := width < 720
	var full := width >= 900
	var condensed := width < 720 or get_viewport_rect().size.y < 470
	var milestones_only := condensed and bool(draft.get("show_milestones", false))
	if is_instance_valid(milestones_box): milestones_box.visible = not condensed or milestones_only
	if is_instance_valid(milestones_toggle):
		milestones_toggle.visible = condensed
		milestones_toggle.text = "VOLTAR AO RITUAL  ▴" if milestones_only else "RECOMPENSAS GARANTIDAS  ▾"
	panes.visible = not milestones_only
	if milestones_only:
		subnav.hide()
		return
	var details_only := not full and int(draft.pane) == 2
	panes.vertical = narrow
	subnav.visible = not full
	inputs_frame.visible = not details_only and (not narrow or int(draft.pane) == 0)
	ritual_frame.visible = not details_only and (not narrow or int(draft.pane) == 1)
	preview_frame.visible = full or details_only
	inputs_frame.size_flags_stretch_ratio = 0.46 if full else 0.56
	ritual_frame.size_flags_stretch_ratio = 0.29 if full else 0.44
	preview_frame.size_flags_stretch_ratio = 0.25 if full else 1.0
	for index in subnav.get_child_count():
		var tab: Button = subnav.get_child(index)
		tab.visible = narrow or index != 1
		tab.text = "ITENS E RITUAL" if not narrow and index == 0 else ["ITENS", "RITUAL", "DETALHES"][index]
		var active := index == int(draft.pane) if narrow else (index == 2 if details_only else index == 0)
		tab.disabled = active or busy
	var inventory_width := width if narrow else (width - 24) * inputs_frame.size_flags_stretch_ratio
	inventory_filters.columns = 3 if inventory_width >= 340 else 2
	var cell_width := 52 if compact else 72
	var columns := clampi(floori((inventory_width - 24) / cell_width), 3, 6)
	var target_size := columns * (1 if get_viewport_rect().size.y < 470 else 2)
	item_grid.columns = columns
	if page_size != target_size:
		var first_visible := int(draft.page) * page_size
		page_size = target_size
		# Keep the first visible ingredient on the new page after resizing.
		draft.page = floori(float(first_visible) / target_size)
		_refresh_inventory()

func _begin_fusion() -> void:
	if busy or is_instance_valid(result_popup): return
	var transaction := SaveManager.transmute_equipment(selected, str(draft.owner))
	if not bool(transaction.ok):
		status.text = str(transaction.reason)
		return
	last_result = transaction.result
	busy = true
	elapsed = 0.0
	_block_controls(true)
	status.text = "A centelha está reunindo os fragmentos..."
	circle.animating = true
	AudioManager.feedback("fusion_start")

func _process(delta: float) -> void:
	if not busy: return
	elapsed += delta
	var active_circle: Control = wager_panel.circle if is_instance_valid(wager_panel) else circle
	if is_instance_valid(active_circle):
		active_circle.progress = minf(1.0, elapsed / 1.65)
		active_circle.queue_redraw()
	if elapsed >= 1.65:
		busy = false
		_block_controls(false)
		AudioManager.feedback("fusion_success" if bool(last_result.get("success", false)) else "fusion_fail")
		if is_instance_valid(wager_panel): wager_panel.finish_animation()
		else:
			_reset_selection(false)
			_refresh_inventory()
			_update_ritual()
			_refresh_milestones()
		active_circle.animating = false
		active_circle.progress = 0.0
		_show_result()

func _block_controls(blocked: bool) -> void:
	for field in find_children("*", "LineEdit", true, false):
		if blocked:
			if not field.has_meta("before_ritual_editable"): field.set_meta("before_ritual_editable", field.editable)
			field.editable = false
		elif field.has_meta("before_ritual_editable"):
			field.editable = bool(field.get_meta("before_ritual_editable"))
			field.remove_meta("before_ritual_editable")
	for button in find_children("*", "BaseButton", true, false):
		if blocked:
			if not button.has_meta("before_fusion_modal"):
				button.set_meta("before_fusion_modal", button.disabled)
			button.disabled = true
		elif button.has_meta("before_fusion_modal"):
			button.disabled = bool(button.get_meta("before_fusion_modal"))
			button.remove_meta("before_fusion_modal")

func _show_result() -> void:
	if is_instance_valid(result_popup): return
	_block_controls(true)
	result_popup = preload("res://scripts/ui/transmutation_result_popup.gd").new()
	result_popup.result = last_result.duplicate(true)
	result_popup.dismiss_requested.connect(_dismiss_result)
	add_child(result_popup)

func _dismiss_result() -> void:
	if not is_instance_valid(result_popup): return
	if SaveManager.acknowledge_transmutation() != OK:
		result_popup.show_error("Não foi possível salvar. Tente continuar novamente.")
		return
	result_popup.queue_free()
	result_popup = null
	_block_controls(false)
	_reset_selection(false)
	if panes != null and is_instance_valid(panes):
		_refresh_inventory()
		_update_ritual()
		_refresh_milestones()
	elif is_instance_valid(wager_panel): wager_panel.refresh()

func begin_wager(target: String, sacrifices: Array[String]) -> void:
	if busy or is_instance_valid(result_popup): return
	var transaction := SaveManager.wager_equipment(target, sacrifices, str(SaveManager.data.selected_class))
	if not bool(transaction.ok):
		wager_panel.status.text = str(transaction.reason)
		return
	last_result = transaction.result
	busy = true
	elapsed = 0.0
	_block_controls(true)
	wager_panel.circle.animating = true
	wager_panel.status.text = "O altar está pesando os sacrifícios..."
	AudioManager.feedback("fusion_start")

func create_ritual_circle() -> Control:
	return RitualCircle.new()

func _refresh_milestones() -> void:
	if not is_instance_valid(milestones_box): return
	for child in milestones_box.get_children():
		milestones_box.remove_child(child)
		child.queue_free()
	_build_milestones()

func _build_milestones() -> void:
	milestones_box.add_theme_constant_override("separation", 2)
	milestones_box.add_child(_label("RECOMPENSAS GARANTIDAS · FUSÃO", 12 if compact else 14, ART.GOLD))
	for tier in ItemTiers.ORDER.size() - 1:
		var rarity: String = ItemTiers.ORDER[tier]
		var higher: String = ItemTiers.ORDER[tier + 1]
		var count := int(SaveManager.data.transmutation.attempts.get(rarity, 0))
		var interval := TransmutationRules.milestone_interval(rarity)
		var panel := PanelContainer.new()
		panel.name = "GuaranteedReward_" + rarity
		panel.set_meta("rarity", rarity)
		var style := ART.panel(Color("#0b2018"), 6)
		style.content_margin_top = 0
		style.content_margin_bottom = 0
		style.border_color = ART.RARITY_COLORS[higher]
		panel.add_theme_stylebox_override("panel", style)
		panel.tooltip_text = "A cada %d fusões: +1 %s.\n%d tentativas; %d bônus entregues.\nPróximo em %d fusões. Progresso deste personagem." % [interval, ItemTiers.label(higher), count, floori(float(count) / interval), interval - count % interval]
		milestones_box.add_child(panel)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 1)
		panel.add_child(column)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		column.add_child(row)
		var title := _label("%s → %s" % [ItemTiers.label(rarity), ItemTiers.label(higher)], 11 if compact else 12, ART.TEXT)
		title.name = "MilestoneTitle"
		title.autowrap_mode = TextServer.AUTOWRAP_OFF
		title.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(title)
		var counter := _label("%d/%d · +1" % [count % interval, interval], 12, ART.GOLD)
		counter.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(counter)
		var bar := ProgressBar.new()
		bar.max_value = interval
		bar.value = count % interval
		bar.custom_minimum_size.y = 4
		bar.show_percentage = false
		bar.add_theme_stylebox_override("background", ART.panel(Color("#19332a"), 0))
		bar.add_theme_stylebox_override("fill", ART.panel(ART.RARITY_COLORS[higher], 0))
		column.add_child(bar)

func _build_help() -> void:
	var sections := GridContainer.new()
	sections.columns = 4 if _available_width() >= 560 else 2
	body.add_child(sections)
	var index := clampi(int(draft.get("help_section", 0)), 0, 3)
	for number in 4:
		var button := _button(["FUSÃO", "MARCOS", "APOSTA", "TROCAS"][number])
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.disabled = number == index
		button.pressed.connect(func() -> void: draft.help_section = number; _render())
		sections.add_child(button)
	var entries := [
		["QUATRO FRAGMENTOS, UMA NOVA CHANCE", "Selecione quatro itens da mesma raridade. Se vencer, recebe um da próxima raridade; caso contrário, recebe um da mesma raridade. Não custa ouro ou cristais.", "Falhas somam 2 pontos percentuais à chance, até +15 pontos extras. Favoritos, equipados e armas iniciais ficam protegidos."],
		["RECOMPENSAS GARANTIDAS", "Os seis marcos estão na parte inferior da Fusão. A cada 10/20/30/40/50/60 tentativas da raridade correspondente, você recebe um item extra da próxima raridade.", "Os marcos são repetíveis e pertencem a cada personagem. Apostas não avançam os marcos. Em telas pequenas, toque em Recompensas Garantidas para expandir a lista."],
		["ESCOLHA SEU PRÊMIO", "Escolha um item da classe atual já liberado na Forja. Ofereça de 4 a 12 itens livres, até de raridades diferentes. A quantidade, raridade e poder definem a chance, limitada a 90%.", "Os sacrifícios são consumidos em ambos os resultados. Vitória entrega o prêmio; falha entrega a consolação mostrada antes de apostar: cerca de 25% da venda, mínimo de uma unidade por moeda presente."],
		["TROQUE O QUE NÃO VAI USAR", "Comum rende 15 ouro; Incomum, 40; Raro, 100. Épico rende 1 cristal; Lendário, 3; Semideus, 8; Deus, 20 por unidade.", "Escolha o item e a quantidade antes de confirmar. Favoritos, equipados e armas iniciais ficam protegidos. As quantidades restantes continuam no inventário."]]
	var column := _frame(body, str(entries[index][0]))
	column.add_child(_label(str(entries[index][1]), 12))
	column.add_child(_label(str(entries[index][2]), 12, ART.MUTED))
	column.add_child(_label("Resultados dos rituais são salvos antes da animação e revelados em um pop-up. Reabrir a tela não repete o sorteio.", 11, ART.GOLD))

class RitualAction extends HOME.OrnateAction:
	var tight := false
	func _ready() -> void:
		ART.apply_button(self, primary, ART.body_font())
		add_theme_font_size_override("font_size", action_font_size)
		mouse_default_cursor_shape = CURSOR_POINTING_HAND
		mouse_entered.connect(func() -> void: create_tween().tween_property(self, "modulate", Color(1.06, 1.06, 1.06), 0.15))
		mouse_exited.connect(func() -> void: create_tween().tween_property(self, "modulate", Color.WHITE, 0.15))
		for state in ["normal", "hover", "pressed", "disabled"]:
			var style := get_theme_stylebox(state).duplicate() as StyleBoxFlat
			style.bg_color = Color("#79452d") if primary else Color("#292923")
			style.border_color = Color("#ba9b70") if primary else Color("#8e8876")
			style.set_corner_radius_all(0)
			if state == "hover": style.bg_color = style.bg_color.lightened(0.12)
			elif state == "pressed": style.bg_color = style.bg_color.darkened(0.18)
			elif state == "disabled": style.bg_color = Color("#1c2723")
			if state == "disabled" and has_meta("ritual_tab"):
				style.bg_color = Color("#253e35")
				style.border_color = Color("#c3b38a")
			if tight:
				style.content_margin_top = 3
				style.content_margin_bottom = 3
			if has_meta("item_accent"):
				style.border_color = get_meta("item_accent")
				style.bg_color = Color("#0b2522") if state == "hover" else Color("#071a17")
				if bool(get_meta("selected_input", false)):
					style.set_border_width_all(2)
					style.bg_color = Color("#102d2a").lerp(style.border_color, 0.15)
			add_theme_stylebox_override(state, style)
		for state in ["font_color", "font_hover_color", "font_pressed_color"]:
			add_theme_color_override(state, Color("#f5ead1"))
		if has_meta("ritual_tab"): add_theme_color_override("font_disabled_color", ART.GOLD)
	func _draw() -> void:
		var ink := Color("#c4ac84", 0.65)
		draw_rect(Rect2(3, 3, maxf(0, size.x - 6), maxf(0, size.y - 6)), Color(ink, 0.28), false, 1)
		for corner in [Vector2(2, 2), size - Vector2(2, 2)]:
			var axis := 1 if corner.x < size.x * 0.5 else -1
			draw_polyline(PackedVector2Array([corner + Vector2(0, axis * 9), corner, corner + Vector2(axis * 9, 0), corner + Vector2(axis * 4, axis * 4)]), ink, 1, true)

class RitualCircle extends Control:
	const TABLE := preload("res://assets/art/transmutation-ritual.png")
	var accent := Color("#67e5dc")
	var selected_count := 0
	var progress := 0.0
	var animating := false
	var clock := 0.0
	func _ready() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		texture_filter = TEXTURE_FILTER_LINEAR
		clip_contents = true
	func _process(delta: float) -> void:
		clock += delta
		queue_redraw()
	func _draw() -> void:
		draw_texture_rect(TABLE, Rect2(Vector2.ZERO, size), false, Color("#c4c8ba"))
		var center := size * Vector2(0.5, 0.45)
		var radius := minf(size.y * 0.33, size.x * 0.30)
		var rotation := clock * 0.12 + progress * TAU * 2.0
		draw_circle(center, radius * 0.7, Color(accent, 0.035 + progress * 0.14))
		for ring in 2:
			var angle := rotation * (1.0 if ring == 0 else -1.0)
			draw_arc(center, radius * (1.0 - ring * 0.23), angle, angle + TAU, 64, Color(accent, 0.16 + progress * 0.5), 1, true)
		for index in 4:
			var angle := float(index) * TAU / 4.0 + rotation
			var point := center + Vector2.from_angle(angle) * radius
			draw_circle(point, 4, accent if index < selected_count else Color("#385146"))
			draw_line(point, center, Color(accent, 0.2 + progress * 0.4), 1, true)
		var extent := radius * (0.23 + progress * 0.15)
		for ring in range(5, 0, -1): draw_circle(center, extent * (0.9 + ring * 0.3), Color(accent, 0.025), true, -1, true)
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -extent), center + Vector2(extent * 0.7, 0), center + Vector2(0, extent), center - Vector2(extent * 0.7, 0)]), accent)
		draw_polyline(PackedVector2Array([center + Vector2(0, -extent), center + Vector2(extent * 0.7, 0), center + Vector2(0, extent)]), Color("#b9ffdb"), 1.2, true)
		if animating:
			for index in 20:
				var angle := float(index) * TAU / 20.0 + rotation
				var distance := radius * (1.5 - progress) * (0.7 + float(index % 3) * 0.15)
				draw_circle(center + Vector2.from_angle(angle) * distance, 1.8, Color(accent, 0.8))
		for index in 24:
			var axis := Vector2.from_angle(index * TAU / 24 - clock * 0.07)
			var p := center + axis * radius * 0.9
			draw_line(p, p + axis * (5 if index % 3 == 0 else 2), Color(accent, 0.7), 1, true)
