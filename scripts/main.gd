extends Control

const STYLE := preload("res://scripts/ui/wild_theme.gd")

const GAME_SCENE := preload("res://scenes/game.tscn")
const BG := Color("#101a18")
const PANEL := Color("#192724")
const PANEL_LIGHT := Color("#25382e")
const GOLD := Color("#c6aa72")
const MINT := Color("#91ad8a")
const SLOT_NAMES := {"weapon":"ARMA", "helmet":"ELMO", "armor":"ARMADURA", "boots":"BOTAS", "ring":"ANEL", "amulet":"AMULETO"}
const SLOT_MARKS := {"weapon":"✦", "helmet":"⌂", "armor":"◈", "boots":"⌁", "ring":"◇", "amulet":"✧"}
const RARITY_COLORS := STYLE.RARITY_COLORS
const RARITY_BG := {"common":Color("#1a1f1a"), "uncommon":Color("#0f1f18"), "rare":Color("#0e1824"), "epic":Color("#17101f"), "legendary":Color("#1f1a0a")}
const CATEGORY_COLORS := {"combat":Color("#c98972"), "survival":Color("#98b5ad"), "wealth":Color("#e7c978"), "mastery":Color("#c192ed"), "forge":Color("#c7a071")}
const CATEGORY_NAMES := {"all": "Todas", "combat": "Combate", "survival": "Sobrevivência", "wealth": "Tesouros", "mastery": "Maestria", "forge": "Forja"}

var shell: MarginContainer
var backdrop_layer: Control
var page_root: VBoxContainer
var active_game: ExpeditionGame
var selected_class := "warrior"
var selected_map := "verdant_reach"
var selected_phase := 1
var selected_difficulty := 0
var page_name := "home"
var online_draft: Dictionary = {}
var page_history: Array[String] = []
var page_scroll: ScrollContainer
var scroll_positions: Dictionary = {}
var upgrade_filter := "all"
var forge_class_filter := "all"
var forge_draft: Dictionary = {}

var relayout_queued := false
var inventory_selected_slot := ""
var transmutation_draft: Dictionary = {}
var relics_draft: Dictionary = {}
var upgrades_draft: Dictionary = {}
var characters_draft: Dictionary = {}
var worlds_draft: Dictionary = {}
var forge_selected_recipe := ""
var achievement_filter := "all"
var bestiary_region := "all"

func _ready() -> void:
	theme = STYLE.create_theme()
	_update_canvas_scale()
	selected_class = str(SaveManager.data.get("selected_class", "warrior"))
	if not SaveManager.is_class_unlocked(selected_class):
		selected_class = "warrior"
	selected_map = str(SaveManager.data.get("selected_map", "verdant_reach"))
	if not SaveManager.is_map_unlocked(selected_map):
		selected_map = "verdant_reach"
	selected_phase = int(SaveManager.data.get("selected_phase", 1))
	selected_difficulty = int(SaveManager.data.get("selected_difficulty", 0))
	if not SaveManager.phase_unlocked(selected_map, selected_phase, selected_difficulty):
		selected_map = "verdant_reach"
		selected_phase = 1
	TalentManager.set_class(selected_class)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop_layer = Control.new()
	backdrop_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop_layer)
	var bg := preload("res://scripts/ui/menu/menu_background.gd").new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop_layer.add_child(bg)
	var particles := preload("res://scripts/ui/menu/menu_particles.gd").new()
	particles.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop_layer.add_child(particles)
	shell = MarginContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_update_shell_margins()
	add_child(shell)
	_build_page("home")
	get_viewport().size_changed.connect(_queue_responsive_refresh)
	_apply_saved_settings()
	NetworkSession.launch_requested.connect(_start_online)
	NetworkSession.lobby_requested.connect(_online_lobby)
	NetworkSession.session_closed.connect(_online_closed)
	NetworkSession.changed.connect(func() -> void:
		if page_name == "online" and shell.visible:
			_queue_responsive_refresh())

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_queue_responsive_refresh()

func _queue_responsive_refresh() -> void:
	if is_node_ready() and not relayout_queued:
		relayout_queued = true
		call_deferred("_refresh_responsive_layout")

func _refresh_responsive_layout() -> void:
	relayout_queued = false
	_update_canvas_scale()
	_update_shell_margins()
	if shell != null and shell.visible:
		_build_page(page_name)

func _update_canvas_scale() -> void:
	var window := get_tree().root
	var actual := Vector2(window.size)
	if actual.x <= 0 or actual.y <= 0:
		return
	var reference := actual
	if actual.x / actual.y < 0.85:
		reference *= minf(1.0, 540.0 / actual.x)
	else:
		reference *= minf(1.0, minf(1280.0 / actual.x, 720.0 / actual.y))
	var target := Vector2i(roundi(reference.x), roundi(reference.y))
	if window.content_scale_size != target:
		window.content_scale_size = target

func _update_shell_margins() -> void:
	if shell == null:
		return
	var viewport_size := get_viewport_rect().size
	var side_margin := 10 if viewport_size.x < 520.0 else (18 if viewport_size.x < 900.0 else 26)
	shell.add_theme_constant_override("margin_left", side_margin)
	shell.add_theme_constant_override("margin_right", side_margin)
	shell.add_theme_constant_override("margin_top", 10 if viewport_size.y < 600.0 else 18)
	shell.add_theme_constant_override("margin_bottom", 10 if viewport_size.y < 600.0 else 18)

func _ui_scale() -> float:
	return clampf(float(SaveManager.data.get("settings", {}).get("ui_scale", 1.0)), 0.85, 1.2)

# ═══════════════════════════════════════════════════════════
# ROTEADOR DE PÁGINAS
# ═══════════════════════════════════════════════════════════
func _build_page(page: String) -> void:
	AudioManager.menu_music(true)
	if is_instance_valid(page_scroll):
		scroll_positions[page_name] = page_scroll.scroll_vertical
	if page != page_name:
		page_history.append(page_name)
	page_name = page
	if backdrop_layer != null and backdrop_layer.get_child_count() > 0:
		backdrop_layer.get_child(0).home = page in ["home", "prepare"]
		backdrop_layer.get_child(0).forge = page == "forge"
		backdrop_layer.get_child(0).worlds = page == "maps"
		backdrop_layer.get_child(0).records = page in ["records", "online", "inventory", "equipment", "talents", "relics", "upgrades", "characters", "transmutation", "maps"]
		backdrop_layer.get_child(0).queue_redraw()
	if page_root != null and is_instance_valid(page_root):
		page_root.queue_free()
	page_root = VBoxContainer.new()
	page_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(page_root)
	page_root.modulate.a = 0.0
	var enter_tween := create_tween()
	enter_tween.tween_property(page_root, "modulate:a", 1.0 if page in ["home", "maps"] else 0.9, 0.18)
	var paper_margin := MarginContainer.new()
	paper_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	paper_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var viewport_width := get_viewport_rect().size.x
	var page_side_margin := maxi(0, roundi((viewport_width - 1160.0) * 0.5)) if viewport_width >= 900.0 else 4
	if page == "home" and viewport_width >= 760:
		page_side_margin = maxi(0, roundi(viewport_width * 0.067) - int(shell.get_theme_constant("margin_left")))
	paper_margin.add_theme_constant_override("margin_left", page_side_margin)
	paper_margin.add_theme_constant_override("margin_right", page_side_margin)
	page_root.add_child(paper_margin)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	var scroll: ScrollContainer = null
	if page in ["home", "online", "inventory", "equipment", "talents", "forge", "transmutation", "relics", "upgrades", "characters", "maps"]:
		page_scroll = null
		var viewport := preload("res://scripts/ui/menu/online_viewport.gd").new()
		viewport.content = content
		paper_margin.add_child(viewport)
	else:
		scroll = ScrollContainer.new()
		page_scroll = scroll
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		paper_margin.add_child(scroll)
		scroll.add_child(content)
	match page:
		"home": _build_home(content)
		"prepare": _build_prepare(content)
		"online": _build_online(content)
		"records": _build_records(content)
		"characters": _build_characters(content)
		"equipment", "inventory": _build_inventory(content)
		"abilities": _build_abilities(content)
		"maps": _build_maps(content)
		"upgrades": _build_upgrades(content)
		"talents": _build_talents(content)
		"settings": _build_settings(content)
		"bestiary": _build_bestiary(content)
		"achievements": _build_achievements(content)
		"forge": _build_forge(content)
		"transmutation": _build_transmutation(content)
		"relics": _build_relics(content)
		"statistics": _build_statistics(content)
		"bounties": _build_bounties(content)
	if scroll != null:
		call_deferred("_restore_page_scroll", page, scroll.get_instance_id())

