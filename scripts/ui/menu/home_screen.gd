extends VBoxContainer
signal start_requested
signal page_requested(page: String)
const ART := preload("res://scripts/ui/wild_theme.gd")
var class_id := "warrior"
var map_id := "verdant_reach"
var phase := 1
var difficulty := 0
var navigation: HFlowContainer
var hero_row: HBoxContainer
var copy_column: VBoxContainer
var vista_space: Control
var story_label: Label
var logo_control: Control

func _ready() -> void:
	name = "HomeScreen"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	var width := get_viewport_rect().size.x
	var short := get_viewport_rect().size.y < 620.0
	var narrow := width < 620.0
	add_theme_constant_override("separation", 6 if short else (8 if narrow else 10))
	var header := HFlowContainer.new()
	header.custom_minimum_size.y = 28
	add_child(header)
	header.add_theme_constant_override("h_separation", 10)
	header.add_theme_constant_override("v_separation", 6)
	var resources := _label("✧  %d     │     ◇  %d" % [SaveManager.data.gold, SaveManager.data.crystals], 14, ART.TEXT)
	resources.autowrap_mode = TextServer.AUTOWRAP_OFF
	header.add_child(resources)
	var settings := _action("CONFIGURAÇÕES", false, 38)
	settings.name = "HomeSettings"
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.action_font_size = 11
	settings.icon = preload("res://assets/art/icons/settings.svg")
	settings.add_theme_constant_override("icon_max_width", 16)
	settings.expand_icon = true
	settings.pressed.connect(func() -> void: page_requested.emit("settings"))
	var online := _action("JOGAR ONLINE", false, 38)
	online.name = "HomeOnline"
	online.action_font_size = 11
	online.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	online.icon = preload("res://assets/art/icons/characters.svg")
	online.add_theme_constant_override("icon_max_width", 16)
	online.expand_icon = true
	online.pressed.connect(func() -> void: page_requested.emit("online"))
	var hero := HBoxContainer.new()
	hero.name = "HomeHero"
	hero_row = hero
	hero.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	add_child(hero)
	var left := VBoxContainer.new()
	copy_column = left
	left.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	left.custom_minimum_size.x = 0 if narrow else (340 if short else 425)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL if narrow else Control.SIZE_FILL
	left.add_theme_constant_override("separation", 5 if short else 9)
	hero.add_child(left)
	var logo := Wordmark.new()
	logo_control = logo
	logo.custom_minimum_size = Vector2(0, 74 if short else 96)
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(logo)
	var destination: MapData = ContentCatalog.maps[map_id]
	left.add_child(_label("◇  REGIÃO %s · FASE %02d/10 · %s" % [["I", "II", "III", "IV", "V", "VI"][destination.stage_index], phase, CampaignRules.difficulty_name(difficulty).to_upper()], 10, ART.GOLD))
	var story := _label("A floresta\nse lembra.", 31 if short else (40 if narrow else 45), ART.TEXT)
	story_label = story
	story.add_theme_font_override("font", ART.title_font())
	left.add_child(story)
	left.add_child(_label("Atravesse a noite. Encontre a centelha.\nVolte com uma história para contar.", 12 if short else 14, ART.MUTED))
	var breathing := Control.new()
	breathing.custom_minimum_size.y = 3 if short else 6
	left.add_child(breathing)
	var play := _action("INICIAR EXPEDIÇÃO   →", true, 38 if short else 44)
	play.name = "HomePlay"
	play.pressed.connect(func() -> void: start_requested.emit())
	var actions := VBoxContainer.new()
	actions.name = "HomeActions"
	actions.add_theme_constant_override("separation", 8)
	left.add_child(actions)
	actions.add_child(play)
	var prepare := _action("PREPARAR PERSONAGEM", false, 36 if short else 40)
	prepare.name = "HomePrepare"
	prepare.pressed.connect(func() -> void: page_requested.emit("prepare"))
	actions.add_child(prepare)
	var utilities := HBoxContainer.new()
	utilities.name = "HomeUtilities"
	utilities.add_theme_constant_override("separation", 8)
	actions.add_child(utilities)
	utilities.add_child(online)
	utilities.add_child(settings)
	online.size_flags_vertical = Control.SIZE_FILL
	settings.size_flags_vertical = Control.SIZE_FILL
	vista_space = Control.new()
	vista_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.add_child(vista_space)
	add_child(_line())
	var identity := HBoxContainer.new()
	identity.name = "HomeIdentity"
	identity.add_theme_constant_override("separation", 14)
	identity.custom_minimum_size.y = 49 if short else 54
	add_child(identity)
	var portrait := preload("res://scripts/ui/menu_portrait.gd").new()
	portrait.class_id = class_id
	portrait.custom_minimum_size = Vector2(44, 52)
	identity.add_child(portrait)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.custom_minimum_size.x = 0
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	details.add_theme_constant_override("separation", 3)
	identity.add_child(details)
	var subtitle: String = {"warrior": "Vigília e Aço", "mage": "Éter e Centelha", "ranger": "Rastro e Vendaval", "assassin": "Sombra e Lâmina", "druid": "Seiva e Matilha", "paladin": "Juramento e Aurora"}[class_id]
	var name_label := _label(ContentCatalog.classes[class_id].display_name + " · " + subtitle, 13, ART.GOLD)
	name_label.add_theme_font_override("font", ART.title_font())
	details.add_child(name_label)
	var points := maxi(0, TalentManager.character_level(class_id) - TalentManager.spent_points(class_id))
	details.add_child(_label("NÍVEL %02d   │   ◇ %d ponto%s de talento disponível%s" % [TalentManager.character_level(class_id), points, "" if points == 1 else "s", "" if points == 1 else "s"], 10, ART.MUTED))
	var records := _label("MELHOR ONDA  %02d     │     CONQUISTAS  %d/%d" % [SaveManager.data.best_wave, SaveManager.get_achievement_count(), ContentCatalog.achievements.size()], 9, ART.GOLD)
	details.add_child(records)
	add_child(_line())
	navigation = HFlowContainer.new()
	navigation.name = "HomeNavigation"
	navigation.add_theme_constant_override("h_separation", 8)
	navigation.add_theme_constant_override("v_separation", 8)
	navigation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(navigation)
	var entries := [["PERSONAGEM", "characters"], ["ARSENAL", "inventory"], ["TALENTOS", "talents"], ["MUNDO", "maps"], ["REGISTROS", "records"]]
	for index in entries.size():
		var tile := HomeTile.new()
		tile.title = entries[index][0]
		tile.page = entries[index][1]
		tile.featured = index == 0
		tile.custom_minimum_size = Vector2(0, 78 if short or narrow else 100)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.pressed.connect(func() -> void: page_requested.emit(tile.page))
		navigation.add_child(tile)
	resized.connect(_adapt_layout)
	call_deferred("_adapt_layout")

