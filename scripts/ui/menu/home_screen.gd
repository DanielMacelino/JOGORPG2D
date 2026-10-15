extends VBoxContainer
signal start_requested
signal page_requested(page: String)
const ART := preload("res://scripts/ui/wild_theme.gd")
const PLAQUE := preload("res://scripts/ui/menu/menu_plaque.gd")
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
	var height := get_viewport_rect().size.y
	var tiny := height < 520
	var short := height < 620 or (width < 420 and height < 720)
	var narrow := width < 620.0
	add_theme_constant_override("separation", 4 if tiny else (6 if short else (8 if narrow else 10)))
	var header := HFlowContainer.new()
	header.custom_minimum_size.y = 20 if tiny else 28
	add_child(header)
	header.add_theme_constant_override("h_separation", 10)
	header.add_theme_constant_override("v_separation", 6)
	var resources := _label("✧  %d     │     ◇  %d" % [SaveManager.data.gold, SaveManager.data.crystals], 10 if short else 12, ART.TEXT)
	resources.autowrap_mode = TextServer.AUTOWRAP_OFF
	header.add_child(resources)
	var settings := _action("CONFIGURAÇÕES", false, 30 if tiny else (32 if short else 38))
	settings.name = "HomeSettings"
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.action_font_size = 11
	settings.icon = preload("res://assets/art/icons/settings.svg")
	settings.add_theme_constant_override("icon_max_width", 16)
	settings.expand_icon = true
	settings.pressed.connect(func() -> void: page_requested.emit("settings"))
	var online := _action("JOGAR ONLINE", false, 30 if tiny else (32 if short else 38))
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
	var flavor := _label("Atravesse a noite. Encontre a centelha.\nVolte com uma história para contar.", 12 if short else 14, ART.MUTED)
	flavor.visible = not tiny
	left.add_child(flavor)
	var breathing := Control.new()
	breathing.custom_minimum_size.y = 3 if short else 6
	left.add_child(breathing)
	var play := _action("INICIAR EXPEDIÇÃO   →", true, 32 if tiny else (38 if short else 44))
	play.name = "HomePlay"
	play.pressed.connect(func() -> void: start_requested.emit())
	var actions := VBoxContainer.new()
	actions.name = "HomeActions"
	actions.add_theme_constant_override("separation", 8)
	left.add_child(actions)
	actions.add_child(play)
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
	portrait.custom_minimum_size = Vector2(32, 38) if tiny else Vector2(44, 52)
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
	var entries := [["PERSONAGEM", "prepare"], ["ARSENAL", "inventory"], ["TALENTOS", "talents"], ["MUNDO", "maps"], ["REGISTROS", "records"]]
	for index in entries.size():
		var tile := HomeTile.new()
		tile.title = entries[index][0]
		tile.page = entries[index][1]
		tile.plate_index = index
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
	var height := get_viewport_rect().size.y
	var tiny := height < 520
	var short := height < 620 or (get_viewport_rect().size.x < 420 and height < 720)
	var stacked := width < 560
	copy_column.custom_minimum_size.x = 0 if stacked else clampf(width * 0.42, 300, 460)
	copy_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL if stacked else Control.SIZE_SHRINK_BEGIN
	vista_space.visible = not stacked
	logo_control.custom_minimum_size.y = 46 if tiny else (68 if short else 82)
	story_label.add_theme_font_size_override("font_size", roundi((24 if tiny else (30 if short else (35 if stacked else 40))) * clampf(float(SaveManager.data.settings.get("ui_scale", 1)), 0.85, 1.2)))
	copy_column.add_theme_constant_override("separation", 4 if tiny else (6 if short else 8))
	var columns := 5 if width >= 760 or (tiny and width >= 560) else (3 if width >= 500 else 2)
	var card_width := floorf((width - float(columns - 1) * 8.0) / columns)
	for tile in navigation.get_children():
		tile.custom_minimum_size = Vector2(card_width, 48 if tiny else (62 if short and stacked else (70 if short else 86)))

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", roundi(font_size * clampf(float(SaveManager.data.settings.get("ui_scale", 1)), 0.85, 1.2)))
	label.add_theme_color_override("font_color", color)
	return label