func _restore_page_scroll(page: String, scroll_id: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var scroll: ScrollContainer = instance_from_id(scroll_id) as ScrollContainer
	if is_instance_valid(scroll) and scroll == page_scroll:
		scroll.scroll_vertical = int(scroll_positions.get(page, 0))

func _go_back() -> void:
	var previous: String = page_history.pop_back() if not page_history.is_empty() else "home"
	_build_page(previous)
	if not page_history.is_empty(): page_history.pop_back()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_action_pressed("ui_cancel") or shell == null or not shell.visible or page_name == "home": return
	for button in page_root.find_children("*", "Button", true, false):
		if button.is_visible_in_tree() and not button.disabled and button.text.contains("VOLTAR"):
			button.pressed.emit()
			get_viewport().set_input_as_handled()
			return

# ═══════════════════════════════════════════════════════════
# HOME
# ═══════════════════════════════════════════════════════════
func _build_home(parent: VBoxContainer) -> void:
	var home := preload("res://scripts/ui/menu/home_screen.gd").new()
	home.class_id = selected_class
	home.map_id = selected_map
	home.phase = selected_phase
	home.difficulty = selected_difficulty
	home.start_requested.connect(_start_game.bind(false))
	home.page_requested.connect(_build_page)
	parent.add_child(home)

func _build_online(parent: VBoxContainer) -> void:
	var screen := preload("res://scripts/ui/menu/online_screen.gd").new()
	screen.back_requested.connect(_go_back)
	screen.draft = online_draft
	screen.default_class = selected_class
	screen.default_map = selected_map
	screen.default_phase = selected_phase
	screen.default_tier = selected_difficulty
	parent.add_child(screen)
func _start_online(destination: Dictionary) -> void:
	if active_game != null and is_instance_valid(active_game):
		active_game.queue_free()
	active_game = preload("res://scripts/network/coop_game.gd").new()
	active_game.name = "CoopExpedition"
	var local: Dictionary = NetworkSession.players[multiplayer.get_unique_id()]
	active_game.player_class = str(local.class)
	active_game.map_id = str(destination.map)
	active_game.phase_number = int(destination.phase)
	active_game.difficulty_tier = int(destination.tier)
	GameManager.begin_run(active_game.player_class, active_game.map_id)
	AudioManager.menu_music(false)
	shell.hide()
	backdrop_layer.hide()
	add_child(active_game)

func _online_lobby() -> void:
	_return_to_menu()
	_build_page("online")

func _online_closed(_reason: String) -> void:
	if active_game != null and active_game.get_script() == preload("res://scripts/network/coop_game.gd"):
		_online_lobby()
	elif shell.visible and page_name == "online":
		_queue_responsive_refresh()

func _build_prepare(parent: VBoxContainer) -> void:
	_build_page_heading(parent, "PREPARAR PERSONAGEM", "Escolha seu viajante, vista seus achados e prepare a próxima expedição.")
	var prepare := preload("res://scripts/ui/menu/prepare_screen.gd").new()
	prepare.class_id = selected_class
	prepare.map_id = selected_map
	prepare.phase = selected_phase
	prepare.page_requested.connect(_build_page)
	parent.add_child(prepare)

func _build_home_hub(parent: VBoxContainer, records: bool) -> void:
	_build_page_heading(parent, "REGISTROS" if records else "PREPARAR PERSONAGEM", "Suas histórias, conquistas e criaturas encontradas." if records else "Escolha o viajante, vista seus achados e prepare a próxima expedição.")
	var entries: Array = [["Bestiário", "bestiary"], ["Conquistas", "achievements"], ["Caçadas", "bounties"], ["Estatísticas", "statistics"]] if records else [["Personagem", "characters"], ["Arsenal", "inventory"], ["Talentos", "talents"], ["Melhorias", "upgrades"], ["Forja", "forge"], ["Relíquias", "relics"]]
	var grid := GridContainer.new()
	grid.columns = 3 if get_viewport_rect().size.x > 800 else (2 if get_viewport_rect().size.x > 500 else 1)
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(grid)
	for entry in entries:
		_add_home_tile(grid, str(entry[0]), str(entry[1]), "")

func _build_records(parent: VBoxContainer) -> void:
	var records := preload("res://scripts/ui/menu/records_screen.gd").new()
	records.page_requested.connect(_build_page)
	records.back_requested.connect(_go_back)
	parent.add_child(records)

func _add_home_tile(parent: GridContainer, title: String, page: String, symbol: String) -> void:
	var tile := preload("res://scripts/ui/menu/nav_tile.gd").new()
	tile.setup(title, symbol, page == "characters" or page == "inventory")
	tile.page = page
	if get_viewport_rect().size.y < 620:
		tile.custom_minimum_size.y = 48
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.pressed.connect(_build_page.bind(page))
	parent.add_child(tile)

# ═══════════════════════════════════════════════════════════
# CABEÇALHO DE PÁGINA
# ═══════════════════════════════════════════════════════════
func _build_page_heading(parent: VBoxContainer, title: String, summary: String) -> void:
	var compact := get_viewport_rect().size.x < 600.0
	if compact:
		var back := _button(parent, "←  VOLTAR", _go_back, false, 42)
		back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		back.custom_minimum_size.x = 124
		var title_box := VBoxContainer.new()
		title_box.add_theme_constant_override("separation", 4)
		parent.add_child(title_box)
		var heading := _label(title_box, title, 25, STYLE.TEXT)
		heading.clip_text = false
		_label(title_box, summary, 13, STYLE.MUTED)
	else:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		parent.add_child(row)
		var back := _button(row, "← VOLTAR", _go_back, false, 40)
		back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		back.custom_minimum_size.x = 136
		var title_box := VBoxContainer.new()
		title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_box.add_theme_constant_override("separation", 3)
		row.add_child(title_box)
		_label(title_box, title, 27, STYLE.TEXT)
		_label(title_box, summary, 13, STYLE.MUTED)
	_label(parent, "OURO DE VÉSPERA  %d   ·   CRISTAIS  %d" % [int(SaveManager.data.gold), int(SaveManager.data.crystals)], 12, GOLD)
	_divider(parent)

# ═══════════════════════════════════════════════════════════
# PERSONAGENS
# ═══════════════════════════════════════════════════════════
func _build_characters(parent: VBoxContainer) -> void:
	var panel := preload("res://scripts/ui/characters_panel.gd").new()
	panel.draft = characters_draft
	panel.selected_class = selected_class
	panel.back_requested.connect(_go_back)
	panel.class_selected.connect(_select_class)
	panel.recruit_requested.connect(_unlock_class)
	parent.add_child(panel)

func _refresh_character_selection() -> void:
	var panel := page_root.find_child("CharactersPanel", true, false)
	if panel != null:
		panel.selected_class = selected_class
		panel.refresh()
	else:
		_build_page("characters")

func _select_class(id: String) -> void:
	if not SaveManager.is_class_unlocked(id):
		return
	selected_class = id
	SaveManager.set_selected_class(id)
	TalentManager.set_class(id)
	_refresh_character_selection()

func _unlock_class(id: String, currency: String) -> void:
	if SaveManager.unlock_class(id, currency):
		AudioManager.feedback("talent")
		selected_class = id
		SaveManager.set_selected_class(id)
		TalentManager.set_class(id)
		_refresh_character_selection()
		var panel := page_root.find_child("CharactersPanel", true, false)
		if panel != null:
			panel.notice.text = _class_name(id) + " se juntou ao acampamento. Arma inicial equipada."

# ═══════════════════════════════════════════════════════════
# INVENTÁRIO
# ═══════════════════════════════════════════════════════════
func _build_inventory(parent: VBoxContainer) -> void:
	var inventory := preload("res://scripts/ui/inventory_panel.gd").new()
	inventory.back_requested.connect(_go_back)
	inventory.class_id = selected_class
	inventory.selected_slot = inventory_selected_slot
	inventory.filter_changed.connect(_remember_inventory_filter)
	inventory.forge_requested.connect(_build_page.bind("forge"))
	inventory.transmutation_requested.connect(_build_page.bind("transmutation"))
	parent.add_child(inventory)

func _build_transmutation(parent: VBoxContainer) -> void:
	var panel := preload("res://scripts/ui/transmutation_panel.gd").new()
	panel.class_id = selected_class
	panel.draft = transmutation_draft
	panel.back_requested.connect(_go_back)
	parent.add_child(panel)

func _remember_inventory_filter(slot: String) -> void:
	inventory_selected_slot = slot

func _open_inventory_for_slot(slot: String) -> void:
	inventory_selected_slot = slot
	_build_page("inventory")

# ═══════════════════════════════════════════════════════════
# HABILIDADES
# ═══════════════════════════════════════════════════════════
func _build_abilities(parent: VBoxContainer) -> void:
	_build_page_heading(parent, "HABILIDADES", "%s: escolhas da classe e habilidades compartilhadas. Bônus de cada nível se somam; a build recomeça a cada expedição." % ContentCatalog.classes[selected_class].display_name)
	# Filtro de raridade
	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 6)
	parent.add_child(filter_row)
	for rarity in ItemTiers.ORDER:
		var rb := _rarity_chip(rarity)
		filter_row.add_child(rb)
	# Cards das habilidades agrupadas por raridade
	var rarity_order := ItemTiers.ORDER
	for rarity in rarity_order:
		var found_any := false
		for id in ContentCatalog.abilities:
			var ability: AbilityData = ContentCatalog.abilities[id]
			if str(ability.rarity) == rarity and not ability.unlock_only and ability.available_to(selected_class):
				found_any = true
				break
		if not found_any:
			continue
		var section_label := _label(parent, _rarity_name(rarity).to_upper(), 11, _rarity_color(rarity))
		section_label.add_theme_constant_override("margin_top", 8)
		for id in ContentCatalog.abilities:
			var ability: AbilityData = ContentCatalog.abilities[id]
			if ability.unlock_only or str(ability.rarity) != rarity or not ability.available_to(selected_class):
				continue
			var card := _panel(parent, RARITY_BG.get(rarity, PANEL), Vector2(0, 0))
			# Borda colorida de raridade
			var card_style := StyleBoxFlat.new()
			card_style.bg_color = RARITY_BG.get(rarity, PANEL)
			card_style.border_color = _rarity_color(rarity).darkened(0.4)
			card_style.border_width_left = 3
			card_style.border_width_right = 0
			card_style.border_width_top = 0
			card_style.border_width_bottom = 0
			card_style.set_corner_radius_all(3)
			card_style.content_margin_left = 12
			card_style.content_margin_right = 12
			card_style.content_margin_top = 10
			card_style.content_margin_bottom = 10
			card.add_theme_stylebox_override("panel", card_style)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			card.add_child(row)
			var icon := preload("res://scripts/ui/ability_icon.gd").new()
			icon.ability_id = str(ability.id)
			icon.accent = _rarity_color(str(ability.rarity))
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(icon)
			var text_box := VBoxContainer.new()
			text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(text_box)
			var title_row := HBoxContainer.new()
			text_box.add_child(title_row)
			_label(title_row, ability.display_name, 15, _rarity_color(str(ability.rarity))).size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_rarity_badge(title_row, str(ability.rarity))
			_label(text_box, "COMPARTILHADA" if ability.class_ids.is_empty() else "HABILIDADE DA CLASSE", 10, MINT)
			_label(text_box, ability.rank_description(1), 12, STYLE.MUTED)
	_label(parent, "Raridade lendária é extremamente baixa. Habilidades ficam mais fortes ao subir de nível (até nível 5).", 12, Color("#94aaa4"))

