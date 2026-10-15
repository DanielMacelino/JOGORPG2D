extends VBoxContainer
## A desired prize is selected separately from the expendable inventory.
var host: Node
var draft: Dictionary = {}
var character_id := "warrior"
var selected: Array[String] = []
var choices: Array[EquipmentData] = []
var offerable: Array[EquipmentData] = []
var panes: BoxContainer
var inventory: VBoxContainer
var ritual: VBoxContainer
var details: VBoxContainer
var inventory_frame: Control
var ritual_frame: Control
var details_frame: Control
var grid: GridContainer
var navigation: HBoxContainer
var modes: Array[Button] = []
var query: LineEdit
var rarity: OptionButton
var page_label: Label
var previous: Button
var next: Button
var circle: Control
var sockets: Control
var status: Label
var odds: Label
var consolation: Label
var perform: Button
var caption: Label
var page_size := 8

func _ready() -> void:
	name = "EquipmentWagerPanel"
	size_flags_horizontal = SIZE_EXPAND_FILL
	character_id = str(SaveManager.data.selected_class)
	if str(draft.get("wager_owner", character_id)) != character_id:
		draft.wager_target = ""
		draft.wager_inputs = []
	draft.wager_owner = character_id
	for pair in [["wager_mode", "targets"], ["wager_page", 0], ["wager_pane", 0], ["wager_rarity", "all"], ["wager_query", ""], ["wager_inputs", []], ["wager_target", ""]]:
		if not draft.has(pair[0]): draft[pair[0]] = pair[1]
	selected.assign(draft.wager_inputs)
	add_theme_constant_override("separation", 6)
	navigation = HBoxContainer.new()
	add_child(navigation)
	for index in 3:
		var tab: Button = host._button(["ITENS", "RITUAL", "PRÊMIO"][index])
		tab.size_flags_horizontal = SIZE_EXPAND_FILL
		tab.pressed.connect(func() -> void: draft.wager_pane = index; _layout())
		navigation.add_child(tab)
	panes = BoxContainer.new()
	panes.add_theme_constant_override("separation", 10)
	add_child(panes)
	inventory = host._frame(panes, "APOSTA · " + ContentCatalog.classes[character_id].display_name.to_upper())
	inventory_frame = inventory.get_parent()
	var mode_row := HBoxContainer.new()
	inventory.add_child(mode_row)
	for mode in ["targets", "offers"]:
		var button: Button = host._button("ESCOLHER PRÊMIO" if mode == "targets" else "SACRIFÍCIOS")
		button.name = "WagerTargets" if mode == "targets" else "WagerSacrifices"
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void: draft.wager_mode = mode; draft.wager_page = 0; refresh())
		mode_row.add_child(button)
		modes.append(button)
	var filters := HBoxContainer.new()
	inventory.add_child(filters)
	query = LineEdit.new()
	query.name = "WagerSearch"
	query.placeholder_text = "Buscar equipamento..."
	query.text = str(draft.wager_query)
	query.custom_minimum_size = Vector2(70, 30)
	query.size_flags_horizontal = SIZE_EXPAND_FILL
	query.text_changed.connect(func(value: String) -> void: draft.wager_query = value; draft.wager_page = 0; refresh())
	filters.add_child(query)
	rarity = OptionButton.new()
	rarity.name = "WagerRarity"
	rarity.fit_to_longest_item = false
	rarity.clip_text = true
	rarity.autowrap_mode = TextServer.AUTOWRAP_OFF
	rarity.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	rarity.custom_minimum_size = Vector2(98, 30)
	rarity.size_flags_horizontal = SIZE_EXPAND_FILL
	rarity.add_item("Todas")
	rarity.set_item_metadata(0, "all")
	for id in ItemTiers.ORDER:
		rarity.add_item(ItemTiers.label(id))
		rarity.set_item_metadata(rarity.item_count - 1, id)
		if id == str(draft.wager_rarity): rarity.select(rarity.item_count - 1)
	rarity.item_selected.connect(func(index: int) -> void: draft.wager_rarity = str(rarity.get_item_metadata(index)); draft.wager_page = 0; refresh())
	filters.add_child(rarity)
	caption = host._label("", 11, host.ART.MUTED)
	caption.max_lines_visible = 2
	inventory.add_child(caption)
	grid = GridContainer.new()
	grid.name = "WagerItems"
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	inventory.add_child(grid)
	var spacer := Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	inventory.add_child(spacer)
	inventory.size_flags_vertical = SIZE_EXPAND_FILL
	var pages := HBoxContainer.new()
	inventory.add_child(pages)
	previous = host._button("←")
	previous.custom_minimum_size.x = 32
	previous.pressed.connect(_page.bind(-1))
	pages.add_child(previous)
	page_label = host._label("", 11)
	page_label.size_flags_horizontal = SIZE_EXPAND_FILL
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pages.add_child(page_label)
	next = host._button("→")
	next.custom_minimum_size.x = 32
	next.pressed.connect(_page.bind(1))
	pages.add_child(next)
	var automatic: Button = host._button("OFERECER 4 MAIS FRACOS")
	automatic.name = "WagerAutoSelect"
	automatic.pressed.connect(func() -> void:
		selected.clear()
		for item in offerable:
			for copy_index in mini(4 - selected.size(), SaveManager.equipment_quantity(str(item.id))): selected.append(str(item.id))
			if selected.size() == 4: break
		draft.wager_inputs = selected.duplicate()
		draft.wager_mode = "offers"
		refresh())
	inventory.add_child(automatic)
	ritual = host._frame(panes, "RITUAL DA APOSTA")
	ritual_frame = ritual.get_parent()
	circle = host.create_ritual_circle()
	circle.custom_minimum_size.y = 92 if get_viewport_rect().size.y < 470 else (148 if host.compact else 190)
	circle.size_flags_vertical = SIZE_EXPAND_FILL
	ritual.add_child(circle)
	sockets = Control.new()
	sockets.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	sockets.mouse_filter = MOUSE_FILTER_IGNORE
	circle.add_child(sockets)
	circle.resized.connect(_position_sockets)
	odds = host._label("", 15, host.ART.GOLD)
	odds.name = "WagerChance"
	odds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ritual.add_child(odds)
	status = host._label("", 11)
	status.name = "WagerStatus"
	status.max_lines_visible = 3
	ritual.add_child(status)
	consolation = host._label("", 11, host.ART.GOLD)
	consolation.name = "WagerConsolation"
	consolation.max_lines_visible = 3
	ritual.add_child(consolation)
	perform = host._button("APOSTAR", true)
	perform.name = "PerformWager"
	perform.pressed.connect(func() -> void: host.begin_wager(str(draft.wager_target), selected))
	ritual.add_child(perform)
	var clear: Button = host._button("LIMPAR SACRIFÍCIOS")
	clear.pressed.connect(func() -> void: selected.clear(); draft.wager_inputs = []; refresh())
	ritual.add_child(clear)
	details = host._frame(panes, "PRÊMIO DESEJADO")
	details_frame = details.get_parent()
	resized.connect(_layout)
	refresh()
	_layout()