func _action(value: String, primary: bool, height: float) -> Button:
	var button := MenuAction.new()
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
		resized.connect(queue_redraw)
	func _draw() -> void:
		if font == null:
			return
		var available := maxf(100, size.x - 47)
		var text_width := font.get_string_size("ASHENWILD", HORIZONTAL_ALIGNMENT_LEFT, -1, 66).x
		var font_size := clampi(floori(66.0 * available / maxf(1, text_width)), 24, 66)
		var baseline := size.y * 0.67
		draw_string(font, Vector2(0, baseline), "ASHENWILD", HORIZONTAL_ALIGNMENT_LEFT, available, font_size, Color("#f5dfb6"))
		var center := Vector2(size.x - 23, baseline - font_size * 0.33)
		draw_arc(center, 19, 0, TAU, 48, Color(ART.GOLD, 0.75), 1, true)
		for index in 8:
			var angle := TAU * index / 8.0 - PI * 0.5
			var tip := center + Vector2.from_angle(angle) * (23 if index % 2 == 0 else 17)
			var side := Vector2.from_angle(angle + PI * 0.5) * 3
			draw_colored_polygon(PackedVector2Array([tip, center + side, center, center - side]), Color(ART.GOLD, 0.85 if index % 2 == 0 else 0.55))
		draw_string(font, Vector2(2, size.y - 8), "R I F T B O U N D   S U R V I V O R S", HORIZONTAL_ALIGNMENT_CENTER, available, 8, Color("#e4d5b7"))
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

class MenuAction extends Button:
	var primary := false
	var action_font_size := 13
	var surface: PlateSurface
	func _ready() -> void:
		ART.apply_button(self, primary, ART.title_font())
		add_theme_font_size_override("font_size", action_font_size)
		mouse_default_cursor_shape = CURSOR_POINTING_HAND
		for state in ["normal", "hover", "pressed", "disabled"]:
			var style := ART.panel(Color.TRANSPARENT, 12)
			style.set_border_width_all(0)
			style.content_margin_top = 6
			style.content_margin_bottom = 6
			add_theme_stylebox_override(state, style)
		surface = PlateSurface.new()
		surface.gold = primary
		surface.show_behind_parent = true
		surface.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		add_child(surface)
		mouse_entered.connect(func() -> void: surface.highlighted = true; surface.queue_redraw())
		mouse_exited.connect(func() -> void: surface.highlighted = false; surface.queue_redraw())
		focus_entered.connect(func() -> void: surface.highlighted = true; surface.queue_redraw())
		focus_exited.connect(func() -> void: surface.highlighted = is_hovered(); surface.queue_redraw())

class PlateSurface extends Control:
	var gold := false
	var highlighted := false
	func _ready() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		texture_filter = TEXTURE_FILTER_LINEAR
		resized.connect(queue_redraw)
	func _draw() -> void:
		var tint := Color(1.04, 1.02, 0.94) if gold else Color(0.31, 0.31, 0.27)
		if highlighted: tint = tint.lightened(0.13)
		PLAQUE.paint(self, Rect2(Vector2.ZERO, size), 5, tint, true)
		if not gold:
			draw_rect(Rect2(2, 2, size.x - 4, size.y - 4), Color(ART.GOLD, 0.65 if highlighted else 0.32), false, 1)

class HomeTile extends Button:
	var title := "PERSONAGEM"
	var page := "prepare"
	var plate_index := 0
	var featured := false
	var font: Font
	var emblem: Texture2D
	func _ready() -> void:
		font = ART.title_font()
		texture_filter = TEXTURE_FILTER_LINEAR
		var icon_name := "characters" if page == "prepare" else ("statistics" if page == "records" else page)
		emblem = load("res://assets/art/icons/" + icon_name + ".svg")
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for state in ["normal", "hover", "pressed", "focus"]:
			add_theme_stylebox_override(state, StyleBoxEmpty.new())
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
		resized.connect(queue_redraw)
	func _draw() -> void:
		var bounds := Rect2(Vector2(1, 1), size - Vector2(2, 2))
		var active := featured or is_hovered() or has_focus()
		PLAQUE.paint(self, bounds, plate_index, Color(1.05, 1.05, 0.96) if active else Color(0.83, 0.86, 0.79))
		if active:
			draw_rect(bounds.grow(-2), Color(ART.GOLD, 0.8), false, 1)
		if emblem != null:
			var side := 14 if size.y < 60 else 18
			draw_texture_rect(emblem, Rect2(14, 8 if size.y < 60 else 14, side, side), false, Color("#ded1af"))
		var points := 9 if size.y < 60 else (10 if size.x < 180 else 12)
		draw_string(font, Vector2(14, size.y - (10 if size.y < 60 else 17)), title, HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.60, points, ART.TEXT)