func _rarity_chip(rarity: String) -> Button:
	var btn := Button.new()
	btn.text = _rarity_name(rarity)
	btn.add_theme_font_size_override("font_size", 10)
	var style := StyleBoxFlat.new()
	style.bg_color = _rarity_color(rarity).darkened(0.6)
	style.border_color = _rarity_color(rarity)
	style.set_border_width_all(1)
	style.set_corner_radius_all(20)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_color_override("font_color", _rarity_color(rarity))
	return btn

func _rarity_badge(parent: Node, rarity: String) -> void:
	var lbl := Label.new()
	lbl.text = "  " + _rarity_name(rarity).to_upper() + "  "
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", _rarity_color(rarity))
	var style := StyleBoxFlat.new()
	style.bg_color = _rarity_color(rarity).darkened(0.65)
	style.border_color = _rarity_color(rarity).darkened(0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	lbl.add_theme_stylebox_override("normal", style)
	parent.add_child(lbl)

# ═══════════════════════════════════════════════════════════
# MAPAS
# ═══════════════════════════════════════════════════════════
func _build_maps(parent: VBoxContainer) -> void:
	var worlds := preload("res://scripts/ui/worlds_panel.gd").new()
	worlds.selected_map = selected_map
	worlds.selected_phase = selected_phase
	worlds.tier = selected_difficulty
	worlds.class_id = selected_class
	worlds.draft = worlds_draft
	worlds.back_requested.connect(_go_back)
	worlds.difficulty_selected.connect(_select_difficulty)
	worlds.phase_selected.connect(_select_phase)
	worlds.start_requested.connect(func(id: String, phase: int) -> void:
		if not SaveManager.phase_unlocked(id, phase, selected_difficulty): return
		selected_map = id
		selected_phase = phase
		_save_destination()
		_start_game(false))
	parent.add_child(worlds)

func _select_difficulty(tier: int) -> void:
	if tier < 0 or tier > int(SaveManager.data.highest_difficulty):
		return
	selected_difficulty = tier
	worlds_draft.clear()
	var ordinal := mini(59, SaveManager.campaign_cleared(tier))
	selected_map = str(ContentCatalog.MAP_ORDER[floori(float(ordinal) / 10.0)])
	selected_phase = ordinal % 10 + 1
	_save_destination()
	_build_page("maps")

func _select_phase(id: String, phase: int) -> void:
	if not SaveManager.phase_unlocked(id, phase, selected_difficulty):
		return
	selected_map = id
	selected_phase = phase
	_save_destination()
	_build_page("maps")

func _save_destination() -> void:
	SaveManager.data.selected_map = selected_map
	SaveManager.data.selected_phase = selected_phase
	SaveManager.data.selected_difficulty = selected_difficulty
	SaveManager.save_game()

func _select_map(id: String) -> void:
	_select_phase(id, 1)

func _build_talents(parent: VBoxContainer) -> void:
	TalentManager.set_class(selected_class)
	var tree := preload("res://scripts/ui/talent_tree.gd").new()
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree.back_requested.connect(_go_back)
	tree.class_selected.connect(_select_talent_class)
	parent.add_child(tree)

func _select_talent_class(index: int) -> void:
	var id: String = ContentCatalog.CLASS_ORDER[index]
	if SaveManager.is_class_unlocked(id):
		selected_class = id
		SaveManager.set_selected_class(id)
		TalentManager.set_class(id)
		_build_page("talents")

# ═══════════════════════════════════════════════════════════
# MELHORIAS PERMANENTES
# ═══════════════════════════════════════════════════════════
func _build_upgrades(parent: VBoxContainer) -> void:
	var panel := preload("res://scripts/ui/upgrades_panel.gd").new()
	panel.draft = upgrades_draft
	panel.back_requested.connect(_go_back)
	parent.add_child(panel)

func _buy_upgrade(id: String, _cost: int) -> void:
	var panel := page_root.find_child("UpgradesPanel", true, false)
	if panel != null:
		panel.purchase(id)

func _build_forge(parent: VBoxContainer) -> void:
	var panel := preload("res://scripts/ui/forge_panel.gd").new()
	panel.draft = forge_draft
	panel.back_requested.connect(_go_back)
	parent.add_child(panel)

func _add_filters(parent: Node, entries: Array, selected: String, callback: Callable) -> void:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 6)
	parent.add_child(row)
	for entry in entries:
		var button := _button(row, str(entry[0]), callback.bind(str(entry[1])), str(entry[1]) == selected, 34)
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

func _do_forge(recipe_id: String) -> void:
	if SaveManager.forge_item(recipe_id):
		var recipe := ContentCatalog.get_forge_recipe(recipe_id)
		_page_notice("⚒  %s forjado com sucesso!\n\nO item foi adicionado ao seu inventário." % recipe.get("result_name", recipe_id))
		_build_page("forge")
	else:
		_page_notice("Não é possível forjar agora. Verifique os ingredientes e recursos.")

