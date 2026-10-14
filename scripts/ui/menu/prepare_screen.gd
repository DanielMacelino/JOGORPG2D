extends VBoxContainer
signal page_requested(page: String)
const ART := preload("res://scripts/ui/wild_theme.gd")
const HOME := preload("res://scripts/ui/menu/home_screen.gd")
var class_id := "warrior"
var map_id := "verdant_reach"
var phase := 1
var body: GridContainer
var hero: PanelContainer
var hero_content: GridContainer
var portrait: Control
var cards: GridContainer
var footer: HFlowContainer

func _ready() -> void:
	name = "PrepareScreen"
	size_flags_horizontal = SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 12)
	body = GridContainer.new()
	body.add_theme_constant_override("h_separation", 16)
	body.add_theme_constant_override("v_separation", 12)
	body.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(body)
	hero = PanelContainer.new()
	hero.name = "PrepareHero"
	hero.size_flags_horizontal = SIZE_EXPAND_FILL
	var frame := ART.panel(Color("#071512", 0.90), 16)
	frame.border_color = Color(ART.GOLD, 0.65)
	hero.add_theme_stylebox_override("panel", frame)
	body.add_child(hero)
	hero_content = GridContainer.new()
	hero_content.add_theme_constant_override("h_separation", 16)
	hero_content.add_theme_constant_override("v_separation", 12)
	hero.add_child(hero_content)
	portrait = ClassPortrait.new()
	portrait.class_id = class_id
	portrait.size_flags_horizontal = SIZE_EXPAND_FILL
	portrait.size_flags_vertical = SIZE_EXPAND_FILL
	hero_content.add_child(portrait)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 10)
	hero_content.add_child(info)
	var data: ClassData = ContentCatalog.classes[class_id]
	info.add_child(_label("◇", 30, ART.GOLD))
	info.add_child(_label(data.display_name, 28, ART.TEXT, true))
	info.add_child(_label("NÍVEL %d" % TalentManager.character_level(class_id), 13, ART.GOLD))
	info.add_child(_label(data.description, 13, ART.MUTED))
	# These are the class's base attributes, matching its description and selection page.
	for stat in [["VIDA", data.max_health, 500.0, Color("#ce7967")], ["DANO", data.damage, 35.0, ART.GOLD], ["PASSO", data.speed, 350.0, Color("#80bfa7")]]:
		var row := HBoxContainer.new()
		info.add_child(row)
		var title := _label(str(stat[0]), 11, ART.MUTED)
		title.size_flags_horizontal = SIZE_EXPAND_FILL
		row.add_child(title)
		var value := _label(str(roundi(float(stat[1]))), 13, ART.GOLD)
		value.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(value)
		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 5
		bar.max_value = float(stat[2])
		bar.value = float(stat[1])
		bar.show_percentage = false
		var track := ART.panel(Color("#2c4037"), 0)
		track.set_border_width_all(0)
		var fill := ART.panel(stat[3], 0)
		fill.set_border_width_all(0)
		bar.add_theme_stylebox_override("background", track)
		bar.add_theme_stylebox_override("fill", fill)
		info.add_child(bar)
	info.add_child(_label("ATRIBUTOS BASE DA CLASSE", 9, ART.MUTED))
	var view := HOME.OrnateAction.new()
	view.name = "PrepareViewCharacter"
	view.text = "VER PERSONAGEM  →"
	view.custom_minimum_size.y = 38
	view.action_font_size = 11
	view.pressed.connect(func() -> void: page_requested.emit("characters"))
	info.add_child(view)
	cards = GridContainer.new()
	cards.name = "PrepareNavigation"
	cards.size_flags_horizontal = SIZE_EXPAND_FILL
	cards.add_theme_constant_override("h_separation", 12)
	cards.add_theme_constant_override("v_separation", 12)
	body.add_child(cards)
	for entry in [["Personagem", "characters", "Veja suas classes, atributos e aparência."], ["Arsenal", "inventory", "Gerencie suas armas e itens de combate."], ["Talentos", "talents", "Desbloqueie e evolua suas habilidades."], ["Melhorias", "upgrades", "Fortaleça seus atributos e recursos."], ["Forja", "forge", "Crie e aprimore equipamentos com materiais."], ["Relíquias", "relics", "Descubra e ative poderosos artefatos."]]:
		var tile := PrepareTile.new()
		tile.custom_minimum_size.y = 142
		tile.title = str(entry[0])
		tile.page = str(entry[1])
		tile.summary = str(entry[2])
		tile.size_flags_horizontal = SIZE_EXPAND_FILL
		tile.pressed.connect(func() -> void: page_requested.emit(tile.page))
		cards.add_child(tile)
	footer = HFlowContainer.new()
	footer.name = "PrepareSummary"
	footer.add_theme_constant_override("h_separation", 12)
	footer.add_theme_constant_override("v_separation", 8)
	add_child(footer)
	var equipped := 0
	for item in SaveManager.loadout_for(class_id).values():
		if not str(item).is_empty():
			equipped += 1
	var points := maxi(0, TalentManager.character_level(class_id) - TalentManager.spent_points(class_id))
	var destination: MapData = ContentCatalog.maps[map_id]
	for entry in [["EQUIPAMENTO", "%d/6" % equipped], ["PONTOS DISPONÍVEIS", str(points)], ["PRÓXIMA EXPEDIÇÃO", "REGIÃO %02d · FASE %02d/10" % [destination.stage_index + 1, phase]]]:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = SIZE_EXPAND_FILL
		var style := ART.panel(Color("#071512", 0.82), 10)
		style.border_color = Color(ART.GOLD, 0.4)
		panel.add_theme_stylebox_override("panel", style)
		var details := VBoxContainer.new()
		panel.add_child(details)
		details.add_child(_label(str(entry[0]), 9, ART.MUTED))
		details.add_child(_label(str(entry[1]), 14, ART.GOLD, true))
		footer.add_child(panel)
	resized.connect(_adapt_layout)
	call_deferred("_adapt_layout")

