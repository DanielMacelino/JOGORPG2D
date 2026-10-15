extends VBoxContainer
signal back_requested
signal difficulty_selected(tier: int)
signal phase_selected(map_id: String, phase: int)
signal start_requested(map_id: String, phase: int)
const ART := preload("res://scripts/ui/wild_theme.gd")
const HOME := preload("res://scripts/ui/menu/home_screen.gd")
const RECORDS := preload("res://scripts/ui/menu/records_screen.gd")
const REGION := preload("res://scripts/ui/region_art.gd")
const ITEM_ICON := preload("res://scripts/ui/equipment_icon.gd")
const STAGE_ART := preload("res://scripts/ui/world_stage_art.gd")
var selected_map := "verdant_reach"
var selected_phase := 1
var tier := 0
var class_id := "warrior"
var draft: Dictionary = {}
var browse := ""
var compact := false
var narrow := false
var short_window := false
var world_list: GridContainer
var detail: VBoxContainer
var layout: BoxContainer
var details_frame: PanelContainer

func _ready() -> void:
	name = "WorldsPanel"
	size_flags_horizontal = SIZE_EXPAND_FILL
	var extent := get_viewport_rect().size
	compact = extent.y < 650
	narrow = extent.x < 760
	short_window = extent.y < 470
	browse = str(draft.get("region", selected_map))
	if not ContentCatalog.maps.has(browse): browse = selected_map
	add_theme_constant_override("separation", 6 if compact else 12)
	_build_header()
	add_child(RECORDS.Rule.new())
	_build_difficulty()
	if narrow:
		var sections := HBoxContainer.new()
		add_child(sections)
		for index in 2:
			var tab := _button("MUNDOS" if index == 0 else "FASES E MISSÃO")
			tab.name = "WorldSection_%d" % index
			tab.pressed.connect(func() -> void:
				draft.section = index
				_update_sections())
			sections.add_child(tab)
	layout = BoxContainer.new()
	layout.vertical = narrow
	layout.add_theme_constant_override("separation", 8 if compact else 14)
	add_child(layout)
	world_list = GridContainer.new()
	world_list.name = "WorldList"
	world_list.columns = (3 if extent.x >= 500 else 2) if narrow else 1
	world_list.custom_minimum_size.x = 0 if narrow else clampf(extent.x * 0.205, 174, 232)
	world_list.size_flags_horizontal = SIZE_EXPAND_FILL if narrow else SIZE_FILL
	world_list.add_theme_constant_override("h_separation", 6)
	world_list.add_theme_constant_override("v_separation", 5 if compact else 9)
	layout.add_child(world_list)
	var panel := AtlasFrame.new()
	details_frame = panel
	panel.name = "WorldDetails"
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(ART.GOLD, 7 if compact else 14))
	layout.add_child(panel)
	detail = VBoxContainer.new()
	detail.size_flags_horizontal = SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 6 if compact else 13)
	panel.add_child(detail)
	_refresh()
	_update_sections()

func _update_sections() -> void:
	if not narrow: return
	world_list.visible = int(draft.get("section", 1)) == 0
	details_frame.visible = not world_list.visible
	for index in 2:
		var tab: Button = find_child("WorldSection_%d" % index, true, false)
		tab.disabled = index == int(draft.get("section", 1))

func _label(text: String, points := 12, color := ART.TEXT, title := false) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", roundi(points * clampf(float(SaveManager.data.settings.ui_scale), 0.85, 1.2)))
	label.add_theme_color_override("font_color", color)
	if title: label.add_theme_font_override("font", ART.title_font())
	return label

func _button(text: String, primary := false) -> Button:
	var button := HOME.OrnateAction.new()
	button.text = text
	button.primary = primary
	button.action_font_size = 11 if compact else 12
	button.custom_minimum_size.y = 32 if compact else 40
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	return button

func _style(accent: Color, padding: int) -> StyleBoxFlat:
	var style := ART.panel(Color("#061714"), padding)
	style.border_color = Color(accent, 0.65)
	return style