# ═══════════════════════════════════════════════════════════
# RELÍQUIAS — SISTEMA COMPLETO
# ═══════════════════════════════════════════════════════════
func _build_relics(parent: VBoxContainer) -> void:
	var panel := preload("res://scripts/ui/relics_panel.gd").new()
	panel.draft = relics_draft
	panel.back_requested.connect(_go_back)
	parent.add_child(panel)

func _build_bestiary(parent: VBoxContainer) -> void:
	_build_page_heading(parent, "BESTIÁRIO", "Conheça seus inimigos. Todo conhecimento é uma vantagem.")
	var kills: Dictionary = SaveManager.data.get("bestiary_kills", {})
	var total_types := ContentCatalog.enemies.size()
	var known_types := 0
	for eid in ContentCatalog.enemies:
		if int(kills.get(eid, 0)) > 0:
			known_types += 1
	_label(parent, "CRIATURAS CONHECIDAS: %d/%d" % [known_types, total_types], 13, GOLD)
	var prog := ProgressBar.new()
	prog.show_percentage = false
	prog.min_value = 0
	prog.max_value = total_types
	prog.value = known_types
	prog.custom_minimum_size.y = 10
	prog.add_theme_stylebox_override("fill", _progress_fill(GOLD))
	prog.add_theme_stylebox_override("background", _progress_bg())
	parent.add_child(prog)
	_divider(parent)
	var filters := GridContainer.new()
	filters.columns = 4 if get_viewport_rect().size.x >= 720.0 else 2
	filters.add_theme_constant_override("h_separation", 6)
	filters.add_theme_constant_override("v_separation", 6)
	filters.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(filters)
	_button(filters, "Todas as regiões", _filter_bestiary.bind("all"), bestiary_region == "all", 36)
	for region_id in ContentCatalog.MAP_ORDER:
		var region: MapData = ContentCatalog.maps[region_id]
		_button(filters, region.display_name, _filter_bestiary.bind(region_id), bestiary_region == region_id, 36)

	var compact := get_viewport_rect().size.x < 720.0
	var grid := GridContainer.new()
	grid.columns = 2 if not compact else 1
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	parent.add_child(grid)

	for enemy_id in ContentCatalog.enemies:
		if bestiary_region != "all":
			var region: MapData = ContentCatalog.maps.get(bestiary_region)
			if region != null and not region.enemy_pool.has(StringName(enemy_id)) and region.elite_id != StringName(enemy_id) and region.boss_id != StringName(enemy_id) and str(enemy_id) != "loot_mimic" and not (str(region.id) == "verdant_reach" and str(enemy_id) == "minotaur"):
				continue
		var enemy: EnemyData = ContentCatalog.enemies[enemy_id]
		var kill_count: int = int(kills.get(enemy_id, 0))
		var is_known := kill_count > 0
		var type_color: Color
		if enemy.boss:
			type_color = Color("#e87070")
		elif enemy.elite:
			type_color = Color("#e0a855")
		else:
			type_color = Color("#89b49e")
		var card_bg := Color("#16130f") if is_known else Color("#0c0b09")
		var card := _panel(grid, card_bg, Vector2.ZERO)
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = card_bg
		if is_known:
			card_style.border_color = type_color.darkened(0.5)
			card_style.border_width_top = 2
		card_style.border_width_right = 0
		card_style.border_width_left = 0
		card_style.border_width_bottom = 0
		card_style.set_corner_radius_all(3)
		card_style.content_margin_left = 12
		card_style.content_margin_right = 12
		card_style.content_margin_top = 10
		card_style.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", card_style)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)

		# Avatar
		var avatar := preload("res://scripts/ui/enemy_portrait.gd").new()
		avatar.enemy_id = str(enemy_id)
		avatar.known = is_known
		avatar.custom_minimum_size = Vector2(56, 70)
		avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(avatar)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 3)
		row.add_child(info)
		var habitats: Array[String] = []
		for region_id in ContentCatalog.MAP_ORDER:
			var region: MapData = ContentCatalog.maps[region_id]
			if region.enemy_pool.has(StringName(enemy_id)) or region.elite_id == StringName(enemy_id) or region.boss_id == StringName(enemy_id) or str(enemy_id) == "loot_mimic" or (str(region.id) == "verdant_reach" and str(enemy_id) == "minotaur"):
				habitats.append(region.display_name)
		_label(info, " / ".join(habitats), 9, STYLE.MUTED)

		if is_known:
			var title_row := HBoxContainer.new()
			title_row.add_theme_constant_override("separation", 6)
			info.add_child(title_row)
			_label(title_row, enemy.display_name.to_upper(), 14, type_color).size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var type_tag := "CHEFE" if enemy.boss else ("ELITE" if enemy.elite else "COMUM")
			var tag_lbl := _label(title_row, " " + type_tag + " ", 9, type_color)
			var tag_style := StyleBoxFlat.new()
			tag_style.bg_color = type_color.darkened(0.7)
			tag_style.set_corner_radius_all(3)

			_label(info, "ABATES: %d" % kill_count, 11, Color("#889b92"))

			# Stats bars
			var hp_row := HBoxContainer.new()
			hp_row.add_theme_constant_override("separation", 6)
			info.add_child(hp_row)
			_label(hp_row, "❤️", 11, Color("#c98972"))
			var hp_bar := ProgressBar.new()
			hp_bar.show_percentage = false
			hp_bar.min_value = 0
			hp_bar.max_value = 2000 if enemy.boss else 200
			hp_bar.value = enemy.max_health
			hp_bar.custom_minimum_size = Vector2(60, 8)
			hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hp_bar.add_theme_stylebox_override("fill", _progress_fill(Color("#c98972")))
			hp_bar.add_theme_stylebox_override("background", _progress_bg())
			hp_row.add_child(hp_bar)
			_label(hp_row, str(int(enemy.max_health)), 10, Color("#aaa")).custom_minimum_size.x = 36

			_label(info, "DANO: %d  ·  PASSO: %d  ·  OURO: %d" % [int(enemy.damage), int(enemy.speed), enemy.gold], 10, STYLE.MUTED)

			if not enemy.tips.is_empty():
				var tip_lbl := _label(info, "💡 " + str(enemy.tips), 11, Color("#7a9880"))
				tip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		else:
			_label(info, "???", 15, Color("#3a3028"))
			_label(info, "Encontre esta criatura na expedição.", 11, Color("#2a2520"))
			_label(info, "Abates: 0", 10, STYLE.MUTED)

func _filter_bestiary(region_id: String) -> void:
	bestiary_region = region_id
	_build_page("bestiary")

