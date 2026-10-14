extends VBoxContainer
const ART := preload("res://scripts/ui/wild_theme.gd")
const ICON := preload("res://scripts/ui/equipment_icon.gd")
var draft: Dictionary = {}
var grid: GridContainer
var empty_label: Label
var page_label: Label
var previous: Button
var next: Button
var preview: Label
var quantity: SpinBox
var value_label: Label
var balance: Label
var notice: Label
var sell: Button
var selected_id := ""
var items: Array[EquipmentData] = []
var page_size := 12

func _ready() -> void:
	name = "EquipmentExchangePanel"
	add_theme_constant_override("separation", 6)
	for pair in [["exchange_rarity", "all"], ["exchange_page", 0]]:
		if not draft.has(pair[0]): draft[pair[0]] = pair[1]
	add_child(_label("TROCAR EQUIPAMENTOS", 18, ART.GOLD))
	add_child(_label("Comum, Incomum e Raro rendem ouro. Épico ou acima rende cristais. Itens em uso e armas iniciais ficam protegidos.", 12, ART.MUTED))
	balance = _label("", 12, ART.GOLD)
	add_child(balance)
	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 8)
	add_child(filters)
	var owner := _picker("ExchangeClass")
	for id in ContentCatalog.CLASS_ORDER:
		if not SaveManager.is_class_unlocked(str(id)): continue
		owner.add_item(ContentCatalog.classes[id].display_name)
		owner.set_item_metadata(owner.item_count - 1, str(id))
		if str(draft.owner) == str(id): owner.select(owner.item_count - 1)
	owner.item_selected.connect(func(index: int) -> void:
		draft.owner = str(owner.get_item_metadata(index))
		_filter_changed())
	filters.add_child(owner)
	var rarity := _picker("ExchangeRarity")
	rarity.add_item("Todas as raridades")
	rarity.set_item_metadata(0, "all")
	for id in ItemTiers.ORDER:
		rarity.add_item(ItemTiers.label(id))
		rarity.set_item_metadata(rarity.item_count - 1, id)
		if str(draft.exchange_rarity) == id: rarity.select(rarity.item_count - 1)
	rarity.item_selected.connect(func(index: int) -> void:
		draft.exchange_rarity = str(rarity.get_item_metadata(index))
		_filter_changed())
	filters.add_child(rarity)
	grid = GridContainer.new()
	grid.name = "ExchangeItems"
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	add_child(grid)
	empty_label = _label("Nenhum item livre neste filtro. Troque a classe ou a raridade.", 13, ART.MUTED)
	empty_label.custom_minimum_size.y = 56
	add_child(empty_label)
	var pages := HBoxContainer.new()
	pages.add_theme_constant_override("separation", 8)
	add_child(pages)
	previous = _button("←")
	previous.pressed.connect(_page.bind(-1))
	pages.add_child(previous)
	page_label = _label("", 12, ART.GOLD)
	page_label.size_flags_horizontal = SIZE_EXPAND_FILL
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pages.add_child(page_label)
	next = _button("→")
	next.pressed.connect(_page.bind(1))
	pages.add_child(next)
	preview = _label("Selecione um item para ver o valor de troca.", 13, ART.TEXT)
	preview.name = "ExchangePreview"
	add_child(preview)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	quantity = SpinBox.new()
	quantity.name = "ExchangeQuantity"
	quantity.min_value = 1
	quantity.max_value = 1
	quantity.step = 1
	quantity.custom_minimum_size = Vector2(96, 42)
	quantity.value_changed.connect(func(_value: float) -> void: _update_quote())
	row.add_child(quantity)
	value_label = _label("", 13, ART.GOLD)
	value_label.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(value_label)
	sell = _button("TROCAR ITEM", true)
	sell.name = "ExchangeConfirm"
	sell.pressed.connect(_sell)
	add_child(sell)
	notice = _label("", 12, ART.GREEN)
	notice.name = "ExchangeNotice"
	add_child(notice)
	resized.connect(_layout)
	_refresh()
	_layout()

