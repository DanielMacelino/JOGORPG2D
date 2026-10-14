extends VBoxContainer
signal back_requested
const ART := preload("res://scripts/ui/wild_theme.gd")
const HOME := preload("res://scripts/ui/menu/home_screen.gd")
const ICON := preload("res://scripts/ui/equipment_icon.gd")
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
var sockets: HBoxContainer
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

func _ready() -> void:
	name = "TransmutationPanel"
	size_flags_horizontal = SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 8)
	for pair in [["tab", 0], ["owner", class_id], ["rarity", "common"], ["page", 0], ["pane", 0], ["milestone_page", 0], ["selected", []]]:
		if not draft.has(pair[0]): draft[pair[0]] = pair[1]
	if not SaveManager.is_class_unlocked(str(draft.owner)): draft.owner = class_id
	selected.assign(draft.selected)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	add_child(header)
	back = HOME.OrnateAction.new()
	back.text = "VOLTAR"
	back.name = "TransmutationBack"
	back.custom_minimum_size = Vector2(100, 42)
	back.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(titles)
	titles.add_child(_label("TRANSMUTAÇÃO", 25, ART.GOLD))
	titles.add_child(_label("Dê um novo destino aos equipamentos que ficaram para trás.", 11, ART.MUTED))
	tabs = GridContainer.new()
	tabs.columns = 4
	tabs.add_theme_constant_override("h_separation", 8)
	tabs.add_theme_constant_override("v_separation", 6)
	add_child(tabs)
	for index in 4:
		var button := _button(["FUSÃO", "MARCOS", "TROCAS", "COMO FUNCIONA"][index])
		button.name = ["FusionTab", "MilestonesTab", "ExchangeTab", "FusionHelpTab"][index]
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.pressed.connect(_tab.bind(index))
		tabs.add_child(button)
		tab_buttons.append(button)
	body = VBoxContainer.new()
	body.size_flags_horizontal = SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	add_child(body)
	compact = get_viewport_rect().size.y < 560
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
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 40
	button.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	ART.apply_button(button, primary)
	return button

func _frame(parent: Node, title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", ART.panel(Color("#071a14", 0.98), 12))
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6 if compact else 8)
	panel.add_child(column)
	column.add_child(_label(title, 16, ART.GOLD))
	return column

func _tab(index: int) -> void:
	if busy or is_instance_valid(result_popup): return
	draft.tab = index
	_render()

func _render() -> void:
	add_theme_constant_override("separation", 4 if int(draft.tab) == 1 else 8)
	for node in body.get_children():
		body.remove_child(node)
		node.queue_free()
	panes = null
	for index in tab_buttons.size(): tab_buttons[index].disabled = index == int(draft.tab)
	body.add_theme_constant_override("separation", 8)
	if int(draft.tab) == 1:
		_build_milestones()
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
	for index in 2:
		var button := _button("ESCOLHER ITENS" if index == 0 else "RITUAL")
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
	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 8)
	inventory.add_child(filters)
	var owner_picker := OptionButton.new()
	owner_picker.name = "FusionClass"
	owner_picker.fit_to_longest_item = false
	owner_picker.custom_minimum_size = Vector2(110, 40)
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
	rarity_picker.custom_minimum_size = Vector2(110, 40)
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
	inventory.add_child(_label("Somente itens não equipados. Mais fracos primeiro. Iniciais protegidos.", 11, ART.MUTED))
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
	var automatic := _button("SELECIONAR 4 MAIS FRACOS")
	automatic.name = "FusionAutoSelect"
	automatic.pressed.connect(_auto_select)
	inventory.add_child(automatic)
	var ritual := _frame(panes, "RITUAL DE FUSÃO")
	ritual_frame = ritual.get_parent()
	sockets = HBoxContainer.new()
	sockets.name = "FusionSockets"
	sockets.alignment = BoxContainer.ALIGNMENT_CENTER
	sockets.add_theme_constant_override("separation", 8)
	ritual.add_child(sockets)
	circle = RitualCircle.new()
	circle.custom_minimum_size.y = 64 if compact else 108
	circle.mouse_filter = MOUSE_FILTER_IGNORE
	ritual.add_child(circle)
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
	ritual.add_child(progress_label)
	progress = ProgressBar.new()
	progress.show_percentage = false
	progress.custom_minimum_size.y = 8
	progress.add_theme_stylebox_override("fill", ART.panel(ART.GOLD, 0))
	ritual.add_child(progress)
	status = _label("", 11, ART.MUTED)
	status.name = "FusionStatus"
	ritual.add_child(status)
	fuse = _button("FUNDIR 4 ITENS", true)
	fuse.name = "PerformFusion"
	fuse.custom_minimum_size.y = 46
	fuse.pressed.connect(_begin_fusion)
	ritual.add_child(fuse)
	var clear := _button("LIMPAR SELEÇÃO")
	clear.pressed.connect(func() -> void:
		_reset_selection()
		_refresh_inventory()
		_update_ritual())
	ritual.add_child(clear)
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
	var allowed := {}
	for item in eligible: allowed[str(item.id)] = SaveManager.equipment_quantity(str(item.id))
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
		var button := _icon_button(item, 50)
		button.name = "FusionIngredient"
		button.set_meta("item_id", str(item.id))
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
			button = _icon_button(item, 48)
			button.tooltip_text = item.display_name + "\nClique para retirar da seleção."
			button.pressed.connect(_remove.bind(index))
		else:
			button = _button("+")
			button.custom_minimum_size = Vector2(48, 54)
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
	circle.accent = ART.RARITY_COLORS.get(higher, ART.GOLD)
	circle.selected_count = selected.size()
	circle.queue_redraw()