func _adapt_layout() -> void:
	if copy_column == null or size.x <= 0:
		return
	var width := size.x
	var short := get_viewport_rect().size.y < 620
	var stacked := width < 700
	copy_column.custom_minimum_size.x = 0 if stacked else clampf(width * 0.46, 320, 460)
	copy_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL if stacked else Control.SIZE_SHRINK_BEGIN
	vista_space.visible = not stacked
	logo_control.custom_minimum_size.y = 68 if short else 82
	story_label.add_theme_font_size_override("font_size", roundi((30 if short else (35 if stacked else 40)) * clampf(float(SaveManager.data.settings.get("ui_scale", 1)), 0.85, 1.2)))
	copy_column.add_theme_constant_override("separation", 6 if short else 8)
	var columns := 5 if width >= 1000 else (3 if width >= 600 else (2 if width >= 340 else 1))
	var card_width := floorf((width - float(columns - 1) * 8.0) / columns)
	for tile in navigation.get_children():
		tile.custom_minimum_size = Vector2(card_width, 74 if short else 84)

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", roundi(font_size * clampf(float(SaveManager.data.settings.get("ui_scale", 1)), 0.85, 1.2)))
	label.add_theme_color_override("font_color", color)
	return label

func _action(value: String, primary: bool, height: float) -> Button:
	var button := OrnateAction.new()
	button.text = value
	button.primary = primary
	button.custom_minimum_size.y = height
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	return button

func _line() -> HSeparator:
	var line := HSeparator.new()
	var style := StyleBoxLine.new()
	style.color = Color(ART.GOLD, 0.30)
	style.thickness = 1
	line.add_theme_stylebox_override("separator", style)
	return line