func _picker(node_name: String) -> OptionButton:
	var picker := OptionButton.new()
	picker.name = node_name
	picker.fit_to_longest_item = false
	picker.autowrap_mode = TextServer.AUTOWRAP_OFF
	picker.clip_text = true
	picker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	picker.custom_minimum_size = Vector2(110, 40)
	picker.size_flags_horizontal = SIZE_EXPAND_FILL
	return picker

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", roundi(font_size * clampf(float(SaveManager.data.settings.ui_scale), 0.85, 1.2)))
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, primary := false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 40
	ART.apply_button(button, primary)
	return button

func _layout() -> void:
	if grid == null: return
	var columns := 4 if size.x < 600 else 6
	var target := columns * 2
	grid.columns = columns
	if page_size != target:
		page_size = target
		draft.exchange_page = 0
		_refresh()

func _filter_changed() -> void:
	selected_id = ""
	draft.exchange_page = 0
	_refresh()

func _page(direction: int) -> void:
	draft.exchange_page = int(draft.exchange_page) + direction
	_refresh()

func _refresh() -> void:
	items = TransmutationRules.eligible_items(SaveManager.data, str(draft.owner), str(draft.exchange_rarity))
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	var pages := maxi(1, ceili(float(items.size()) / page_size))
	draft.exchange_page = clampi(int(draft.exchange_page), 0, pages - 1)
	for index in range(int(draft.exchange_page) * page_size, mini(items.size(), (int(draft.exchange_page) + 1) * page_size)):
		var item := items[index]
		var price := EquipmentExchange.quote(item)
		var button := _button("")
		button.name = "ExchangeItem"
		button.set_meta("item_id", str(item.id))
		button.custom_minimum_size = Vector2(50, 56)
		button.tooltip_text = "%s\n%s\nQuantidade: %d · Troca: %d %s por unidade" % [item.display_name, item.description, SaveManager.equipment_quantity(str(item.id)), int(price.unit_value), "ouro" if price.currency == "gold" else "cristais"]
		var icon := ICON.new()
		icon.item = item
		icon.framed = true
		icon.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		icon.offset_left = 4
		icon.offset_right = -4
		icon.offset_top = 3
		icon.offset_bottom = -3
		button.add_child(icon)
		button.pressed.connect(_select.bind(str(item.id)))
		grid.add_child(button)
	empty_label.visible = items.is_empty()
	grid.visible = not items.is_empty()
	page_label.text = "%d / %d · %d tipos" % [int(draft.exchange_page) + 1, pages, items.size()]
	previous.disabled = int(draft.exchange_page) == 0
	next.disabled = int(draft.exchange_page) == pages - 1
	balance.text = "OURO %d · CRISTAIS %d" % [int(SaveManager.data.gold), int(SaveManager.data.crystals)]
	_update_quote()

func _select(id: String) -> void:
	selected_id = id
	quantity.max_value = maxi(1, SaveManager.equipment_quantity(id))
	quantity.value = 1
	_update_quote()

func _update_quote() -> void:
	if sell == null: return
	var item: EquipmentData = ContentCatalog.equipment.get(selected_id)
	if item == null or SaveManager.equipment_quantity(selected_id) == 0:
		sell.disabled = true
		quantity.editable = false
		preview.text = "Selecione um item para ver o valor de troca."
		value_label.text = ""
		sell.text = "TROCAR ITEM"
		return
	var price := EquipmentExchange.quote(item)
	var amount := int(quantity.value)
	var currency := "OURO" if price.currency == "gold" else "CRISTAIS"
	preview.text = item.display_name + "\n" + item.description
	value_label.text = "%d unidade(s) → %d %s" % [amount, amount * int(price.unit_value), currency]
	sell.text = "TROCAR POR %d %s" % [amount * int(price.unit_value), currency]
	sell.disabled = GameManager.run_active or NetworkSession.running
	quantity.editable = true

func _sell() -> void:
	if selected_id.is_empty(): return
	var transaction := SaveManager.exchange_equipment(selected_id, int(quantity.value), str(draft.owner))
	if not bool(transaction.ok):
		notice.text = str(transaction.reason)
		return
	var receipt: Dictionary = transaction.receipt
	notice.text = "%d item(ns) trocado(s) por %d %s. Salvo no inventário." % [int(receipt.amount), int(receipt.total), "ouro" if receipt.currency == "gold" else "cristais"]
	selected_id = ""
	AudioManager.feedback("talent")
	_refresh()
