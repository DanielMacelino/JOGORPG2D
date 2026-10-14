extends VBoxContainer
signal page_requested(page: String)
signal back_requested
const ART := preload("res://scripts/ui/wild_theme.gd")
const HOME := preload("res://scripts/ui/menu/home_screen.gd")
var header: GridContainer
var cards: GridContainer

func _ready() -> void:
	name = "RecordsScreen"
	size_flags_horizontal = SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 14)
	header = GridContainer.new()
	header.add_theme_constant_override("h_separation", 20)
	header.add_theme_constant_override("v_separation", 10)
	add_child(header)
	var back := HOME.OrnateAction.new()
	back.name = "RecordsBack"
	back.text = "←  VOLTAR"
	back.custom_minimum_size = Vector2(122, 40)
	back.size_flags_vertical = SIZE_SHRINK_BEGIN
	back.action_font_size = 13
	back.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back)
	var heading := HBoxContainer.new()
	heading.size_flags_horizontal = SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 14)
	header.add_child(heading)
	var emblem := CompassEmblem.new()
	emblem.custom_minimum_size = Vector2(50, 50)
	heading.add_child(emblem)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 0)
	heading.add_child(titles)
	titles.add_child(_label("REGISTROS", 30, ART.GOLD, true))
	titles.add_child(_label("Suas histórias, conquistas e criaturas encontradas.", 14, ART.TEXT))
	add_child(Rule.new())
	var currencies := HFlowContainer.new()
	currencies.add_theme_constant_override("h_separation", 20)
	currencies.add_theme_constant_override("v_separation", 8)
	add_child(currencies)
	for text in ["◇  OURO DE VÉSPERA  %d" % int(SaveManager.data.gold), "│", "◈  CRISTAIS  %d" % int(SaveManager.data.crystals)]:
		var currency := _label(text, 12, ART.GOLD)
		currency.name = "RecordsCurrency" + str(currencies.get_child_count())
		currency.autowrap_mode = TextServer.AUTOWRAP_OFF
		currencies.add_child(currency)
	add_child(Rule.new())
	cards = GridContainer.new()
	cards.name = "RecordsCards"
	cards.size_flags_horizontal = SIZE_EXPAND_FILL
	cards.add_theme_constant_override("h_separation", 14)
	cards.add_theme_constant_override("v_separation", 14)
	add_child(cards)
	var discovered := 0
	for id in ContentCatalog.enemies:
		if int(SaveManager.data.bestiary_kills.get(str(id), 0)) > 0: discovered += 1
	var completed := 0
	for bounty in ContentCatalog.bounties:
		if SaveManager.data.completed_bounties.has(str(bounty.id)): completed += 1
	var entries := [
		["Bestiário", "bestiary", "Descubra e registre todas as criaturas encontradas em sua jornada.", discovered, ContentCatalog.enemies.size(), "bestiary"],
		["Conquistas", "achievements", "Complete desafios e desbloqueie conquistas especiais.", SaveManager.get_achievement_count(), ContentCatalog.achievements.size(), "achievements"],
		["Caçadas", "bounties", "Registre as criaturas mais perigosas e raras que você derrotou.", completed, ContentCatalog.bounties.size(), "bounties"],
		["Estatísticas", "statistics", "Acompanhe seu progresso, desempenho e dados da sua jornada.", -1, 0, "statistics"]]
	for entry in entries:
		var tile := RecordTile.new()
		tile.name = "Record_" + str(entry[1])
		tile.page = str(entry[1])
		tile.art_name = str(entry[5])
		tile.featured = tile.page == "bestiary"
		tile.progress_current = int(entry[3])
		tile.progress_total = int(entry[4])
		tile.setup(str(entry[0]), str(entry[2]))
		tile.pressed.connect(func() -> void: page_requested.emit(tile.page))
		cards.add_child(tile)
	resized.connect(_adapt)
	call_deferred("_adapt")

func _adapt() -> void:
	if cards == null or size.x <= 0: return
	header.columns = 2 if size.x >= 600 else 1
	cards.columns = 3 if size.x >= 900 else (2 if size.x >= 580 else 1)
	for tile in cards.get_children():
		tile._fit()

func _label(text: String, pixels: int, color: Color, serif := false) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", ART.title_font() if serif else ART.body_font())
	label.add_theme_font_size_override("font_size", pixels)
	label.add_theme_color_override("font_color", color)
	return label