func _layout() -> void:
	if tabs != null: tabs.columns = 4 if size.x >= 560 else 2
	if panes == null or not is_instance_valid(panes) or item_grid == null or ritual_frame == null: return
	var narrow := size.x < 760
	panes.vertical = narrow
	subnav.visible = narrow
	inputs_frame.visible = not narrow or int(draft.pane) == 0
	ritual_frame.visible = not narrow or int(draft.pane) == 1
	for index in subnav.get_child_count(): subnav.get_child(index).disabled = index == int(draft.pane) or busy
	var columns := 4 if narrow else 5
	var target_size := columns * (2 if compact else 3)
	item_grid.columns = columns
	if page_size != target_size:
		page_size = target_size
		draft.page = 0
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

func _process(delta: float) -> void:
	if not busy: return
	elapsed += delta
	if is_instance_valid(circle):
		circle.progress = minf(1.0, elapsed / 1.65)
		circle.queue_redraw()
	if elapsed >= 1.65:
		busy = false
		_block_controls(false)
		_reset_selection(false)
		AudioManager.feedback("talent")
		_refresh_inventory()
		_update_ritual()
		circle.animating = false
		circle.progress = 0.0
		_show_result()

func _block_controls(blocked: bool) -> void:
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

func _build_milestones() -> void:
	body.add_theme_constant_override("separation", 2)
	body.add_child(_label("RECOMPENSAS GARANTIDAS", 18, ART.GOLD))
	if not compact:
		body.add_child(_label("Todos os marcos são extras e repetíveis. Passe o mouse para ver os totais.", 12, ART.MUTED))
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
		panel.tooltip_text = "A cada %d fusões: +1 %s.\n%d tentativas; %d bônus entregues.\nPróximo em %d fusões. Compartilhado entre classes." % [interval, ItemTiers.label(higher), count, floori(float(count) / interval), interval - count % interval]
		body.add_child(panel)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 1)
		panel.add_child(column)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		column.add_child(row)
		var title := _label("%s → %s" % [ItemTiers.label(rarity), ItemTiers.label(higher)], 16, ART.TEXT)
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
	var column := _frame(body, "UM RITUAL, QUATRO FRAGMENTOS")
	for line in ["1. Escolha a classe e uma raridade. Selecione quatro itens, inclusive cópias repetidas se você tiver quantidade suficiente.", "2. Equipamentos em uso por qualquer classe e armas iniciais ficam protegidos. A seleção automática usa os mais fracos primeiro.", "3. A chance aparece antes da fusão. Se melhorar, recebe um item da próxima raridade; caso contrário, recebe um da mesma raridade.", "4. Cada falha acrescenta 2 pontos percentuais à chance dessa raridade, até +15 pontos. Uma melhora reinicia esse bônus.", "5. Cada 10/20/30/40/50/60 tentativas da respectiva raridade entrega um item extra da próxima raridade. Não exige uma sequência de falhas.", "6. Os resultados pertencem à classe escolhida. Cópias iguais são guardadas e podem ser usadas em outras fusões. Deus é a raridade máxima.", "O ritual consome quatro itens e devolve um, ou dois quando há bônus. Não custa ouro ou cristais. O resultado aparece em um pop-up e é salvo antes da animação.", "Na aba TROCAS: Comum = 15 ouro, Incomum = 40 ouro, Raro = 100 ouro; Épico = 1 cristal, Lendário = 3, Semideus = 8, Deus = 20 por unidade."]:
		column.add_child(_label(line, 12, ART.TEXT))

class RitualCircle extends Control:
	var accent := Color("#e9cb88")
	var selected_count := 0
	var progress := 0.0
	var animating := false
	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.y * 0.4, size.x * 0.32)
		var rotation := progress * TAU * 2.0
		draw_circle(center, radius + 8, Color(accent, 0.06 + progress * 0.14))
		for ring in 2:
			draw_arc(center, radius * (1.0 - ring * 0.23), rotation * (1.0 if ring == 0 else -1.0), rotation + TAU, 64, Color(accent, 0.6), 1.5, true)
		for index in 4:
			var angle := float(index) * TAU / 4.0 + rotation
			var point := center + Vector2.from_angle(angle) * radius
			draw_circle(point, 4, accent if index < selected_count else Color("#385146"))
			draw_line(point, center, Color(accent, 0.2 + progress * 0.4), 1, true)
		var extent := radius * (0.24 + progress * 0.3)
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -extent), center + Vector2(extent * 0.7, 0), center + Vector2(0, extent), center - Vector2(extent * 0.7, 0)]), accent)
		if animating:
			for index in 20:
				var angle := float(index) * TAU / 20.0 + rotation
				var distance := radius * (1.5 - progress) * (0.7 + float(index % 3) * 0.15)
				draw_circle(center + Vector2.from_angle(angle) * distance, 1.8, Color(accent, 0.8))
