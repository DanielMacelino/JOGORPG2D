extends VBoxContainer
## Class selection gallery. Actual portraits, stats, progression and recruitment prices.
signal back_requested
signal class_selected(id: String)
signal recruit_requested(id: String, currency: String)
const ART := preload("res://scripts/ui/wild_theme.gd")
const HOME := preload("res://scripts/ui/menu/home_screen.gd")
const RECORDS := preload("res://scripts/ui/menu/records_screen.gd")
const CABINET := preload("res://scripts/ui/relics_panel.gd")
const COLORS := {"warrior": "#e49a73", "mage": "#70c9f1", "ranger": "#acd87d", "assassin": "#d1a2e4", "druid": "#7dd3ab", "paladin": "#f0ce87"}
const WEAPONS := {"warrior": "sword", "mage": "staff", "ranger": "bow", "assassin": "daggers", "druid": "roots", "paladin": "hammer"}
var draft: Dictionary = {}
var selected_class := "warrior"
var page_index := 0
var page_size := 3
var compact := false
var horizontal_card := false
var visible_ids: Array[String] = []
var cards: GridContainer
var pager: HBoxContainer
var currencies: HFlowContainer
var notice: Label

func _ready() -> void:
	name = "CharactersPanel"
	size_flags_horizontal = SIZE_EXPAND_FILL
	var extent := get_viewport_rect().size
	compact = extent.y < 660 or (extent.x < 600 and extent.y < 720)
	horizontal_card = compact and extent.x >= 560
	page_size = 1 if extent.x < 650 or compact else (2 if extent.x < 1050 else 3)
	var initial_page := floori(float(maxi(0, ContentCatalog.CLASS_ORDER.find(selected_class))) / page_size)
	page_index = int(draft.get("page", initial_page))
	add_theme_constant_override("separation", 4 if compact else 9)
	_build_header()
	cards = GridContainer.new()
	cards.name = "CharacterCards"
	cards.columns = page_size
	cards.size_flags_horizontal = SIZE_EXPAND_FILL
	cards.add_theme_constant_override("h_separation", 14)
	add_child(cards)
	pager = HBoxContainer.new()
	pager.name = "CharacterPages"
	pager.alignment = BoxContainer.ALIGNMENT_CENTER
	pager.add_theme_constant_override("separation", 16)
	add_child(pager)
	notice = _label("Cada viajante mantém seu nível, seus talentos e seus equipamentos.", 11, ART.MUTED)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.visible = not compact
	add_child(notice)
	refresh()

func _build_header() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	var back := _button("←  VOLTAR", false, 32 if compact else 42)
	back.name = "CharactersBack"
	back.custom_minimum_size.x = 100 if compact else 132
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
	var title := _label("PERSONAGENS", 20 if compact else (27 if page_size == 1 else 34), ART.GOLD, true)
	title.name = "CharactersTitle"
	_single_line(title)
	titles.add_child(title)
	var subtitle := _label("Seis estilos de combate. Recrute novos viajantes com ouro ou cristais.", 13, ART.TEXT)
	subtitle.visible = not compact
	titles.add_child(subtitle)
	if not compact: add_child(RECORDS.Rule.new())
	currencies = HFlowContainer.new()
	currencies.add_theme_constant_override("h_separation", 20)
	currencies.add_theme_constant_override("v_separation", 2)
	add_child(currencies)

func refresh() -> void:
	_clear(currencies)
	for text in ["OURO DE VÉSPERA  %d" % int(SaveManager.data.gold), "CRISTAIS  %d" % int(SaveManager.data.crystals)]:
		var currency := _label(text, 11 if compact else 12, ART.GOLD)
		currency.name = "CharacterCurrency" + str(currencies.get_child_count())
		currency.autowrap_mode = TextServer.AUTOWRAP_OFF
		currencies.add_child(currency)
	_clear(cards)
	_clear(pager)
	visible_ids.clear()
	var pages := ceili(float(ContentCatalog.CLASS_ORDER.size()) / page_size)
	page_index = clampi(page_index, 0, pages - 1)
	for index in range(page_index * page_size, mini(ContentCatalog.CLASS_ORDER.size(), (page_index + 1) * page_size)):
		var id := str(ContentCatalog.CLASS_ORDER[index])
		visible_ids.append(id)
		_build_card(id)
	var previous := _button("←", false, 32)
	previous.name = "PreviousCharacters"
	previous.disabled = page_index == 0
	previous.tooltip_text = "Personagens anteriores"
	previous.pressed.connect(change_page.bind(-1))
	pager.add_child(previous)
	var caption := _label("PERSONAGENS %d–%d / %d" % [page_index * page_size + 1, mini((page_index + 1) * page_size, 6), 6], 11 if compact else 13, ART.GOLD, true)
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	caption.size_flags_vertical = SIZE_SHRINK_CENTER
	pager.add_child(caption)
	var next := _button("→", false, 32)
	next.name = "NextCharacters"
	next.disabled = page_index == pages - 1
	next.tooltip_text = "Outros personagens"
	next.pressed.connect(change_page.bind(1))
	pager.add_child(next)
	draft.page = page_index