func _build_header() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	var back := _button("← VOLTAR")
	back.name = "WorldsBack"
	back.size_flags_horizontal = SIZE_FILL
	back.custom_minimum_size.x = 94 if narrow else (116 if compact else 140)
	back.pressed.connect(func() -> void: back_requested.emit())
	row.add_child(back)
	if not narrow and not short_window:
		var emblem := RECORDS.CompassEmblem.new()
		emblem.custom_minimum_size = Vector2.ONE * (42 if compact else 54)
		row.add_child(emblem)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(titles)
	titles.add_child(_label("MUNDOS", 23 if narrow else (28 if compact else 32), ART.GOLD, true))
	if not narrow and not short_window:
		titles.add_child(_label("Explore os mundos. Cada região guarda dez desafios.", 10 if compact else 12, ART.TEXT))
	var wallet := _label("OURO  %d   |   CRISTAIS  %d" % [SaveManager.data.gold, SaveManager.data.crystals], 11, ART.GOLD)
	wallet.name = "WorldWallet"
	wallet.autowrap_mode = TextServer.AUTOWRAP_OFF
	wallet.size_flags_horizontal = SIZE_SHRINK_END
	if narrow and not short_window: add_child(wallet)
	elif narrow: wallet.queue_free()
	else: row.add_child(wallet)

func _build_difficulty() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	var picker := OptionButton.new()
	picker.name = "WorldDifficulty"
	picker.fit_to_longest_item = false
	picker.size_flags_horizontal = SIZE_EXPAND_FILL
	picker.custom_minimum_size.y = 32 if compact else 38
	picker.clip_text = true
	picker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var highest := int(SaveManager.data.highest_difficulty)
	for index in maxi(7, highest + 2):
		picker.add_item("%s · %s" % [CampaignRules.difficulty_name(index), "%d/60 fases" % SaveManager.campaign_cleared(index) if index <= highest else "conclua os seis mundos na dificuldade anterior"])
		picker.set_item_disabled(index, index > highest)
	picker.select(tier)
	picker.item_selected.connect(func(index: int) -> void: difficulty_selected.emit(index))
	row.add_child(picker)
	var completed_worlds := 0
	for id in ContentCatalog.MAP_ORDER:
		if _completed(str(id)) == 10: completed_worlds += 1
	var message := _label("PRÓXIMA DIFICULDADE  ·  %d/6 MUNDOS" % completed_worlds, 10 if compact else 11, ART.GOLD)
	message.name = "WorldDifficultyProgress"
	message.tooltip_text = "Conclua as dez fases dos seis mundos nesta dificuldade para liberar a próxima."
	message.mouse_filter = MOUSE_FILTER_PASS
	message.visible = not narrow
	row.add_child(message)

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _completed(id: String) -> int:
	var count := 0
	for phase in range(1, 11):
		if SaveManager.phase_completed(id, phase, tier): count += 1
	return count

