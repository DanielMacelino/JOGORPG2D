extends VBoxContainer
## Permanent mastery cabinet. Purchases refresh in place and always use canonical prices.
signal back_requested
const ART := preload("res://scripts/ui/wild_theme.gd")
const HOME := preload("res://scripts/ui/menu/home_screen.gd")
const RECORDS := preload("res://scripts/ui/menu/records_screen.gd")
const CABINET := preload("res://scripts/ui/relics_panel.gd")
const FILTERS := [["Todos", "all"], ["Força", "strength"], ["Habilidades", "skills"], ["Movimento", "movement"], ["Defesa", "defense"], ["Economia", "economy"]]
const META := {
	"vitality": ["defense", "Vida máxima", "Mais fôlego para sobreviver aos cercos.", "#ff8199"],
	"might": ["strength", "Dano causado", "Fortaleça cada golpe e cada poder do seu viajante.", "#f3ab7a"],
	"fortune": ["economy", "Ouro e experiência", "Extraia mais recursos de cada expedição.", "#efd285"],
	"resilience": ["defense", "Redução de dano", "Resista aos ataques e avance sob pressão.", "#8ce0b0"],
	"swiftness": ["movement", "Velocidade de movimento", "Abra distância e atravesse as hordas com agilidade.", "#7be5d8"],
	"crit_mastery": ["strength", "Chance de crítico", "Encontre a abertura que transforma um golpe em execução.", "#d6a4ff"],
	"xp_boost": ["skills", "Experiência adicional", "Aprenda mais com cada criatura derrotada.", "#84d7ff"],
	"attack_speed": ["skills", "Velocidade de ataque", "Dê ritmo aos seus ataques e mantenha os inimigos sob pressão.", "#ffca78"]
}
var draft: Dictionary = {}
var selected_id := "vitality"
var filter_id := "all"
var page_index := 0
var page_size := 5
var section_index := 0
var compact := false
var narrow := false
var matched_ids: Array[String] = []
var visible_ids: Array[String] = []
var currencies: HFlowContainer
var mastery_label: Label
var mastery_bar: ProgressBar
var filter_grid: GridContainer
var sections: HBoxContainer
var list_column: VBoxContainer
var cards: VBoxContainer
var pager: HBoxContainer
var detail_frame: PanelContainer
var details: VBoxContainer
var notice: Label

func _ready() -> void:
	name = "UpgradesPanel"
	size_flags_horizontal = SIZE_EXPAND_FILL
	var extent := get_viewport_rect().size
	compact = extent.y < 600 or (extent.x < 600 and extent.y < 720)
	narrow = extent.x < 900 or compact
	page_size = 2 if compact else (3 if narrow else 5)
	filter_id = str(draft.get("filter", "all"))
	selected_id = str(draft.get("selected", "vitality"))
	if not META.has(selected_id): selected_id = "vitality"
	if not FILTERS.any(func(entry: Array) -> bool: return entry[1] == filter_id): filter_id = "all"
	page_index = maxi(0, int(draft.get("page", 0)))
	section_index = clampi(int(draft.get("section", 0)), 0, 1)
	add_theme_constant_override("separation", 4 if compact else 8)
	_build_header()
	var mastery := VBoxContainer.new()
	mastery.add_theme_constant_override("separation", 3)
	add_child(mastery)
	mastery_label = _label("", 11, ART.GOLD)
	mastery_label.name = "MasterySummary"
	mastery.add_child(mastery_label)
	mastery_bar = _bar(ART.GOLD, 80, 5)
	mastery.add_child(mastery_bar)
	sections = HBoxContainer.new()
	sections.visible = narrow
	sections.name = "UpgradeSections"
	add_child(sections)
	for index in 2:
		var button := _button("MELHORIAS" if index == 0 else "DETALHES", false, 30)
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.pressed.connect(_set_section.bind(index))
		sections.add_child(button)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	add_child(body)
	list_column = VBoxContainer.new()
	list_column.size_flags_horizontal = SIZE_EXPAND_FILL
	list_column.size_flags_stretch_ratio = 0.71
	list_column.add_theme_constant_override("separation", 5 if compact else 8)
	body.add_child(list_column)
	filter_grid = GridContainer.new()
	filter_grid.name = "UpgradeFilters"
	filter_grid.columns = 2 if extent.x < 380 else (3 if narrow else 6)
	filter_grid.add_theme_constant_override("h_separation", 4)
	filter_grid.add_theme_constant_override("v_separation", 4)
	list_column.add_child(filter_grid)
	for entry in FILTERS:
		var button := _button(str(entry[0]), filter_id == str(entry[1]), 30 if compact else 38)
		button.name = "UpgradeFilter_" + str(entry[1])
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.action_font_size = 11
		button.pressed.connect(set_filter.bind(str(entry[1])))
		filter_grid.add_child(button)
	cards = VBoxContainer.new()
	cards.name = "UpgradeCards"
	cards.add_theme_constant_override("separation", 5 if compact else 7)
	list_column.add_child(cards)
	pager = HBoxContainer.new()
	pager.alignment = BoxContainer.ALIGNMENT_END
	list_column.add_child(pager)
	detail_frame = CABINET.RelicFrame.new()
	detail_frame.name = "UpgradeDetails"
	detail_frame.size_flags_horizontal = SIZE_EXPAND_FILL
	detail_frame.size_flags_stretch_ratio = 0.29
	detail_frame.add_theme_stylebox_override("panel", _frame(ART.GOLD, 8 if compact else 13))
	body.add_child(detail_frame)
	details = VBoxContainer.new()
	details.add_theme_constant_override("separation", 4 if compact else 5)
	detail_frame.add_child(details)
	notice = _label("Melhorias permanentes para todas as suas expedições.", 11, ART.MUTED)
	notice.name = "UpgradeNotice"
	notice.visible = not compact
	add_child(notice)
	_refresh()