# ═══════════════════════════════════════════════════════════
# CONQUISTAS — SISTEMA COMPLETO
# ═══════════════════════════════════════════════════════════
func _build_achievements(parent: VBoxContainer) -> void:
	_build_page_heading(parent, "CONQUISTAS", "Recompensas por bravura, persistência e maestria.")
	var unlocked_map: Dictionary = SaveManager.data.get("achievements", {})
	var total := ContentCatalog.achievements.size()
	var done := unlocked_map.size()

	# Progresso geral
	_label(parent, "%d / %d CONQUISTAS DESBLOQUEADAS" % [done, total], 14, GOLD)
	var prog := ProgressBar.new()
	prog.show_percentage = false
	prog.min_value = 0
	prog.max_value = total
	prog.value = done
	prog.custom_minimum_size.y = 12
	prog.add_theme_stylebox_override("fill", _progress_fill(GOLD))
	prog.add_theme_stylebox_override("background", _progress_bg())
	parent.add_child(prog)

	# Recompensas totais acumuladas
	var total_gold_from_ach := 0
	var total_crystals_from_ach := 0
	for ach in ContentCatalog.achievements:
		if unlocked_map.has(ach.id):
			total_gold_from_ach += int(ach.get("reward_gold", 0))
			total_crystals_from_ach += int(ach.get("reward_crystals", 0))
	_label(parent, "RECOMPENSAS COLETADAS: %d Ouro  ·  %d Cristais" % [total_gold_from_ach, total_crystals_from_ach], 11, Color("#a8916c"))
	_divider(parent)

	# Filtro por categoria
	var categories := ["all", "combat", "survival", "wealth", "mastery", "forge"]
	var filter_row := GridContainer.new()
	filter_row.columns = 3 if get_viewport_rect().size.x < 620 else 6
	filter_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_row.add_theme_constant_override("h_separation", 6)
	filter_row.add_theme_constant_override("v_separation", 6)
	parent.add_child(filter_row)

	for cat in categories:
		var cat_btn := Button.new()
		cat_btn.text = str(CATEGORY_NAMES.get(cat, cat))
		cat_btn.custom_minimum_size = Vector2(0, 34)
		cat_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		STYLE.apply_button(cat_btn)
		cat_btn.add_theme_font_size_override("font_size", 12)
		var selected: bool = achievement_filter == cat
		var cat_color: Color = CATEGORY_COLORS.get(cat, GOLD) if cat != "all" else Color("#aaa")
		var cat_style := StyleBoxFlat.new()
		cat_style.bg_color = cat_color.darkened(0.65) if selected else Color("#1a1510")
		cat_style.border_color = cat_color if selected else Color("#555")
		cat_style.set_border_width_all(1)
		cat_style.set_corner_radius_all(3)
		cat_style.content_margin_left = 8
		cat_style.content_margin_right = 8
		cat_style.content_margin_top = 3
		cat_style.content_margin_bottom = 3
		cat_btn.add_theme_stylebox_override("normal", cat_style)
		cat_btn.add_theme_stylebox_override("hover", cat_style)
		cat_btn.add_theme_color_override("font_color", cat_color)
		cat_btn.pressed.connect(func(): achievement_filter = cat; _build_page("achievements"))
		filter_row.add_child(cat_btn)

	# Lista de conquistas
	for ach in ContentCatalog.achievements:
		if achievement_filter != "all" and str(ach.get("category", "")) != achievement_filter:
			continue
		var is_unlocked: bool = unlocked_map.has(ach.id)
		var cat := str(ach.get("category", "combat"))
		var cat_color: Color = CATEGORY_COLORS.get(cat, GOLD)
		var card_bg := Color("#14120e") if not is_unlocked else Color("#16140e")
		var card := _panel(parent, card_bg, Vector2.ZERO)
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = card_bg
		card_style.border_color = (GOLD if is_unlocked else Color("#333")).darkened(0.2)
		card_style.border_width_left = 3 if is_unlocked else 1
		card_style.border_width_right = 0
		card_style.border_width_top = 0
		card_style.border_width_bottom = 0
		card_style.set_corner_radius_all(3)
		card_style.content_margin_left = 12
		card_style.content_margin_right = 12
		card_style.content_margin_top = 9
		card_style.content_margin_bottom = 9
		card.add_theme_stylebox_override("panel", card_style)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		card.add_child(row)
		var icon_lbl := _label(row, str(ach.get("icon", "★")) if is_unlocked else "☆", 28, GOLD if is_unlocked else Color("#3d332d"), HORIZONTAL_ALIGNMENT_CENTER)
		icon_lbl.custom_minimum_size.x = 42
		icon_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 3)
		row.add_child(info)
		var title_row := HBoxContainer.new()
		title_row.add_theme_constant_override("separation", 6)
		info.add_child(title_row)
		_label(title_row, str(ach.title), 14, Color("#d9c398") if is_unlocked else Color("#786a5d")).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cat_tag := _label(title_row, " " + str(CATEGORY_NAMES.get(cat, cat)).to_upper() + " ", 9, cat_color)
		_label(info, str(ach.desc), 12, Color("#889b92") if is_unlocked else Color("#4d453d"))
		# Recompensa
		var reward_parts := []
		if int(ach.get("reward_gold", 0)) > 0:
			reward_parts.append("⚜ %d Ouro" % int(ach.reward_gold))
		if int(ach.get("reward_crystals", 0)) > 0:
			reward_parts.append("💎 %d Cristais" % int(ach.reward_crystals))
		if not str(ach.get("reward_relic", "")).is_empty():
			reward_parts.append("⚱ Relíquia")
		var reward_str := " · ".join(reward_parts)
		if not reward_str.is_empty():
			_label(info, ("✓ " if is_unlocked else "🎁 ") + reward_str, 11, GOLD if is_unlocked else Color("#5a4e38"))
		if is_unlocked:
			var done_lbl := _label(row, "OBTIDA ✓", 12, MINT, HORIZONTAL_ALIGNMENT_CENTER)
			done_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			done_lbl.custom_minimum_size.x = 70

# ═══════════════════════════════════════════════════════════
# CAÇADAS / BOUNTIES
# ═══════════════════════════════════════════════════════════
func _build_bounties(parent: VBoxContainer) -> void:
	_build_page_heading(parent, "CAÇADAS", "Missões de caça com recompensas especiais em ouro e cristais.")
	var compact := get_viewport_rect().size.x < 680.0
	var active: Array = SaveManager.data.get("active_bounties", [])
	var completed: Array = SaveManager.data.get("completed_bounties", [])

	# Progresso
	_label(parent, "ATIVAS: %d/3  ·  COMPLETAS: %d  ·  DISPONÍVEIS: %d" % [active.size(), completed.size(), ContentCatalog.bounties.size() - active.size() - completed.size()], 12, GOLD)
	_divider(parent)

	# Caçadas ativas
	if active.size() > 0:
		_label(parent, "⚡  CAÇADAS ATIVAS", 14, Color("#e7a050"))
		for bid in active:
			for b in ContentCatalog.bounties:
				if b.id == bid:
					_build_bounty_card(parent, b, "active", compact)

	# Caçadas disponíveis
	var has_available := false
	for b in ContentCatalog.bounties:
		if not active.has(b.id) and not completed.has(b.id):
			if not has_available:
				_label(parent, "📋  DISPONÍVEIS", 14, Color("#a8b9b4"))
				has_available = true
			_build_bounty_card(parent, b, "available", compact)

	# Completas
	if completed.size() > 0:
		_label(parent, "✅  COMPLETAS", 14, MINT)
		for bid in completed:
			for b in ContentCatalog.bounties:
				if b.id == bid:
					_build_bounty_card(parent, b, "completed", compact)

	if not has_available and active.is_empty():
		var hint := _panel(parent, Color("#0f1310"), Vector2.ZERO)
		_label(hint, "Todas as caçadas estão ativas ou completas.\nNovas caçadas serão adicionadas em futuras atualizações.", 13, Color("#6a8070"), HORIZONTAL_ALIGNMENT_CENTER)

	_label(parent, "🎯 Caçadas registram progresso durante a expedição. Máximo de 3 caçadas ativas simultâneas.", 12, Color("#7a9490"))

func _build_bounty_card(parent: VBoxContainer, b: Dictionary, state: String, compact: bool) -> void:
	var difficulty := str(b.get("difficulty", "normal"))
	var diff_colors := {"easy": Color("#6abf6a"), "normal": Color("#6aabcf"), "hard": Color("#e07050"), "legendary": Color("#e0c050")}
	var diff_color: Color = diff_colors.get(difficulty, GOLD)
	var progress := SaveManager.get_bounty_progress(b.id)
	var target := int(b.get("target_count", 1))
	var is_completed := state == "completed"
	var is_active := state == "active"
	var card_bg := Color("#0c1a0c") if is_completed else (Color("#141008") if is_active else Color("#111"))
	var card := _panel(parent, card_bg, Vector2.ZERO)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = card_bg
	card_style.border_color = (MINT if is_completed else (diff_color if is_active else Color("#333"))).darkened(0.3)
	card_style.border_width_left = 4 if is_active else 2
	card_style.border_width_right = 0
	card_style.border_width_top = 0
	card_style.border_width_bottom = 0
	card_style.set_corner_radius_all(3)
	card_style.content_margin_left = 12
	card_style.content_margin_right = 12
	card_style.content_margin_top = 9
	card_style.content_margin_bottom = 9
	card.add_theme_stylebox_override("panel", card_style)
	var layout: Control = VBoxContainer.new() if compact else HBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	card.add_child(layout)
	var icon_lbl := _label(layout, str(b.get("icon", "🎯")), 24, diff_color if not is_completed else MINT, HORIZONTAL_ALIGNMENT_CENTER)
	icon_lbl.custom_minimum_size.x = 40
	icon_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	layout.add_child(info)
	var title_row := HBoxContainer.new()
	info.add_child(title_row)
	_label(title_row, str(b.get("title", "")), 14, MINT if is_completed else diff_color).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var diff_tag := _label(title_row, " " + difficulty.to_upper() + " ", 9, diff_color)
	_label(info, str(b.get("desc", "")), 12, Color("#b0a898") if not is_completed else Color("#7a9490"))
	if is_active:
		var pb := ProgressBar.new()
		pb.show_percentage = false
		pb.min_value = 0
		pb.max_value = target
		pb.value = progress
		pb.custom_minimum_size.y = 10
		pb.add_theme_stylebox_override("fill", _progress_fill(diff_color))
		pb.add_theme_stylebox_override("background", _progress_bg())
		info.add_child(pb)
		_label(info, "PROGRESSO: %d / %d" % [progress, target], 11, Color("#a8916c"))
	var reward_str := "⚜ %d Ouro" % int(b.get("reward_gold", 0))
	if int(b.get("reward_crystals", 0)) > 0:
		reward_str += "  ·  💎 %d Cristais" % int(b.reward_crystals)
	_label(info, ("RECOMPENSA: " if not is_completed else "COLETADO: ") + reward_str, 11, GOLD if not is_completed else MINT)
	if state == "available":
		var activate_btn := _button(layout, "ACEITAR\nCAÇADA", _activate_bounty.bind(str(b.id)), true, 48)
		activate_btn.custom_minimum_size.x = 90 if not compact else 0
		activate_btn.disabled = SaveManager.data.get("active_bounties", []).size() >= 3
	elif is_completed:
		var done_lbl := _label(layout, "✓\nCONCLUIDA", 12, MINT, HORIZONTAL_ALIGNMENT_CENTER)
		done_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		done_lbl.custom_minimum_size.x = 70