func _build_card(id: String) -> void:
	var data: ClassData = ContentCatalog.classes[id]
	var unlocked: bool = SaveManager.is_class_unlocked(id)
	var active := unlocked and selected_class == id
	var accent := Color(str(COLORS[id]))
	var frame := CABINET.RelicFrame.new()
	frame.name = "CharacterCard_" + id
	frame.accent = ART.GOLD if active else accent
	frame.selected = active
	frame.size_flags_horizontal = SIZE_EXPAND_FILL
	var style := ART.panel(Color("#08110f", 0.96).lerp(Color(accent.darkened(0.88), 0.96), 0.8), 6 if compact else 9)
	style.border_color = ART.GOLD if active else Color(accent, 0.8)
	style.set_border_width_all(2 if active else 1)
	style.set_corner_radius_all(1)
	if active:
		style.shadow_size = 5
		style.shadow_color = Color(ART.GOLD, 0.17)
	frame.add_theme_stylebox_override("panel", style)
	cards.add_child(frame)
	var layout: BoxContainer = HBoxContainer.new() if horizontal_card else VBoxContainer.new()
	layout.add_theme_constant_override("separation", 3 if compact else 5)
	frame.add_child(layout)
	var art_column := VBoxContainer.new()
	art_column.add_theme_constant_override("separation", 0)
	art_column.size_flags_horizontal = SIZE_EXPAND_FILL
	if horizontal_card: art_column.size_flags_stretch_ratio = 0.38
	layout.add_child(art_column)
	var status := _label("EM VIAGEM" if active else ("NO ACAMPAMENTO" if unlocked else "RECRUTÁVEL"), 10, ART.GOLD if active else accent, true)
	status.name = "ClassStatus_" + id
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_OFF
	art_column.add_child(status)
	var stage := CharacterStage.new()
	stage.name = "ClassPortrait_" + id
	stage.class_id = id
	stage.accent = accent
	stage.locked = not unlocked
	stage.custom_minimum_size.y = clampf(get_viewport_rect().size.y - 170, 120, 370) if horizontal_card else (86 if compact else 180)
	stage.size_flags_vertical = SIZE_EXPAND_FILL
	art_column.add_child(stage)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3 if compact else 5)
	if horizontal_card: info.size_flags_stretch_ratio = 0.62
	layout.add_child(info)
	var title := _label(data.display_name, 20 if compact else 25, ART.TEXT, true)
	title.name = "ClassTitle_" + id
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_single_line(title)
	title.tooltip_text = data.display_name
	info.add_child(title)
	var description := _label(data.description, 11 if compact else 12, ART.TEXT)
	description.name = "ClassDescription_" + id
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.max_lines_visible = 2
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	description.custom_minimum_size.y = 34 if not compact else 0
	description.tooltip_text = data.description
	description.mouse_filter = MOUSE_FILTER_PASS
	description.visible = not horizontal_card
	info.add_child(description)
	if horizontal_card: title.tooltip_text = data.display_name + "\n" + data.description
	_build_stats(info, data)
	var starting: AbilityData = ContentCatalog.abilities.get(str(data.starting_ability))
	if starting != null:
		var passive_row := HBoxContainer.new()
		passive_row.add_theme_constant_override("separation", 6)
		info.add_child(passive_row)
		var icon := TextureRect.new()
		icon.texture = load("res://assets/art/equipment/%s.svg" % str(WEAPONS[id]))
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(22, 22)
		icon.size_flags_vertical = SIZE_SHRINK_CENTER
		icon.modulate = accent
		passive_row.add_child(icon)
		var passive := _label(starting.display_name + " · " + starting.description, 10 if compact else 11, accent)
		passive.name = "ClassPassive_" + id
		passive.size_flags_horizontal = SIZE_EXPAND_FILL
		passive.max_lines_visible = 2
		passive.custom_minimum_size.y = 30 if not compact else 0
		passive.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		passive.tooltip_text = starting.display_name + "\n" + starting.description
		passive.mouse_filter = MOUSE_FILTER_PASS
		passive_row.add_child(passive)
	var runs := _label("%d expedições com esta classe" % int(SaveManager.data.get("statistics", {}).get("class_runs", {}).get(id, 0)), 11, ART.MUTED)
	runs.name = "ClassRuns_" + id
	runs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	runs.visible = not compact
	info.add_child(runs)
	var level := TalentManager.character_level(id)
	var xp := TalentManager.xp_into_level(id)
	var xp_cost := TalentManager.level_cost(level)
	var progress := _label("NÍVEL %d · %d / %d XP" % [level, xp, xp_cost] if level < TalentManager.MAX_LEVEL else "NÍVEL %d · MÁXIMO" % level, 10 if compact else 11, ART.GOLD)
	progress.name = "ClassLevel_" + id
	progress.autowrap_mode = TextServer.AUTOWRAP_OFF
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_child(progress)
	var xp_bar := _bar(accent, xp_cost, 4)
	xp_bar.name = "ClassXP_" + id
	xp_bar.value = xp_cost if level >= TalentManager.MAX_LEVEL else xp
	info.add_child(xp_bar)
	var spacer := Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	info.add_child(spacer)
	if unlocked:
		var select := _button("✓  SELECIONADO" if active else "ESCOLHER CLASSE", active, 32 if compact else 36)
		select.name = "SelectClass_" + id
		select.disabled = active
		select.pressed.connect(func() -> void: class_selected.emit(id))
		info.add_child(select)
		# OrnateAction installs its defaults in _ready, so customize afterwards.
		if active:
			select.add_theme_stylebox_override("disabled", style.duplicate())
			select.add_theme_color_override("font_disabled_color", ART.GOLD)
	else:
		var recruit := HBoxContainer.new()
		recruit.add_theme_constant_override("separation", 6)
		info.add_child(recruit)
		for currency in ["gold", "crystals"]:
			var price := data.cost_gold if currency == "gold" else data.cost_crystals
			var buy := _button("%d %s" % [price, "OURO" if currency == "gold" else "CRISTAIS"], currency == "gold", 32 if compact else 36)
			buy.name = "Recruit_%s_%s" % [id, currency]
			buy.action_font_size = 11
			buy.size_flags_horizontal = SIZE_EXPAND_FILL
			buy.disabled = int(SaveManager.data.get(currency, 0)) < price
			buy.tooltip_text = "Recrutar %s por %d %s. Você recebe a arma inicial desta classe." % [data.display_name, price, "ouro" if currency == "gold" else "cristais"]
			buy.pressed.connect(func() -> void: recruit_requested.emit(id, currency))
			recruit.add_child(buy)