func _build_header() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	add_child(row)
	var back := _button("←  VOLTAR", false, 32 if compact else 42)
	back.name = "UpgradesBack"
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
	var title := _label("MELHORIAS", 22 if compact else (28 if narrow else 34), ART.GOLD, true)
	title.name = "UpgradesTitle"
	_single_line(title)
	titles.add_child(title)
	var subtitle := _label("Invista ouro para fortalecer seu viajante.", 13, ART.TEXT)
	subtitle.visible = not compact
	titles.add_child(subtitle)
	if not compact: add_child(RECORDS.Rule.new())
	currencies = HFlowContainer.new()
	currencies.add_theme_constant_override("h_separation", 20)
	currencies.add_theme_constant_override("v_separation", 2)
	add_child(currencies)

func _refresh() -> void:
	_clear(currencies)
	for text in ["OURO DE VÉSPERA  %d" % int(SaveManager.data.gold), "CRISTAIS  %d" % int(SaveManager.data.crystals)]:
		var label := _label(text, 11 if compact else 12, ART.GOLD)
		label.name = "UpgradeCurrency" + str(currencies.get_child_count())
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		currencies.add_child(label)
	var tier := PermanentUpgrades.tier(SaveManager.data.upgrades)
	var progress := PermanentUpgrades.progress(SaveManager.data.upgrades)
	mastery_label.text = "PATAMAR %d · %s · +%s por compra · %d/80" % [tier + 1, PermanentUpgrades.NAMES[tier], PermanentUpgrades.percent(PermanentUpgrades.RATES[tier]), progress]
	mastery_label.tooltip_text = "Complete 10 níveis de cada um dos 8 atributos para abrir o próximo patamar. Os bônus se acumulam."
	mastery_bar.value = progress
	_refresh_cards()
	_refresh_details()
	_apply_section()
	_store()