func _adapt_layout() -> void:
	if body == null or size.x <= 0:
		return
	var wide := size.x >= 850
	body.columns = 2 if wide else 1
	hero.custom_minimum_size.x = floorf(size.x * 0.42) if wide else 0
	hero_content.columns = 2 if (size.x >= 500) else 1
	portrait.custom_minimum_size = Vector2(135 if wide else 0, 300 if wide else 220)
	cards.columns = 2 if size.x >= 480 else 1
	for panel in footer.get_children():
		panel.custom_minimum_size.x = floorf((size.x - 24) / 3) if size.x >= 600 else size.x

func _label(value: String, font_size: int, color: Color, serif: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", roundi(font_size * clampf(float(SaveManager.data.settings.get("ui_scale", 1)), 0.85, 1.2)))
	label.add_theme_color_override("font_color", color)
	if serif:
		label.add_theme_font_override("font", ART.title_font())
	return label

class PrepareTile extends Button:
	var title := ""
	var page := ""
	var summary := ""
	var illustration: Texture2D
	var emblem: Texture2D
	var title_label: Label
	var copy_label: Label
	var text_start := 70.0
	func _ready() -> void:
		clip_contents = true
		illustration = load("res://assets/art/prepare-workshop.png") if page in ["inventory", "forge", "upgrades"] else load("res://assets/art/home-portal.png")
		emblem = load("res://assets/art/icons/" + page + ".svg")
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tooltip_text = title + ": " + summary
		for state in ["normal", "hover", "pressed", "focus"]:
			add_theme_stylebox_override(state, StyleBoxEmpty.new())
		title_label = Label.new()
		title_label.text = title
		title_label.mouse_filter = MOUSE_FILTER_IGNORE
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_label.add_theme_font_override("font", ART.title_font())
		var text_scale := clampf(float(SaveManager.data.settings.get("ui_scale", 1)), 0.85, 1.2)
		title_label.add_theme_font_size_override("font_size", roundi(19 * text_scale))
		title_label.add_theme_color_override("font_color", ART.TEXT)
		add_child(title_label)
		copy_label = Label.new()
		copy_label.text = summary
		copy_label.mouse_filter = MOUSE_FILTER_IGNORE
		copy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy_label.add_theme_font_size_override("font_size", roundi(11 * text_scale))
		copy_label.add_theme_color_override("font_color", ART.MUTED)
		add_child(copy_label)
		resized.connect(_layout_text)
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
		_layout_text()
	func _layout_text() -> void:
		var text_width := maxf(1, size.x - 83)
		title_label.size = Vector2(text_width, 0)
		copy_label.size = Vector2(text_width, 0)
		var title_height := title_label.get_minimum_size().y
		var copy_height := copy_label.get_minimum_size().y
		var block_height := title_height + copy_height + 23
		custom_minimum_size.y = maxf(142, 64 + block_height)
		text_start = maxf(64, size.y - block_height)
		title_label.position = Vector2(62, text_start + 5)
		copy_label.position = Vector2(62, text_start + title_height + 10)
		queue_redraw()
	func _draw() -> void:
		var bounds := Rect2(Vector2.ONE, size - Vector2(2, 2))
		if illustration != null:
			var focal: Vector2 = {"characters": Vector2(0.64, 0.58), "inventory": Vector2(0.24, 0.48), "talents": Vector2(0.44, 0.40), "upgrades": Vector2(0.83, 0.44), "forge": Vector2(0.75, 0.5), "relics": Vector2(0.80, 0.60)}[page]
			var extent := Vector2(illustration.get_width() * 0.58, illustration.get_width() * 0.58 * size.y / maxf(1, size.x))
			extent.y = minf(extent.y, illustration.get_height())
			extent.x = extent.y * size.x / maxf(1, size.y)
			var start := focal * illustration.get_size() - extent * 0.5
			start.x = clampf(start.x, 0, illustration.get_width() - extent.x)
			start.y = clampf(start.y, 0, illustration.get_height() - extent.y)
			draw_texture_rect_region(illustration, bounds, Rect2(start, extent), Color(0.78, 0.85, 0.77))
			draw_rect(bounds, Color("#03100d", 0.30))
			draw_rect(Rect2(1, text_start, size.x - 2, size.y - text_start - 1), Color("#03100d", 0.90))
		draw_rect(bounds, ART.GOLD if is_hovered() or has_focus() else Color("#847958"), false, 1)
		var center := Vector2(30, size.y * 0.66)
		draw_polyline(PackedVector2Array([center + Vector2(0, -23), center + Vector2(23, 0), center + Vector2(0, 23), center + Vector2(-23, 0), center + Vector2(0, -23)]), ART.GOLD, 1, true)
		if emblem != null:
			draw_texture_rect(emblem, Rect2(center - Vector2(12, 12), Vector2(24, 24)), false, ART.GOLD)
		draw_line(Vector2(size.x - 22, size.y - 22), Vector2(size.x - 12, size.y - 22), ART.GOLD, 1, true)
		draw_polyline(PackedVector2Array([Vector2(size.x - 17, size.y - 27), Vector2(size.x - 12, size.y - 22), Vector2(size.x - 17, size.y - 17)]), ART.GOLD, 1, true)

class ClassPortrait extends "res://scripts/ui/menu_portrait.gd":
	const SENTINEL := preload("res://assets/art/prepare-sentinel.png")
	const FOREST := preload("res://assets/art/home-portal.png")
	func _ready() -> void:
		super._ready()
		clip_contents = true
	func _draw() -> void:
		if class_id == "warrior":
			var extent := SENTINEL.get_size() * minf(size.x / SENTINEL.get_width(), size.y / SENTINEL.get_height())
			draw_texture_rect(SENTINEL, Rect2((size - extent) * 0.5, extent), false)
		else:
			var extent := FOREST.get_size() * maxf(size.x / FOREST.get_width(), size.y / FOREST.get_height())
			draw_texture_rect(FOREST, Rect2((size - extent) * 0.5, extent), false, Color(0.35, 0.43, 0.36))
			super._draw()