func _refresh() -> void:
	_clear(world_list)
	for id in ContentCatalog.MAP_ORDER:
		var map: MapData = ContentCatalog.maps[id]
		var card := WorldCard.new()
		card.name = "World_" + str(id)
		card.map = map
		card.active = str(id) == browse
		card.completed = _completed(str(id))
		card.available = SaveManager.phase_unlocked(str(id), 1, tier)
		card.small = narrow
		card.custom_minimum_size.y = (37 if compact else 48) if narrow else (54 if compact else 73)
		card.size_flags_horizontal = SIZE_EXPAND_FILL
		card.tooltip_text = map.display_name + "\n" + map.description
		card.pressed.connect(func() -> void:
			browse = str(map.id)
			draft.region = browse
			draft.section = 1
			_refresh()
			_update_sections())
		world_list.add_child(card)
	_clear(detail)
	var map: MapData = ContentCatalog.maps[browse]
	var phase := selected_phase if browse == selected_map else mini(10, _completed(browse) + 1)
	_build_banner(map)
	detail.add_child(RECORDS.Rule.new())
	var phases := StageTrack.new()
	phases.name = "WorldPhases"
	phases.columns = 5 if narrow and get_viewport_rect().size.x < 560 else 10
	phases.add_theme_constant_override("h_separation", 4)
	phases.add_theme_constant_override("v_separation", 4)
	detail.add_child(phases)
	for number in range(1, 11):
		var stage := StageButton.new()
		stage.name = "WorldPhase_%02d" % number
		stage.number = number
		stage.region_theme = map.theme
		stage.done = SaveManager.phase_completed(browse, number, tier)
		stage.available = SaveManager.phase_unlocked(browse, number, tier)
		stage.active = number == phase
		stage.disabled = not stage.available
		stage.custom_minimum_size = Vector2(24, 50 if short_window else (86 if compact else 110))
		stage.size_flags_horizontal = SIZE_EXPAND_FILL
		stage.tooltip_text = "%02d · %s\n%s\n%s" % [number, CampaignRules.PHASE_NAMES[number - 1], CampaignRules.phase_objective(number), "Concluída; pode repetir." if stage.done else ("Disponível." if stage.available else "Conclua a fase anterior.")]
		stage.pressed.connect(func() -> void:
			draft.region = browse
			phase_selected.emit(browse, stage.number))
		phases.add_child(stage)
	if not narrow and not short_window:
		var legend := HBoxContainer.new()
		legend.name = "WorldPhaseLegend"
		detail.add_child(legend)
		for entry in [["01–04  ·  EXPLORAÇÃO", "Conheça os desafios da região."], ["05  ·  DESAFIO", "Fendas e guardião fortalecido."], ["06–09  ·  ASCENSÃO", "Elites, altar, tempestade e cerco."], ["10  ·  SOBERANO", "Chefe exclusivo e fúria final."]]:
			var column := VBoxContainer.new()
			column.size_flags_horizontal = SIZE_EXPAND_FILL
			legend.add_child(column)
			column.add_child(_label(str(entry[0]), 10, ART.GOLD))
			var explanation := _label(str(entry[1]), 10, ART.MUTED)
			explanation.max_lines_visible = 2
			column.add_child(explanation)
	detail.add_child(RECORDS.Rule.new())
	_build_destination(map, phase)

func _build_banner(map: MapData) -> void:
	var banner := Landscape.new()
	banner.name = "WorldBanner"
	banner.region_theme = map.theme
	banner.custom_minimum_size.y = 42 if short_window else (112 if compact else (125 if narrow else 166))
	detail.add_child(banner)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	row.offset_left = 6
	row.offset_right = -6
	row.add_theme_constant_override("separation", 12)
	banner.add_child(row)
	if not narrow:
		var emblem := REGION.new()
		emblem.region_theme = map.theme
		emblem.accent = map.accent
		emblem.custom_minimum_size.x = 68 if compact else 98
		row.add_child(emblem)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = SIZE_EXPAND_FILL
	info.size_flags_stretch_ratio = 0.7
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info)
	var title := _label(map.display_name, 18 if compact or narrow else 26, ART.GOLD, true)
	title.max_lines_visible = 2
	info.add_child(title)
	if not short_window:
		var description := _label(map.description, 11 if compact else 12, ART.TEXT)
		description.max_lines_visible = 2 if compact else 3
		info.add_child(description)
	var progress := _label("REGIÃO %02d · %d/10 FASES" % [map.stage_index + 1, _completed(browse)], 11, map.accent)
	info.add_child(progress)
	var bar := ProgressBar.new()
	bar.max_value = 10
	bar.value = _completed(browse)
	bar.show_percentage = false
	bar.custom_minimum_size.y = 6
	bar.add_theme_stylebox_override("fill", ART.panel(map.accent, 0))
	info.add_child(bar)
	if not narrow and not short_window:
		var space := Control.new()
		space.size_flags_horizontal = SIZE_EXPAND_FILL
		space.size_flags_stretch_ratio = 0.3
		row.add_child(space)