class Rule extends Control:
	func _ready() -> void:
		custom_minimum_size.y = 9
		mouse_filter = MOUSE_FILTER_IGNORE
	func _draw() -> void:
		draw_line(Vector2(0, 4), Vector2(size.x, 4), Color(ART.GOLD, 0.30), 1, true)
		for x in [3.0, size.x - 3]:
			draw_polyline(PackedVector2Array([Vector2(x, 1), Vector2(x + 3, 4), Vector2(x, 7), Vector2(x - 3, 4), Vector2(x, 1)]), Color(ART.GOLD, 0.65), 1, true)

class CompassEmblem extends Control:
	func _ready() -> void: mouse_filter = MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var center := size * 0.5
		draw_arc(center, 22, 0, TAU, 48, Color(ART.GOLD, 0.75), 1.5, true)
		for index in 8:
			var axis := Vector2.UP.rotated(index * TAU / 8)
			var side := axis.orthogonal()
			draw_colored_polygon(PackedVector2Array([center + axis * 27, center + axis * 7 + side * 4, center, center + axis * 7 - side * 4]), Color(ART.GOLD, 0.9 if index % 2 == 0 else 0.5))
		draw_circle(center, 3, ART.GOLD)

class RecordTile extends Button:
	var page := "bestiary"
	var art_name := "bestiary"
	var featured := false
	var progress_current := 0
	var progress_total := 0
	var title_text := ""
	var summary_text := ""
	var art: Texture2D
	var emblem_texture: Texture2D
	var glow := 0.0
	var hover_tween: Tween
	var details: VBoxContainer
	var track_style: StyleBoxFlat
	var fill_style: StyleBoxFlat

	func setup(title: String, summary: String) -> void:
		title_text = title
		summary_text = summary
		custom_minimum_size.x = 220
		size_flags_horizontal = SIZE_EXPAND_FILL

	func _ready() -> void:
		art = load("res://assets/art/records-" + art_name + ".png")
		emblem_texture = load("res://assets/art/icons/" + ("records-bestiary" if page == "bestiary" else page) + ".svg")
		track_style = ART.panel(Color("#1c2b27"), 0)
		fill_style = ART.panel(ART.GOLD, 0)
		fill_style.set_border_width_all(0)
		mouse_default_cursor_shape = CURSOR_POINTING_HAND
		tooltip_text = "Abrir " + title_text
		for state in ["normal", "hover", "pressed", "focus"]: add_theme_stylebox_override(state, StyleBoxEmpty.new())
		var inset := MarginContainer.new()
		inset.mouse_filter = MOUSE_FILTER_IGNORE
		inset.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		for edge in ["left", "right"]: inset.add_theme_constant_override("margin_" + edge, 22)
		inset.add_theme_constant_override("margin_top", 24)
		inset.add_theme_constant_override("margin_bottom", 17)
		add_child(inset)
		details = VBoxContainer.new()
		details.mouse_filter = MOUSE_FILTER_IGNORE
		details.add_theme_constant_override("separation", 6)
		inset.add_child(details)
		var icon_space := Control.new()
		icon_space.mouse_filter = MOUSE_FILTER_IGNORE
		icon_space.custom_minimum_size.y = 62
		details.add_child(icon_space)
		var title := Label.new()
		title.text = title_text
		title.add_theme_font_override("font", ART.title_font())
		title.add_theme_font_size_override("font_size", 24)
		title.add_theme_color_override("font_color", ART.TEXT)
		title.mouse_filter = MOUSE_FILTER_IGNORE
		details.add_child(title)
		var summary := Label.new()
		summary.text = summary_text
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary.add_theme_font_override("font", ART.body_font())
		summary.add_theme_font_size_override("font_size", 13)
		summary.add_theme_color_override("font_color", ART.TEXT)
		summary.mouse_filter = MOUSE_FILTER_IGNORE
		var summary_margin := MarginContainer.new()
		summary_margin.mouse_filter = MOUSE_FILTER_IGNORE
		summary_margin.add_theme_constant_override("margin_right", 30)
		details.add_child(summary_margin)
		summary_margin.add_child(summary)
		if progress_current >= 0:
			var count := Label.new()
			count.name = "RecordProgress"
			count.text = "%d / %d" % [progress_current, progress_total]
			count.add_theme_font_size_override("font_size", 11)
			count.add_theme_color_override("font_color", ART.GOLD)
			count.mouse_filter = MOUSE_FILTER_IGNORE
			details.add_child(count)
		resized.connect(queue_redraw)
		resized.connect(_fit)
		details.minimum_size_changed.connect(_fit)
		mouse_entered.connect(_animate.bind(1.0))
		mouse_exited.connect(_animate.bind(0.0))
		focus_entered.connect(_animate.bind(1.0))
		focus_exited.connect(_animate.bind(0.0))
		call_deferred("_fit")

	func _fit() -> void:
		if details == null: return
		custom_minimum_size.y = maxf(216 if page != "statistics" else 184, details.get_combined_minimum_size().y + 41 + (10 if progress_current >= 0 else 0))

	func _animate(value: float) -> void:
		if hover_tween != null: hover_tween.kill()
		hover_tween = create_tween()
		hover_tween.tween_method(func(amount: float) -> void: glow = amount; queue_redraw(), glow, value, 0.16)

	func _draw() -> void:
		var bounds := Rect2(Vector2.ONE, size - Vector2.ONE * 2)
		if art != null:
			var factor := maxf(bounds.size.x / art.get_width(), bounds.size.y / art.get_height())
			var crop := bounds.size / factor
			draw_texture_rect_region(art, bounds, Rect2((art.get_size() - crop) * 0.5, crop))
		draw_rect(bounds, Color("#02100e", 0.22))
		# Transparent gradients retain the artwork while keeping text readable.
		for index in 32:
			var fraction := float(index) / 31
			draw_rect(Rect2(1, 1 + fraction * (size.y - 2), size.x - 2, (size.y - 2) / 31 + 1), Color("#02100e", 0.10 + fraction * 0.65))
		var intensity := maxf(glow, 0.7 if featured else 0)
		for width in [7.0, 4.0]: draw_rect(bounds.grow(-1), Color(ART.GOLD, intensity * 0.05), false, width)
		draw_rect(bounds, Color(ART.GOLD, 0.48 + intensity * 0.52), false, 2 if featured or glow > 0.5 else 1)
		for corner in [Vector2(5, 5), Vector2(size.x - 5, 5), Vector2(5, size.y - 5), size - Vector2(5, 5)]:
			var toward := Vector2(1 if corner.x < size.x * 0.5 else -1, 1 if corner.y < size.y * 0.5 else -1)
			draw_polyline(PackedVector2Array([corner + Vector2(0, toward.y * 11), corner, corner + Vector2(toward.x * 11, 0)]), Color(ART.GOLD, 0.85), 1, true)
			draw_arc(corner + toward * 3, 4, 0, TAU, 12, Color(ART.GOLD, 0.50), 1, true)
		var center := Vector2(49, 52)
		var seal := PackedVector2Array()
		for index in 12: seal.append(center + Vector2.UP.rotated(index * TAU / 12) * (29 if index % 2 == 0 else 27))
		draw_colored_polygon(seal, Color("#061310", 0.82))
		var outline := seal.duplicate()
		outline.append(seal[0])
		draw_polyline(outline, Color(ART.GOLD, 0.80), 1.5, true)
		if emblem_texture != null: draw_texture_rect(emblem_texture, Rect2(center - Vector2(16, 16), Vector2(32, 32)), false, ART.GOLD)
		var arrow := Vector2(size.x - 33, size.y - (39 if progress_current >= 0 else 32))
		draw_line(arrow - Vector2(12, 0), arrow + Vector2(6, 0), ART.GOLD, 1.5, true)
		draw_polyline(PackedVector2Array([arrow + Vector2(-1, -7), arrow + Vector2(6, 0), arrow + Vector2(-1, 7)]), ART.GOLD, 1.5, true)
		if progress_current >= 0:
			var track := Rect2(33, size.y - 19, maxf(1, size.x - 124), 5)
			draw_style_box(track_style, track)
			var fill := track
			fill.size.x *= clampf(float(progress_current) / maxf(1, progress_total), 0, 1)
			if fill.size.x > 0: draw_style_box(fill_style, fill)
			draw_polyline(PackedVector2Array([Vector2(25, size.y - 19), Vector2(28, size.y - 16.5), Vector2(25, size.y - 14), Vector2(22, size.y - 16.5), Vector2(25, size.y - 19)]), ART.GOLD, 1, true)