func _page(direction: int) -> void:
	draft.wager_page = int(draft.wager_page) + direction
	refresh()

func choose_target(id: String) -> void:
	if host.busy or not EquipmentWager.target_available(SaveManager.data, id, character_id): return
	draft.wager_target = id
	draft.wager_mode = "offers"
	draft.wager_page = 0
	draft.wager_query = ""
	draft.wager_rarity = "all"
	rarity.select(0)
	query.text = ""
	AudioManager.feedback("socket")
	refresh()

func add_sacrifice(id: String) -> void:
	if host.busy or selected.size() >= EquipmentWager.MAX_INPUTS: return
	if not offerable.any(func(item: EquipmentData) -> bool: return str(item.id) == id): return
	if selected.count(id) >= SaveManager.equipment_quantity(id): return
	selected.append(id)
	draft.wager_inputs = selected.duplicate()
	AudioManager.feedback("socket")
	refresh()

func remove_sacrifice(id: String) -> void:
	if host.busy: return
	selected.erase(id)
	draft.wager_inputs = selected.duplicate()
	refresh()

func refresh() -> void:
	if grid == null: return
	offerable = TransmutationRules.eligible_items(SaveManager.data, character_id, "all")
	var allowed := {}
	for item in offerable: allowed[str(item.id)] = SaveManager.equipment_quantity(str(item.id))
	var retained: Array[String] = []
	for id in selected:
		if retained.count(id) < int(allowed.get(id, 0)): retained.append(id)
	selected = retained
	draft.wager_inputs = selected.duplicate()
	if not str(draft.wager_target).is_empty() and not EquipmentWager.target_available(SaveManager.data, str(draft.wager_target), character_id): draft.wager_target = ""
	var selecting_target := str(draft.wager_mode) == "targets"
	modes[0].disabled = host.busy or selecting_target
	modes[1].disabled = host.busy or not selecting_target
	choices = EquipmentWager.targets(SaveManager.data, character_id) if selecting_target else offerable.duplicate()
	choices = choices.filter(func(item: EquipmentData) -> bool:
		return (str(draft.wager_rarity) == "all" or str(item.rarity) == str(draft.wager_rarity)) and item.display_name.to_lower().contains(str(draft.wager_query).strip_edges().to_lower()))
	caption.text = "Prêmios já liberados na Forja. Escolha o que deseja obter." if selecting_target else "4 a 12 itens. Clique para oferecer; botão direito retira. Favoritos e equipados protegidos."
	for child in grid.get_children(): grid.remove_child(child); child.queue_free()
	var pages := maxi(1, ceili(float(choices.size()) / page_size))
	draft.wager_page = clampi(int(draft.wager_page), 0, pages - 1)
	for index in range(int(draft.wager_page) * page_size, mini(choices.size(), (int(draft.wager_page) + 1) * page_size)):
		var item := choices[index]
		var id := str(item.id)
		var button: Button = host._icon_button(item, 42 if host.compact else 58)
		button.name = "WagerTarget" if selecting_target else "WagerSacrifice"
		button.set_meta("item_id", id)
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.set_meta("selected_input", id == str(draft.wager_target) if selecting_target else selected.has(id))
		button.tooltip_text = "%s\n%s\nPoder %.1f" % [item.display_name, item.description, item.power_score()]
		if selecting_target: button.pressed.connect(choose_target.bind(id))
		else:
			button.disabled = selected.size() >= EquipmentWager.MAX_INPUTS or selected.count(id) >= SaveManager.equipment_quantity(id)
			button.pressed.connect(add_sacrifice.bind(id))
			button.gui_input.connect(func(event: InputEvent) -> void:
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT: remove_sacrifice(id))
			var count: Label = host._label("%d/%d" % [selected.count(id), SaveManager.equipment_quantity(id)], 10, host.ART.GOLD)
			count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			count.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
			count.offset_top = -16
			button.add_child(count)
		grid.add_child(button)
	page_label.text = "%d / %d · %d itens" % [int(draft.wager_page) + 1, pages, choices.size()]
	previous.disabled = int(draft.wager_page) == 0
	next.disabled = int(draft.wager_page) == pages - 1
	_update_offer()