func _refresh_cards() -> void:
	_clear(cards)
	_clear(pager)
	matched_ids.clear()
	visible_ids.clear()
	for item in ContentCatalog.upgrades:
		if filter_id == "all" or META[str(item.id)][0] == filter_id: matched_ids.append(str(item.id))
	var pages := maxi(1, ceili(float(matched_ids.size()) / page_size))
	page_index = clampi(page_index, 0, pages - 1)
	for index in range(page_index * page_size, mini(matched_ids.size(), (page_index + 1) * page_size)):
		var id := matched_ids[index]
		visible_ids.append(id)
		var color := _color(id)
		var card := CABINET.RelicFrame.new()
		card.name = "UpgradeCard_" + id
		card.accent = color
		card.selected = selected_id == id
		card.add_theme_stylebox_override("panel", _frame(color, 6, card.selected))
		cards.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)
		var pick := Button.new()
		pick.name = "SelectUpgrade_" + id
		pick.icon = _texture(id)
		pick.expand_icon = true
		pick.custom_minimum_size = Vector2(44 if compact else 58, 44 if compact else 58)
		pick.add_theme_constant_override("icon_max_width", 44 if compact else 58)
		pick.tooltip_text = "Ver detalhes: " + _title(id)
		for state in ["normal", "hover", "pressed"]: pick.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		pick.pressed.connect(select_upgrade.bind(id, true))
		row.add_child(pick)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = SIZE_EXPAND_FILL
		info.size_flags_vertical = SIZE_SHRINK_CENTER
		info.add_theme_constant_override("separation", 2)
		info.mouse_filter = MOUSE_FILTER_STOP
		info.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		info.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed: select_upgrade(id, true))
		row.add_child(info)
		var title := _label(_title(id), 15 if compact else 18, ART.TEXT, true)
		_single_line(title)
		title.tooltip_text = _title(id)
		info.add_child(title)
		var effect := _label(_bonus_text(id), 11 if compact else 12, color)
		effect.max_lines_visible = 2
		info.add_child(effect)
		var progression := HBoxContainer.new()
		info.add_child(progression)
		var rank := _local_rank(id)
		var level := _label("NÍVEL %d/10" % rank, 10 if compact else 11, ART.MUTED)
		level.autowrap_mode = TextServer.AUTOWRAP_OFF
		progression.add_child(level)
		var bar := _bar(color, 10, 7)
		bar.value = rank
		bar.size_flags_horizontal = SIZE_EXPAND_FILL
		bar.size_flags_vertical = SIZE_SHRINK_CENTER
		progression.add_child(bar)
		var actions := VBoxContainer.new()
		actions.size_flags_vertical = SIZE_SHRINK_CENTER
		actions.add_theme_constant_override("separation", 2)
		row.add_child(actions)
		var price := _label("%d OURO" % PermanentUpgrades.cost(id, SaveManager.data.upgrades) if _can_buy(id) else "PATAMAR COMPLETO", 10 if compact else 12, ART.GOLD)
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price.autowrap_mode = TextServer.AUTOWRAP_OFF
		if not _can_buy(id) and narrow: price.text = "10/10"
		actions.add_child(price)
		var action := _purchase_button(id, true)
		action.name = "BuyUpgrade_" + id
		action.custom_minimum_size.x = 80 if narrow else 128
		actions.add_child(action)
	var previous := _button("←", false, 30)
	previous.name = "PreviousUpgrades"
	previous.disabled = page_index == 0
	previous.pressed.connect(_change_page.bind(-1))
	pager.add_child(previous)
	var counter := _label("%d / %d" % [page_index + 1, pages], 12, ART.MUTED)
	counter.custom_minimum_size.x = 65
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter.size_flags_vertical = SIZE_SHRINK_CENTER
	pager.add_child(counter)
	var next := _button("→", false, 30)
	next.name = "NextUpgrades"
	next.disabled = page_index >= pages - 1
	next.pressed.connect(_change_page.bind(1))
	pager.add_child(next)

func _refresh_details() -> void:
	_clear(details)
	var id := selected_id
	var color := _color(id)
	var stage := CABINET.RelicStage.new()
	stage.name = "UpgradeIllustration"
	stage.texture = _texture(id)
	stage.accent = color
	stage.custom_minimum_size.y = 42 if compact else (110 if narrow else 120)
	details.add_child(stage)
	var title := _label(_title(id), 18 if compact else 24, ART.TEXT, true)
	title.name = "SelectedUpgradeTitle"
	details.add_child(title)
	var tier := PermanentUpgrades.tier(SaveManager.data.upgrades)
	if not compact: details.add_child(_label("%s · NÍVEL %d/10" % [str(PermanentUpgrades.NAMES[tier]).to_upper(), _local_rank(id)], 11, color))
	if not compact: details.add_child(_label(str(META[id][2]), 13, ART.TEXT))
	if not compact: details.add_child(RECORDS.Rule.new())
	if not compact: details.add_child(_label("EFEITO PERMANENTE", 12, ART.GOLD, true))
	var bonus := _label(_bonus_text(id), 12 if compact else 14, color)
	bonus.name = "UpgradeBonusPreview"
	details.add_child(bonus)
	var rank: int = SaveManager.upgrade_level(id)
	var step := _label("Nível %d → %d neste patamar" % [_local_rank(id), _local_rank(id) + 1] if _can_buy(id) else ("Maestria completa: 70/70" if rank >= PermanentUpgrades.MAX_RANK else "Conclua os outros atributos para avançar."), 11 if compact else 12, ART.TEXT)
	step.name = "UpgradeNextLevel"
	details.add_child(step)
	var progress := _bar(color, 10, 8)
	progress.value = _local_rank(id)
	details.add_child(progress)
	if not compact:
		details.add_child(_label("%d/70 compras acumuladas" % rank, 11, ART.MUTED))
		details.add_child(RECORDS.Rule.new())
		var explanation := "Complete 10 níveis de cada atributo para abrir o próximo patamar. Seus bônus anteriores permanecem."
		if id in ["resilience", "crit_mastery"]: explanation = "O ganho incide sobre o percentual restante. Toda compra melhora o atributo, sem atingir imunidade ou críticos garantidos."
		details.add_child(_label(explanation, 12, ART.MUTED))
	var space := Control.new()
	space.size_flags_vertical = SIZE_EXPAND_FILL
	details.add_child(space)
	var price := _label("%d OURO" % PermanentUpgrades.cost(id, SaveManager.data.upgrades) if _can_buy(id) else "", 12 if compact else 16, ART.GOLD, true)
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.visible = _can_buy(id)
	details.add_child(price)
	var action := _purchase_button(id, false)
	action.name = "SelectedUpgradeAction"
	details.add_child(action)