func _build_destination(map: MapData, phase: int) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4 if compact else 7)
	detail.add_child(column)
	var accent := Color("#f29979") if phase in [5, 10] else ART.GOLD
	column.add_child(_label("FASE %02d · %s" % [phase, CampaignRules.PHASE_NAMES[phase - 1].to_upper()], 13, accent, true))
	var objective := _label(CampaignRules.phase_objective(phase), 11 if compact else 12, ART.TEXT)
	objective.max_lines_visible = 2 if compact else 3
	objective.tooltip_text = objective.text
	objective.mouse_filter = MOUSE_FILTER_PASS
	column.add_child(objective)
	var expedition := CampaignRules.expedition(str(map.id), phase, tier)
	var boss: EnemyData = ContentCatalog.enemies[str(expedition.boss_id)]
	if not short_window:
		column.add_child(_label("GUARDIÃO · " + boss.display_name + (" · SOBERANO REGIONAL" if phase == 10 else ""), 11, accent))
	var reward := "RECOMPENSAS · Ouro, XP e equipamento regional · %d cristal(is) do chefe" % (2 if phase == 10 else 1)
	var signature: EquipmentData = ContentCatalog.equipment.get(browse + "_" + class_id)
	if not short_window:
		var rewards := HBoxContainer.new()
		rewards.name = "WorldRewards"
		rewards.add_theme_constant_override("separation", 7)
		column.add_child(rewards)
		var multiplier := CampaignRules.reward_multiplier(tier, phase)
		for index in 3:
			var chip := PanelContainer.new()
			chip.size_flags_horizontal = SIZE_EXPAND_FILL
			chip.add_theme_stylebox_override("panel", _style(map.accent if index == 2 else ART.GOLD, 5))
			rewards.add_child(chip)
			var row := HBoxContainer.new()
			chip.add_child(row)
			if index < 2:
				var icon := TextureRect.new()
				icon.texture = preload("res://assets/art/relics/deaths_coin.svg") if index == 0 else preload("res://assets/art/relics/time_crystal.svg")
				icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon.custom_minimum_size = Vector2(20, 24) if compact or narrow else Vector2(26, 30)
				row.add_child(icon)
			elif signature != null:
				var icon := ITEM_ICON.new()
				icon.item = signature
				icon.custom_minimum_size = Vector2(20, 24) if compact or narrow else Vector2(26, 30)
				row.add_child(icon)
			var value: String = ["%d–%d ouro" % [roundi(140 * multiplier), roundi(195 * multiplier)], "%d cristal(is)" % (2 if phase == 10 else 1), "Item regional"][index]
			row.add_child(_label(value, 10, ART.GOLD))
			chip.tooltip_text = "Recompensa do chefe; ouro coletado durante as ondas é adicional." if index == 0 else ("Possível achado: " + signature.display_name + "\n" + signature.description if index == 2 and signature != null else reward)
	var available := SaveManager.phase_unlocked(browse, phase, tier)
	var play := _button("IR PARA A FASE %02d  →" % phase if available else "CONCLUA A FASE ANTERIOR")
	play.name = "WorldStart"
	play.disabled = not available
	play.tooltip_text = reward
	play.pressed.connect(func() -> void:
		if SaveManager.phase_unlocked(browse, phase, tier): start_requested.emit(browse, phase))
	column.add_child(play)

class Landscape extends Control:
	const IMAGE := preload("res://assets/art/world-atlas.png")
	var region_theme: StringName = &"forest"
	func _ready() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		texture_filter = TEXTURE_FILTER_LINEAR
		clip_contents = true
		resized.connect(queue_redraw)
	func _draw() -> void:
		var crop: Rect2 = {&"volcanic": Rect2(0.64, 0.0, 0.36, 0.35), &"graveyard": Rect2(0.58, 0.34, 0.42, 0.38), &"castle": Rect2(0.29, 0.05, 0.43, 0.42), &"frost": Rect2(0.30, 0.0, 0.46, 0.28), &"swamp": Rect2(0.62, 0.62, 0.38, 0.38)}.get(region_theme, Rect2(0.23, 0.26, 0.48, 0.49))
		var region := Rect2(crop.position * IMAGE.get_size(), crop.size * IMAGE.get_size())
		var scale_factor := maxf(size.x / region.size.x, size.y / region.size.y)
		var extent := size / maxf(0.001, scale_factor)
		var origin := region.position + (region.size - extent) * Vector2(0.68, 0.5)
		draw_texture_rect_region(IMAGE, Rect2(Vector2.ZERO, size), Rect2(origin, extent), Color("#c2c1a5"))
		for step in 32:
			draw_rect(Rect2(size.x * step / 32, 0, size.x / 32 + 1, size.y), Color(0.01, 0.05, 0.04, lerpf(0.96, 0.16, float(step) / 31)))