class Wordmark extends Control:
	var font: Font
	func _ready() -> void:
		font = ART.title_font()
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		if font == null:
			return
		var text_width := font.get_string_size("ASHENWILD", HORIZONTAL_ALIGNMENT_LEFT, -1, 66).x
		var font_size := clampi(floori(66.0 * size.x / maxf(1, text_width)), 24, 66)
		var baseline := size.y * 0.67
		draw_string(font, Vector2(0, baseline), "ASHENWILD", HORIZONTAL_ALIGNMENT_LEFT, size.x, font_size, Color("#f5dfb6"))
		draw_string(font, Vector2(2, size.y - 8), "R I F T B O U N D   S U R V I V O R S", HORIZONTAL_ALIGNMENT_CENTER, size.x - 4, 9, Color("#e4d5b7"))
		draw_line(Vector2(0, size.y - 1), Vector2(size.x, size.y - 1), Color(ART.GOLD, 0.38), 1, true)

class OrnateAction extends Button:
	var primary := false
	var action_font_size := 13
	func _ready() -> void:
		ART.apply_button(self, primary, ART.title_font())
		add_theme_font_size_override("font_size", action_font_size)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(func() -> void: create_tween().tween_property(self, "modulate", Color(1.06, 1.06, 1.06), 0.15))
		mouse_exited.connect(func() -> void: create_tween().tween_property(self, "modulate", Color.WHITE, 0.15))
		var style := ART.panel(Color("#dfb471") if primary else Color("#081614", 0.6), 10)
		style.border_color = Color("#d5ae68")
		style.content_margin_top = 7
		style.content_margin_bottom = 7
		style.set_corner_radius_all(1)
		add_theme_stylebox_override("normal", style)
	func _draw() -> void:
		var color := Color("#8b642e", 0.7) if primary else Color("#d5ae68", 0.65)
		for point in [Vector2(3, 3), size - Vector2(3, 3)]:
			var sign_value := 1.0 if point.x < size.x * 0.5 else -1.0
			draw_polyline(PackedVector2Array([point + Vector2(0, sign_value * 10), point, point + Vector2(sign_value * 10, 0)]), color, 1, true)

class HomeTile extends Button:
	const BACKGROUND := preload("res://assets/art/home-portal.png")
	var title := "PERSONAGEM"
	var page := "characters"
	var featured := false
	var font: Font
	var emblem: Texture2D
	func _ready() -> void:
		font = ART.title_font()
		var icon_name := "statistics" if page == "records" else page
		emblem = load("res://assets/art/icons/" + icon_name + ".svg")
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for state in ["normal", "hover", "pressed", "focus"]:
			add_theme_stylebox_override(state, StyleBoxEmpty.new())
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
	func _draw() -> void:
		var bounds := Rect2(Vector2(1, 1), size - Vector2(2, 2))
		var center: Vector2 = {"characters": Vector2(0.64, 0.57), "inventory": Vector2(0.80, 0.66), "talents": Vector2(0.42, 0.4), "maps": Vector2(0.67, 0.28), "records": Vector2(0.78, 0.7)}[page]
		var extent := Vector2(BACKGROUND.get_width() * 0.34, BACKGROUND.get_width() * 0.34 * size.y / maxf(1, size.x))
		var start := center * BACKGROUND.get_size() - extent * 0.5
		start.x = clampf(start.x, 0, BACKGROUND.get_width() - extent.x)
		start.y = clampf(start.y, 0, BACKGROUND.get_height() - extent.y)
		draw_texture_rect_region(BACKGROUND, bounds, Rect2(start, extent), Color(0.65, 0.73, 0.65))
		draw_rect(bounds, Color("#04110e", 0.45))
		draw_rect(Rect2(1, size.y * 0.55, size.x - 2, size.y * 0.45 - 1), Color("#04110e", 0.55))
		var active := featured or is_hovered() or has_focus()
		draw_rect(bounds, ART.GOLD if active else Color("#566455"), false, 2 if active else 1)
		if emblem != null:
			draw_texture_rect(emblem, Rect2(19, 15, 26, 26), false, ART.GOLD)
		draw_string(font, Vector2(20, size.y - 19), title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 25, 12, ART.TEXT)
		if active:
			draw_line(Vector2(20, size.y - 10), Vector2(size.x - 20, size.y - 10), Color(ART.GOLD, 0.65), 1, true)