func _update_offer() -> void:
	var offer := EquipmentWager.quote(SaveManager.data, str(draft.wager_target), selected)
	odds.text = "%.1f%% DE CHANCE" % (float(offer.chance) * 100)
	status.text = "%d/12 oferecidos · mínimo 4.\nOs itens oferecidos são consumidos em ambos os resultados." % selected.size()
	consolation.text = "Se falhar: %s.\nConsolação abaixo da venda normal." % _currency(offer.consolation)
	perform.disabled = not EquipmentWager.validate(SaveManager.data, str(draft.wager_target), selected, character_id).is_empty() or GameManager.run_active or NetworkSession.running
	perform.text = "APOSTAR · CONSUMIR %d ITENS" % selected.size()
	for child in sockets.get_children(): sockets.remove_child(child); child.queue_free()
	for index in mini(selected.size(), 4):
		var item: EquipmentData = ContentCatalog.equipment[selected[index]]
		var button: Button = host._icon_button(item, 28 if host.compact else 40)
		button.tooltip_text = item.display_name + "\nClique para retirar uma cópia."
		button.pressed.connect(remove_sacrifice.bind(str(item.id)))
		sockets.add_child(button)
	circle.selected_count = mini(4, selected.size())
	for index in range(details.get_child_count() - 1, 0, -1):
		var child := details.get_child(index)
		details.remove_child(child)
		child.queue_free()
	var target: EquipmentData = ContentCatalog.equipment.get(str(draft.wager_target))
	if target == null: details.add_child(host._label("Selecione um prêmio no catálogo. A chance aumenta conforme o valor e a quantidade dos sacrifícios.", 12))
	else:
		var icon: Control = host.ICON.new()
		icon.item = target
		icon.custom_minimum_size.y = 54 if host.compact else 90
		details.add_child(icon)
		details.add_child(host._label(target.display_name, 14, host.ART.GOLD))
		details.add_child(host._label(ItemTiers.label(str(target.rarity)).to_upper() + " · PODER %.1f" % target.power_score(), 11))
		var stats: Label = host._label(target.description, 11)
		stats.max_lines_visible = 4
		details.add_child(stats)
		details.add_child(host._label("Se vencer: recebe exatamente este equipamento.\nSe falhar: recebe somente a consolação indicada. A aposta não avança os marcos da Fusão.", 11, host.ART.MUTED))
	call_deferred("_position_sockets")