func _activate_bounty(bounty_id: String) -> void:
	if not SaveManager.activate_bounty(bounty_id):
		_page_notice("Não é possível aceitar esta caçada agora. Você pode ter 3 caçadas ativas no máximo.")
	else:
		_build_page("bounties")

# ═══════════════════════════════════════════════════════════
# ESTATÍSTICAS — VISUAL
# ═══════════════════════════════════════════════════════════
func _build_statistics(parent: VBoxContainer) -> void:
	_build_page_heading(parent, "ESTATÍSTICAS", "Os registros do seu legado em Vespera.")
	var stats: Dictionary = SaveManager.data.get("statistics", {})
	var best_wave: int = int(SaveManager.data.get("best_wave", 0))
	var compact := get_viewport_rect().size.x < 680.0

	# Bloco de destaque - melhor performance
	var highlight_card := _panel(parent, Color("#1a1208"), Vector2.ZERO)
	var highlight_style := StyleBoxFlat.new()
	highlight_style.bg_color = Color("#1a1208")
	highlight_style.border_color = GOLD.darkened(0.3)
	highlight_style.set_border_width_all(1)
	highlight_style.set_corner_radius_all(10)
	highlight_style.content_margin_left = 16
	highlight_style.content_margin_right = 16
	highlight_style.content_margin_top = 14
	highlight_style.content_margin_bottom = 14
	highlight_card.add_theme_stylebox_override("panel", highlight_style)
	var highlight_row: Control = VBoxContainer.new() if compact else HBoxContainer.new()
	highlight_row.add_theme_constant_override("separation", 20)
	highlight_card.add_child(highlight_row)
	_big_stat(highlight_row, "🌊", str(best_wave), "MELHOR ONDA")
	_big_stat(highlight_row, "💀", str(int(stats.get("total_kills", 0))), "ABATES TOTAIS")
	_big_stat(highlight_row, "⏱️", "%.1f h" % (float(stats.get("total_playtime", 0.0)) / 3600.0), "TEMPO JOGADO")
	_big_stat(highlight_row, "🏃", str(int(stats.get("total_runs", 0))), "EXPEDIÇÕES")

	_divider(parent)
	_label(parent, "DESEMPENHO POR CLASSE", 14, Color("#a8916c"))

	# Melhores waves por classe
	var class_best: Dictionary = stats.get("class_best_wave", {})
	var class_runs: Dictionary = stats.get("class_runs", {})
	var class_row := GridContainer.new()
	class_row.columns = 3 if not compact else 2
	class_row.add_theme_constant_override("h_separation", 10)
	class_row.add_theme_constant_override("v_separation", 10)
	class_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(class_row)
	for cid in ContentCatalog.CLASS_ORDER:
		var cd: ClassData = ContentCatalog.classes.get(cid)
		if cd == null:
			continue
		var ccard := _panel(class_row, PANEL, Vector2.ZERO)
		ccard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cinner := VBoxContainer.new()
		cinner.add_theme_constant_override("separation", 4)
		ccard.add_child(_pad(cinner, 10, 8, 10, 8))
		_label(cinner, cd.display_name, 14, cd.accent, HORIZONTAL_ALIGNMENT_CENTER)
		_label(cinner, "Melhor onda: %d" % int(class_best.get(cid, 0)), 12, Color("#aaa"), HORIZONTAL_ALIGNMENT_CENTER)
		_label(cinner, "Expedições: %d" % int(class_runs.get(cid, 0)), 11, Color("#888"), HORIZONTAL_ALIGNMENT_CENTER)
		# Mini barra de progresso
		var cbar := ProgressBar.new()
		cbar.show_percentage = false
		cbar.min_value = 0
		cbar.max_value = 8
		cbar.value = int(class_best.get(cid, 0))
		cbar.custom_minimum_size.y = 6
		cbar.add_theme_stylebox_override("fill", _progress_fill(cd.accent))
		cbar.add_theme_stylebox_override("background", _progress_bg())
		cinner.add_child(cbar)

	_divider(parent)
	_label(parent, "ESTATÍSTICAS GERAIS", 14, Color("#a8916c"))

	# Stats em lista
	var stat_items := [
		{"label": "TEMPO TOTAL JOGADO", "val": "%.1f min" % (float(stats.get("total_playtime", 0.0)) / 60.0), "icon": "⏱️"},
		{"label": "INIMIGOS DERROTADOS", "val": str(int(stats.get("total_kills", 0))), "icon": "💀"},
		{"label": "EXPEDIÇÕES REALIZADAS", "val": str(int(stats.get("total_runs", 0))), "icon": "🏃"},
		{"label": "OURO TOTAL COLETADO", "val": "%d ⚜" % int(stats.get("total_gold_earned", 0)), "icon": "💰"},
		{"label": "ONDA MAIS ALTA", "val": "Onda %d" % best_wave, "icon": "🌊"},
		{"label": "CHEFES DERROTADOS", "val": str(int(stats.get("total_bosses_killed", 0))), "icon": "👑"},
		{"label": "ELITES ELIMINADAS", "val": str(int(stats.get("total_elites_killed", 0))), "icon": "💥"},
		{"label": "ABATES NO MELHOR RUN", "val": str(int(stats.get("best_run_kills", 0))), "icon": "🏆"},
		{"label": "CONQUISTAS OBTIDAS", "val": "%d/%d" % [SaveManager.get_achievement_count(), ContentCatalog.achievements.size()], "icon": "★"},
	]
	# Habilidade mais usada
	var most_used := str(stats.get("most_used_ability", ""))
	if not most_used.is_empty() and ContentCatalog.abilities.has(most_used):
		var ab_name := str(ContentCatalog.abilities[most_used].display_name)
		stat_items.append({"label": "HABILIDADE FAVORITA", "val": ab_name, "icon": "✦"})

	var grid := GridContainer.new()
	grid.columns = 2 if not compact else 1
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	parent.add_child(grid)
	for stat in stat_items:
		var scard := _panel(grid, PANEL, Vector2.ZERO)
		scard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var srow := HBoxContainer.new()
		srow.add_theme_constant_override("separation", 10)
		scard.add_child(_pad(srow, 12, 8, 12, 8))
		_label(srow, str(stat.get("icon", "•")), 16, Color("#aaa"), HORIZONTAL_ALIGNMENT_CENTER).custom_minimum_size.x = 28
		var slabel := _label(srow, str(stat.label), 13, Color("#889b92"))
		slabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_label(srow, str(stat.val), 14, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)