func _build_stats(parent: Node, data: ClassData) -> void:
	var frame := PanelContainer.new()
	var style := ART.panel(Color("#07120f", 0.8), 5)
	style.border_color = Color(data.accent, 0.45)
	frame.add_theme_stylebox_override("panel", style)
	parent.add_child(frame)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	frame.add_child(stats)
	for entry in [["VIDA", data.max_health, 420.0, Color("#f18a98")], ["DANO", data.damage, 30.0, Color("#edc282")], ["PASSO", data.speed, 310.0, Color("#8ddcc0")]]:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 1)
		stats.add_child(column)
		var label := _label(str(entry[0]), 9, ART.MUTED)
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(label)
		var value := _label(str(roundi(float(entry[1]))), 12 if compact else 15, entry[3])
		value.name = "BaseStat_%s_%s" % [data.id, entry[0]]
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(value)
		var bar := _bar(entry[3], entry[2], 4)
		bar.value = float(entry[1])
		column.add_child(bar)

func change_page(delta: int) -> void:
	page_index += delta
	refresh()

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
	button.action_font_size = 11 if compact else 12
	button.custom_minimum_size.y = height
	return button

func _bar(color: Color, maximum: float, height: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = maximum
	bar.custom_minimum_size.y = height
	var track := ART.panel(Color("#263c36"), 0)
	track.set_border_width_all(0)
	bar.add_theme_stylebox_override("background", track)
	var fill := ART.panel(color, 0)
	fill.set_border_width_all(0)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

class CharacterStage extends Control:
	const FOREST := preload("res://assets/art/home-portal.png")
	const PORTRAIT := preload("res://scripts/ui/menu_portrait.gd")
	var class_id := "warrior"
	var accent := ART.GOLD
	var locked := false
	var actor: Control
	func _ready() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		clip_contents = true
		actor = PORTRAIT.new()
		actor.class_id = class_id
		actor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		actor.offset_top = 2
		actor.offset_bottom = -7
		actor.modulate = Color(0.75, 0.8, 0.76) if locked else Color(1.1, 1.08, 1.0)
		add_child(actor)
		resized.connect(queue_redraw)
	func _draw() -> void:
		var bounds := Rect2(Vector2.ZERO, size)
		var source := Rect2(Vector2(FOREST.get_width() * 0.32, FOREST.get_height() * 0.25), Vector2(FOREST.get_width() * 0.35, FOREST.get_height() * 0.65))
		draw_texture_rect_region(FOREST, bounds, source, Color(0.55, 0.62, 0.56))
		draw_rect(bounds, Color(accent.darkened(0.65), 0.4))
		var center := Vector2(size.x * 0.5, size.y - 15)
		var radius := minf(size.x * 0.38, size.y * 0.5)
		var stones := PackedVector2Array()
		for index in 13:
			var angle := index * TAU / 12
			stones.append(center + Vector2(cos(angle) * radius, sin(angle) * radius * 0.22))
		draw_colored_polygon(stones, Color("#34423a"))
		draw_polyline(stones, Color(accent, 0.55), 1, true)
		draw_line(Vector2(15, size.y - 1), Vector2(size.x - 15, size.y - 1), Color(accent, 0.45), 1, true)