func purchase(id: String) -> bool:
	if not META.has(id): return false
	var result: bool = SaveManager.buy_upgrade(id)
	if result:
		selected_id = id
		_refresh()
	else:
		_refresh()
		notice.text = "Melhoria indisponível durante a partida." if GameManager.run_active else ("Complete os outros atributos para abrir o próximo patamar." if not _can_buy(id) else "Faltam %d de ouro." % maxi(0, PermanentUpgrades.cost(id, SaveManager.data.upgrades) - int(SaveManager.data.gold)))
	return result

func set_filter(id: String) -> void:
	filter_id = id
	page_index = 0
	for item in ContentCatalog.upgrades:
		if id == "all" or META[str(item.id)][0] == id:
			selected_id = str(item.id)
			break
	for index in filter_grid.get_child_count():
		var button: Button = filter_grid.get_child(index)
		ART.apply_button(button, str(FILTERS[index][1]) == id, button.get_theme_font("font"))
		button.add_theme_font_size_override("font_size", 11)
	_refresh()

func select_upgrade(id: String, show_details: bool = false) -> void:
	if not META.has(id): return
	selected_id = id
	if narrow and show_details: section_index = 1
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
	for index in sections.get_child_count(): sections.get_child(index).modulate = Color.WHITE if section_index == index else Color("#a1aaa2")

func _store() -> void:
	draft.filter = filter_id
	draft.selected = selected_id
	draft.page = page_index
	draft.section = section_index

func _can_buy(id: String) -> bool:
	return PermanentUpgrades.can_buy(id, SaveManager.data.upgrades)

func _purchase_button(id: String, on_card: bool) -> Button:
	var allowed := _can_buy(id)
	var text := "APRIMORAR ↑" if allowed else ("MÁXIMO" if SaveManager.upgrade_level(id) >= PermanentUpgrades.MAX_RANK else "COMPLETO")
	if narrow and on_card and allowed: text = "APRIMORAR"
	var button := _button(text, allowed, 30 if compact else (34 if on_card else 42))
	button.disabled = not allowed or int(SaveManager.data.gold) < PermanentUpgrades.cost(id, SaveManager.data.upgrades) or GameManager.run_active
	button.tooltip_text = "Complete os 10 níveis de todos os atributos para abrir o próximo patamar." if not allowed else ("Ouro insuficiente." if button.disabled else "Compra permanente. Bônus acumulativos.")
	button.action_font_size = 10 if narrow and on_card else 12
	button.pressed.connect(purchase.bind(id))
	return button

func _local_rank(id: String) -> int:
	return clampi(SaveManager.upgrade_level(id) - PermanentUpgrades.tier(SaveManager.data.upgrades) * 10, 0, 10)

func _bonus_text(id: String) -> String:
	var rank: int = SaveManager.upgrade_level(id)
	var current := PermanentUpgrades.percent(PermanentUpgrades.effective_bonus(id, rank))
	var following := PermanentUpgrades.percent(PermanentUpgrades.effective_bonus(id, rank + 1))
	return "%s: +%s%s" % [str(META[id][1]), current, " → +" + following if _can_buy(id) else ""]

func _title(id: String) -> String:
	for item in ContentCatalog.upgrades:
		if str(item.id) == id: return str(item.name)
	return id

func _texture(id: String) -> Texture2D:
	return load("res://assets/art/upgrades/%s.svg" % id) as Texture2D

func _color(id: String) -> Color:
	return Color(str(META[id][3]))

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

func _button(text: String, primary: bool, height: float) -> Button:
	var button := HOME.OrnateAction.new()
	button.text = text
	button.primary = primary
	button.action_font_size = 12
	button.custom_minimum_size.y = height
	return button

func _frame(color: Color, margin: float, active: bool = false) -> StyleBoxFlat:
	var style := ART.panel(Color("#05120f", 0.97).lerp(Color(color.darkened(0.86), 0.97), 0.65 if active else 0.25), margin)
	style.border_color = color if active else Color(color, 0.55)
	style.set_border_width_all(2 if active else 1)
	if active:
		style.shadow_color = Color(color, 0.16)
		style.shadow_size = 5
	return style

func _bar(color: Color, maximum: float, height: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = maximum
	bar.custom_minimum_size.y = height
	var track := ART.panel(Color("#14252b"), 0)
	track.border_color = Color("#768b91")
	bar.add_theme_stylebox_override("background", track)
	var fill := ART.panel(color, 0)
	fill.border_color = color.lightened(0.35)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