func _big_stat(parent: Node, icon: String, value: String, label: String) -> void:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 3)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	_label(box, icon, 22, Color("white"), HORIZONTAL_ALIGNMENT_CENTER)
	_label(box, value, 26, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_label(box, label, 10, Color("#888"), HORIZONTAL_ALIGNMENT_CENTER)

# ═══════════════════════════════════════════════════════════
# CONFIGURAÇÕES
# ═══════════════════════════════════════════════════════════
func _build_settings(parent: VBoxContainer) -> void:
	_build_page_heading(parent, "CONFIGURAÇÕES", "Suas preferências ficam salvas neste dispositivo.")
	var settings: Dictionary = SaveManager.data.settings
	var compact := get_viewport_rect().size.x < 620.0
	_label(parent, "ÁUDIO", 13, Color("#a8916c"))
	for setting in [{"id":"master", "name":"Volume geral"}, {"id":"music", "name":"Música"}, {"id":"effects", "name":"Efeitos sonoros"}]:
		var card := _panel(parent, PANEL, Vector2.ZERO)
		var layout: Control = VBoxContainer.new() if compact else HBoxContainer.new()
		layout.add_theme_constant_override("separation", 8)
		card.add_child(_pad(layout, 12, 8, 12, 8))
		var value_label: Label
		if compact:
			_label(layout, setting.name, 14, Color("#d8dfd4"))
		var slider_row := HBoxContainer.new() if compact else layout
		if compact:
			layout.add_child(slider_row)
			value_label = _label(slider_row, "%d%%" % roundi(float(settings.get(setting.id, 1.0)) * 100.0), 12, MINT, HORIZONTAL_ALIGNMENT_RIGHT)
			value_label.custom_minimum_size.x = 48
		else:
			_label(slider_row, setting.name, 14, Color("#d8dfd4"))
			value_label = _label(slider_row, "%d%%" % roundi(float(settings.get(setting.id, 1.0)) * 100.0), 12, MINT, HORIZONTAL_ALIGNMENT_RIGHT)
			value_label.custom_minimum_size.x = 48
		var slider := HSlider.new()
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = float(settings.get(setting.id, 1.0))
		slider.value_changed.connect(_setting_changed.bind(setting.id))
		slider.value_changed.connect(_update_setting_value.bind(value_label))
		if compact:
			slider_row.add_child(slider)
			slider_row.move_child(value_label, 0)
		else:
			slider_row.add_child(slider)
			slider_row.move_child(slider, 1)
			slider_row.move_child(value_label, 2)
	_divider(parent)
	_label(parent, "INTERFACE", 13, Color("#a8916c"))
	var ui_scale_card := _panel(parent, PANEL, Vector2.ZERO)
	var ui_layout: Control = VBoxContainer.new() if compact else HBoxContainer.new()
	ui_layout.add_theme_constant_override("separation", 8)
	ui_scale_card.add_child(_pad(ui_layout, 12, 8, 12, 8))
	var ui_val_label: Label
	if compact:
		_label(ui_layout, "Tamanho do texto", 14, Color("#d8dfd4"))
	var ui_row := HBoxContainer.new() if compact else ui_layout
	if compact:
		ui_layout.add_child(ui_row)
		ui_val_label = _label(ui_row, "%d%%" % roundi(float(settings.get("ui_scale", 1.0)) * 100.0), 12, MINT, HORIZONTAL_ALIGNMENT_RIGHT)
		ui_val_label.custom_minimum_size.x = 48
	else:
		_label(ui_row, "Tamanho do texto", 14, Color("#d8dfd4"))
		ui_val_label = _label(ui_row, "%d%%" % roundi(float(settings.get("ui_scale", 1.0)) * 100.0), 12, MINT, HORIZONTAL_ALIGNMENT_RIGHT)
		ui_val_label.custom_minimum_size.x = 48
	var ui_slider := HSlider.new()
	ui_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui_slider.min_value = 0.85
	ui_slider.max_value = 1.2
	ui_slider.step = 0.05
	ui_slider.value = float(settings.get("ui_scale", 1.0))
	ui_slider.value_changed.connect(_setting_changed.bind("ui_scale"))
	ui_slider.value_changed.connect(_update_setting_value.bind(ui_val_label))
	ui_slider.drag_ended.connect(_on_text_scale_drag_ended)
	if compact:
		ui_row.add_child(ui_slider)
		ui_row.move_child(ui_val_label, 0)
	else:
		ui_row.add_child(ui_slider)
		ui_row.move_child(ui_slider, 1)
		ui_row.move_child(ui_val_label, 2)
	var fullscreen := CheckButton.new()
	fullscreen.text = "Tela cheia (PC)"
	fullscreen.add_theme_font_size_override("font_size", roundi(14 * _ui_scale()))
	fullscreen.button_pressed = bool(settings.get("fullscreen", false))
	fullscreen.toggled.connect(_fullscreen_changed)
	parent.add_child(fullscreen)
	var vibration := CheckButton.new()
	vibration.text = "Vibração (celular)"
	vibration.add_theme_font_size_override("font_size", roundi(14 * _ui_scale()))
	vibration.button_pressed = bool(settings.get("vibration", true))
	vibration.toggled.connect(func(value: bool) -> void: SaveManager.data.settings.vibration = value; SaveManager.save_game())
	parent.add_child(vibration)
	if not OS.has_feature("mobile"):
		_divider(parent)
		_label(parent, "VÍDEO", 13, Color("#a8916c"))
		var resolution_row := HBoxContainer.new()
		resolution_row.add_theme_constant_override("separation", 14)
		parent.add_child(resolution_row)
		_label(resolution_row, "Resolução", 14, Color("#d8dfd4"))
		var resolution := OptionButton.new()
		resolution.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		resolution.add_theme_font_size_override("font_size", roundi(13 * _ui_scale()))
		var resolutions := ["1280x720", "1600x900", "1920x1080"]
		for index in resolutions.size():
			resolution.add_item(resolutions[index])
			if resolutions[index] == str(settings.get("resolution", "1280x720")):
				resolution.select(index)
		resolution.item_selected.connect(_resolution_changed)
		resolution_row.add_child(resolution)
	_divider(parent)
	_label(parent, "Idioma: Português (Brasil)   ·   Versão: 0.9.0-alpha", 12, Color("#94aaa4"))
	_label(parent, "NOVO COMEÇO", 13, Color("#e7b19c"))
	_label(parent, "Apaga XP, ouro, cristais, itens, talentos, desbloqueios, campanha, registros e preferências deste jogador.", 12, Color("#d8bcb3"))
	var reset_button := _button(parent, "RESETAR TODO O PROGRESSO", _confirm_reset, false, 48)
	reset_button.name = "ResetPlayerProgress"
	reset_button.add_theme_color_override("font_color", Color("#ffb8a6"))
	reset_button.add_theme_color_override("font_hover_color", Color("#ffe1d6"))

func _confirm_reset() -> void:
	if GameManager.run_active or NetworkSession.running:
		_page_notice("Saia da partida antes de resetar o jogador.")
		return
	if get_node_or_null("ResetProgressConfirmation") != null:
		return
	var dialog := ConfirmationDialog.new()
	dialog.name = "ResetProgressConfirmation"
	dialog.title = "Recomeçar do zero?"
	dialog.dialog_autowrap = true
	dialog.dialog_text = "Todo o progresso salvo neste computador será apagado: XP de todas as classes, ouro, cristais, equipamentos, talentos, melhorias, desbloqueios, campanha, conquistas e registros.\n\nAs preferências também voltarão ao padrão. Você sairá da sala online, se estiver em uma. Esta ação não pode ser desfeita."
	dialog.get_ok_button().text = "APAGAR TUDO"
	dialog.get_cancel_button().text = "CANCELAR"
	dialog.confirmed.connect(func() -> void: dialog.hide(); dialog.queue_free(); call_deferred("_reset_player_progress"))
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(maxi(220, mini(460, roundi(get_viewport_rect().size.x - 32.0))), 220))
	dialog.get_cancel_button().grab_focus()

