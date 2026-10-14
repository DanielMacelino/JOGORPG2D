extends VBoxContainer
## All awarded equipment, including level rewards, with a bounded number of cards.
const STYLE := preload("res://scripts/ui/wild_theme.gd")
const ICON := preload("res://scripts/ui/equipment_icon.gd")
const TIERS := preload("res://scripts/data/item_tiers.gd")
var items: Array = []
var page := 0
var page_size := 2
var cards: VBoxContainer
var counter: Label
var previous: Button
var next: Button

func _ready() -> void:
	name = "RunRewards"
	size_flags_horizontal = SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	var title := Label.new()
	title.text = "EQUIPAMENTOS DA EXPEDIÇÃO  ·  %d" % items.size()
	title.add_theme_color_override("font_color", STYLE.GOLD)
	title.add_theme_font_size_override("font_size", 13)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(title)
	cards = VBoxContainer.new()
	cards.add_theme_constant_override("separation", 5)
	add_child(cards)
	var navigation := HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 8)
	add_child(navigation)
	previous = _button(navigation, "Anterior", -1)
	counter = Label.new()
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter.size_flags_horizontal = SIZE_EXPAND_FILL
	counter.add_theme_font_size_override("font_size", 12)
	navigation.add_child(counter)
	next = _button(navigation, "Próxima", 1)
	_layout()
	get_viewport().size_changed.connect(_layout)
	_refresh()

func _button(parent: Control, text: String, offset: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 38
	STYLE.apply_button(button)
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(func() -> void: page += offset; _refresh())
	parent.add_child(button)
	return button

func _layout() -> void:
	var requested := 1 if get_viewport_rect().size.y < 460 else 2
	if page_size != requested:
		page_size = requested
		page = 0
		if cards != null:
			_refresh()

func _refresh() -> void:
	for child in cards.get_children():
		cards.remove_child(child)
		child.queue_free()
	var pages := maxi(1, ceili(float(items.size()) / page_size))
	page = clampi(page, 0, pages - 1)
	counter.text = "%d / %d" % [page + 1, pages]
	previous.disabled = page == 0
	next.disabled = page + 1 >= pages
	previous.get_parent().visible = pages > 1
	if items.is_empty():
		var empty := Label.new()
		empty.text = "Nenhum equipamento recebido nesta expedição."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cards.add_child(empty)
		return
	for index in range(page * page_size, mini(items.size(), (page + 1) * page_size)):
		var entry: Dictionary = items[index]
		var item: EquipmentData = ContentCatalog.equipment.get(str(entry.get("id", "")))
		if item == null:
			continue
		var card := PanelContainer.new()
		card.set_meta("equipment_id", str(item.id))
		var rarity: Color = STYLE.RARITY_COLORS.get(str(item.rarity), STYLE.GOLD)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#0a1b22")
		style.border_color = rarity
		style.set_border_width_all(1)
		style.set_corner_radius_all(3)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		card.add_theme_stylebox_override("panel", style)
		card.tooltip_text = item.display_name + "\n" + item.description
		cards.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 9)
		card.add_child(row)
		var icon := ICON.new()
		icon.item = item
		icon.framed = true
		icon.custom_minimum_size = Vector2(42, 42)
		icon.size_flags_vertical = SIZE_SHRINK_CENTER
		row.add_child(icon)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 3)
		row.add_child(info)
		var name_label := Label.new()
		name_label.text = item.display_name
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.max_lines_visible = 2
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", Color("#f4ead5"))
		info.add_child(name_label)
		var origin := "CHEFE" if str(entry.get("source", "")) == "boss" else "SUBIDA DE NÍVEL"
		var status := "REPETIDO: +100 OURO" if bool(entry.get("duplicate", false)) else "ADICIONADO AO ARSENAL"
		var details := Label.new()
		details.text = "%s  ·  %s  ·  %s" % [TIERS.label(str(item.rarity)).to_upper(), origin, status]
		details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_theme_font_size_override("font_size", 11)
		details.add_theme_color_override("font_color", rarity.lightened(0.20))
		info.add_child(details)
		card.modulate.a = 0.0
		create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(card, "modulate:a", 1.0, 0.22)