func _currency(value: Dictionary) -> String:
	var parts: Array[String] = []
	if int(value.gold) > 0: parts.append("%d ouro" % value.gold)
	if int(value.crystals) > 0: parts.append("%d cristal(is)" % value.crystals)
	return " + ".join(parts) if not parts.is_empty() else "selecione os sacrifícios"

func _position_sockets() -> void:
	if not is_instance_valid(circle): return
	var radius := Vector2(minf(circle.size.y * 0.42, circle.size.x * 0.27), circle.size.y * 0.28)
	for index in sockets.get_child_count():
		var button: Control = sockets.get_child(index)
		button.size = button.custom_minimum_size
		button.position = circle.size * Vector2(0.5, 0.45) + Vector2.UP.rotated(index * TAU / 4) * radius - button.size * 0.5

func finish_animation() -> void:
	selected.clear()
	draft.wager_inputs = []
	refresh()

func _layout() -> void:
	if panes == null: return
	var width: float = host._available_width()
	var narrow := width < 720
	var full := width >= 900
	var section := int(draft.wager_pane)
	panes.vertical = narrow
	navigation.visible = not full
	inventory_frame.visible = full or (section == 0 if narrow else section != 2)
	ritual_frame.visible = full or (section == 1 if narrow else section != 2)
	details_frame.visible = full or section == 2
	inventory_frame.size_flags_stretch_ratio = 0.46 if full else 0.55
	ritual_frame.size_flags_stretch_ratio = 0.29 if full else 0.45
	details_frame.size_flags_stretch_ratio = 0.25 if full else 1.0
	for index in 3:
		var tab: Button = navigation.get_child(index)
		tab.visible = narrow or index != 1
		tab.text = "ITENS E RITUAL" if not narrow and index == 0 else ["ITENS", "RITUAL", "PRÊMIO"][index]
		tab.disabled = host.busy or (index == section if narrow else (index == 2 if section == 2 else index == 0))
	var available := width if narrow else width * (0.46 if full else 0.55)
	grid.columns = clampi(floori((available - 24) / (52 if host.compact else 68)), 3, 6)
	var count := grid.columns * (1 if get_viewport_rect().size.y < 470 else 2)
	if page_size != count:
		page_size = count
		refresh()