func _reset_player_progress() -> void:
	var error := SaveManager.reset_progress()
	if error != OK:
		_page_notice("Saia da partida antes de resetar o jogador." if error == ERR_BUSY else "Não foi possível gravar o novo save. Seu progresso foi mantido.")
		return
	if NetworkSession.active:
		NetworkSession.close("Sala encerrada: o jogador recomeçou do zero.")
	NetworkSession.config.clear()
	NetworkSession.local_profile.clear()
	GameManager.finish_run()
	GameManager.active_class = "warrior"
	GameManager.active_map = "verdant_reach"
	selected_class = "warrior"
	selected_map = "verdant_reach"
	selected_phase = 1
	selected_difficulty = 0
	TalentManager.set_tree("general")
	TalentManager.set_class(selected_class)
	online_draft.clear()
	forge_draft.clear()
	transmutation_draft.clear()
	relics_draft.clear()
	upgrades_draft.clear()
	characters_draft.clear()
	page_history.clear()
	scroll_positions.clear()
	inventory_selected_slot = ""
	forge_selected_recipe = ""
	upgrade_filter = "all"
	forge_class_filter = "all"
	achievement_filter = "all"
	bestiary_region = "all"
	AudioManager.apply_settings()
	_apply_saved_settings()
	_build_page("home")
	page_history.clear()
	_page_notice("Progresso resetado. Sua nova jornada começa na primeira fase, com os personagens e equipamentos iniciais.")

# ═══════════════════════════════════════════════════════════
# HELPERS DE UI
# ═══════════════════════════════════════════════════════════
func _progress_fill(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(3)
	return s

func _progress_bg() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#29392e")
	s.set_corner_radius_all(3)
	return s

func _divider(parent: Node) -> void:
	var line := ColorRect.new()
	line.color = STYLE.LINE
	line.custom_minimum_size = Vector2(0, 1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(line)

func _update_setting_value(value: float, label: Label) -> void:
	label.text = "%d%%" % roundi(value * 100.0)

func _setting_changed(value: float, setting_id: String) -> void:
	SaveManager.data.settings[setting_id] = value
	SaveManager.save_game()
	if setting_id != "ui_scale":
		AudioManager.apply_settings()
		var bus := AudioServer.get_bus_index("Master") if setting_id == "master" else AudioServer.get_bus_index("Music") if setting_id == "music" else AudioServer.get_bus_index("SFX")
		if bus >= 0:
			AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(value, 0.001)))

func _on_text_scale_drag_ended(_changed: bool) -> void:
	_build_page("settings")

func _resolution_changed(index: int) -> void:
	var sizes := [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
	var names := ["1280x720", "1600x900", "1920x1080"]
	DisplayServer.window_set_size(sizes[index])
	SaveManager.data.settings.resolution = names[index]
	SaveManager.save_game()

func _fullscreen_changed(value: bool) -> void:
	SaveManager.data.settings.fullscreen = value
	SaveManager.save_game()
	if value:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _apply_saved_settings() -> void:
	var settings: Dictionary = SaveManager.data.settings
	if bool(settings.get("fullscreen", false)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var pieces := str(settings.get("resolution", "1280x720")).split("x")
		if pieces.size() == 2:
			DisplayServer.window_set_size(Vector2i(int(pieces[0]), int(pieces[1])))

func _page_notice(message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "Expedição"
	add_child(dialog)
	var popup_width := maxi(220, mini(400, roundi(get_viewport_rect().size.x - 24.0)))
	dialog.popup_centered(Vector2i(popup_width, 150))

# ═══════════════════════════════════════════════════════════
# JOGO
# ═══════════════════════════════════════════════════════════
func _start_game(restart: bool) -> void:
	if NetworkSession.active:
		NetworkSession.close("Sala encerrada para iniciar uma expedição solo.")
	if not SaveManager.is_class_unlocked(selected_class) or not SaveManager.phase_unlocked(selected_map, selected_phase, selected_difficulty):
		return
	SaveManager.set_selected_class(selected_class)
	SaveManager.data.selected_map = selected_map
	SaveManager.data.selected_phase = selected_phase
	SaveManager.data.selected_difficulty = selected_difficulty
	TalentManager.set_class(selected_class)
	SaveManager.save_game()
	if active_game != null and is_instance_valid(active_game):
		active_game.queue_free()
	active_game = GAME_SCENE.instantiate() as ExpeditionGame
	active_game.player_class = selected_class
	active_game.map_id = selected_map
	active_game.phase_number = selected_phase
	active_game.difficulty_tier = selected_difficulty
	GameManager.begin_run(selected_class, selected_map)
	active_game.return_to_menu.connect(_return_to_menu)
	active_game.restart_requested.connect(_start_game.bind(true))
	active_game.next_stage_requested.connect(_next_stage)
	AudioManager.menu_music(false)
	shell.hide()
	backdrop_layer.hide()
	add_child(active_game)

func _next_stage() -> void:
	var ordinal := CampaignRules.ordinal(selected_map, selected_phase) + 1
	var tier := selected_difficulty
	if ordinal >= CampaignRules.TOTAL_PHASES:
		ordinal = 0
		tier += 1
	var next_id: String = ContentCatalog.MAP_ORDER[floori(float(ordinal) / 10.0)]
	var phase := ordinal % 10 + 1
	if SaveManager.phase_unlocked(next_id, phase, tier):
		selected_map = next_id
		selected_phase = phase
		selected_difficulty = tier
		get_tree().paused = false
		_start_game(false)
		return
	_return_to_menu()
	_build_page("maps")

func _return_to_menu() -> void:
	get_tree().paused = false
	GameManager.finish_run()
	if active_game != null and is_instance_valid(active_game):
		active_game.queue_free()
	active_game = null
	backdrop_layer.show()
	shell.show()
	_build_page("home")
	page_history.clear()

func _quit_game() -> void:
	get_tree().quit()

# ═══════════════════════════════════════════════════════════
# LOOKUP HELPERS
# ═══════════════════════════════════════════════════════════
func _class_name(id: String) -> String:
	var data: ClassData = ContentCatalog.classes.get(id)
	return data.display_name if data != null else "Viajante"

func _class_subtitle(id: String) -> String:
	return {"warrior":"VIGÍLIA E AÇO", "mage":"CENTELHA ARCANA", "ranger":"PASSO SILENCIOSO", "assassin":"FIO E SOMBRA", "druid":"RAIZ E SEIVA", "paladin":"LUZ E JURAMENTO"}.get(id, "VIGÍLIA")

func _rarity_name(id: String) -> String:
	return {"common":"Comum", "uncommon":"Incomum", "rare":"Rara", "epic":"Épica", "legendary":"Lendária", "demigod":"Semideus", "divine":"Deus"}.get(id, id.capitalize())

func _rarity_color(id: String) -> Color:
	return RARITY_COLORS.get(id, GOLD)

func _ability_mark(id: String) -> String:
	return {"ember_orb":"◉", "thorn_aura":"✧", "storm_arc":"ϟ", "starfall":"✴", "swift_feet":"➤", "vital_bloom":"✿", "keen_edge":"⚔", "rapid_hands":"✦", "lucky_find":"◇", "second_wind":"♥", "iron_skin":"🛡", "hunters_pace":"💨", "lifesteal":"🩸", "berserker":"🔥", "frost_nova":"❄", "echo_strike":"⚡", "blade_storm":"🌀", "time_warp":"⏳", "phoenix_flame":"🔥", "void_rift":"💠"}.get(id, "✦")

# ═══════════════════════════════════════════════════════════
# FACTORY HELPERS
# ═══════════════════════════════════════════════════════════
func _panel(parent: Node, color: Color, minimum := Vector2.ZERO) -> PanelContainer:
	var panel := preload("res://scripts/ui/menu/animated_panel.gd").new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = minimum
	var style := StyleBoxFlat.new()
	style.bg_color = color.lerp(PANEL, 0.55)
	style.border_color = STYLE.LINE
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.015, 0.022, 0.018, 0.36)
	style.shadow_size = 0
	style.shadow_offset = Vector2(0, 4)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel

func _pad(child: Control, left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	margin.add_child(child)
	return margin

func _label(parent: Node, value: String, font_size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = STYLE.clean_text(value)
	label.add_theme_font_size_override("font_size", roundi(maxi(font_size, 11) * _ui_scale()))
	label.add_theme_color_override("font_color", STYLE.MUTED if color.get_luminance() < 0.15 else color)
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = false
	if parent is HBoxContainer or parent is VBoxContainer:
		label.custom_minimum_size.x = minf(160, STYLE.body_font().get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(font_size, 11)).x)
	parent.add_child(label)
	return label

func _button(parent: Node, value: String, callback: Callable, primary := false, height := 48) -> Button:
	var button := preload("res://scripts/ui/menu/menu_button.gd").new()
	button.text = value
	button.is_primary = primary
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.custom_minimum_size.y = height
	if parent is HBoxContainer:
		button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