class WorldCard extends Button:
	var map: MapData
	var active := false
	var available := false
	var completed := 0
	var small := false
	func _ready() -> void:
		mouse_default_cursor_shape = CURSOR_POINTING_HAND
		var style := ART.panel(Color("#071914"), 4)
		style.border_color = ART.GOLD if active else Color(map.accent, 0.4)
		style.set_border_width_all(2 if active else 1)
		for state in ["normal", "hover", "pressed", "focus"]: add_theme_stylebox_override(state, style)
		var art := Landscape.new()
		art.region_theme = map.theme
		art.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		art.offset_left = 3
		art.offset_right = -3
		art.offset_top = 3
		art.offset_bottom = -3
		add_child(art)
		if not small:
			var emblem := REGION.new()
			emblem.region_theme = map.theme
			emblem.accent = map.accent
			emblem.set_anchors_and_offsets_preset(PRESET_LEFT_WIDE)
			emblem.offset_right = 51
			add_child(emblem)
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 7 if small else 56)
		margin.add_theme_constant_override("margin_right", 7)
		margin.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(margin)
		var column := VBoxContainer.new()
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.mouse_filter = MOUSE_FILTER_IGNORE
		margin.add_child(column)
		var title := Label.new()
		title.text = map.display_name
		title.add_theme_font_size_override("font_size", 11 if small else 15)
		title.add_theme_color_override("font_color", ART.GOLD if active else (ART.TEXT if available else ART.MUTED))
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		title.clip_text = true
		title.mouse_filter = MOUSE_FILTER_IGNORE
		column.add_child(title)
		var progress := Label.new()
		progress.text = "%d/10 fases%s" % [completed, " · bloqueado" if not available else ""]
		progress.add_theme_font_size_override("font_size", 10 if small else 12)
		progress.add_theme_color_override("font_color", map.accent)
		progress.mouse_filter = MOUSE_FILTER_IGNORE
		progress.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		progress.clip_text = true
		column.add_child(progress)
		mouse_entered.connect(func() -> void: modulate = Color(1.12, 1.12, 1.06))
		mouse_exited.connect(func() -> void: modulate = Color.WHITE)

class StageTrack extends GridContainer:
	func _ready() -> void:
		resized.connect(queue_redraw)
	func _draw() -> void:
		for index in range(1, get_child_count()):
			if index % columns == 0: continue
			var previous: Control = get_child(index - 1)
			var current: Control = get_child(index)
			var color := Color(ART.GREEN if current.done else ART.GOLD, 0.65 if current.available else 0.22)
			var from := previous.position + previous.size * Vector2(0.5, 0.40)
			var to := current.position + current.size * Vector2(0.5, 0.40)
			draw_line(from, to, Color("#07130f"), 5, true)
			draw_line(from, to, color, 1.5, true)

class StageButton extends Button:
	var number := 1
	var region_theme: StringName = &"forest"
	var done := false
	var available := false
	var active := false
	var clock := 0.0
	func _ready() -> void:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]: add_theme_stylebox_override(state, StyleBoxEmpty.new())
		mouse_default_cursor_shape = CURSOR_POINTING_HAND
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
		resized.connect(queue_redraw)
		set_process(active and available)
	func _process(delta: float) -> void:
		clock += delta
		queue_redraw()
	func _draw() -> void:
		STAGE_ART.paint(self, number, region_theme, done, available, active, available and (is_hovered() or has_focus()), sin(clock * 2) * 0.5 + 0.5)

class AtlasFrame extends PanelContainer:
	func _draw() -> void:
		var ink := Color(ART.GOLD, 0.65)
		draw_rect(Rect2(4, 4, size.x - 8, size.y - 8), Color(ART.GOLD, 0.2), false, 1)
		for corner in [Vector2(3, 3), Vector2(size.x - 3, 3), Vector2(size.x - 3, size.y - 3), Vector2(3, size.y - 3)]:
			var axis := Vector2(1 if corner.x < size.x * 0.5 else -1, 1 if corner.y < size.y * 0.5 else -1)
			draw_polyline(PackedVector2Array([corner + Vector2(0, axis.y * 17), corner, corner + Vector2(axis.x * 17, 0), corner + axis * 6, corner]), ink, 1, true)
		for x in [7, size.x - 7]:
			for y in range(25, mini(120, int(size.y) - 25), 9):
				draw_line(Vector2(x, y), Vector2(x + (2 if x < 20 else -2), y - 2), Color(ART.GOLD, 0.5), 1, true)
