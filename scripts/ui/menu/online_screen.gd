extends VBoxContainer
signal back_requested
const ART := preload("res://scripts/ui/wild_theme.gd")
const HOME := preload("res://scripts/ui/menu/home_screen.gd")
const RECORDS := preload("res://scripts/ui/menu/records_screen.gd")
var header: GridContainer
var identity_grid: GridContainer
var portrait: Control
var portrait_caption: Label
var draft: Dictionary = {}
var default_class := "warrior"
var default_map := "verdant_reach"
var default_phase := 1
var default_tier := 0
var columns: GridContainer
var region: OptionButton
var phase: OptionButton
var difficulty: OptionButton
var details: Label
var mode_row: GridContainer
var mode_buttons: Array[Button] = []
var section_switch: HBoxContainer
var section_index := 0
var compact_page := false

func _ready() -> void:
	name = "OnlineScreen"
	size_flags_horizontal = SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 12)
	for pair in [["nickname", SaveManager.data.settings.get("online_name", "Viajante")], ["class", default_class], ["map", default_map], ["phase", default_phase], ["tier", default_tier], ["port", NetworkSession.PORT], ["address", SaveManager.data.settings.get("online_ip", "")], ["tab", 0]]:
		if not draft.has(pair[0]):
			draft[pair[0]] = pair[1]
	compact_page = get_viewport_rect().size.y < 700 or get_viewport_rect().size.x < 700
	if compact_page: add_theme_constant_override("separation", 6)
	_build_header()
	var status := _label(NetworkSession.status, 12, ART.GREEN)
	status.name = "OnlineStatus"
	add_child(status)
	columns = GridContainer.new()
	columns.add_theme_constant_override("h_separation", 14)
	columns.add_theme_constant_override("v_separation", 12)
	columns.size_flags_horizontal = SIZE_EXPAND_FILL
	section_switch = HBoxContainer.new()
	section_switch.add_theme_constant_override("separation", 6)
	add_child(section_switch)
	for index in 2:
		var section := Button.new()
		section.name = "OnlineSection" + str(index)
		section.text = ("EQUIPE" if NetworkSession.active else "VIAJANTE") if index == 0 else "EXPEDIÇÃO"
		section.size_flags_horizontal = SIZE_EXPAND_FILL
		section.custom_minimum_size.y = 42
		ART.apply_button(section)
		section.pressed.connect(func() -> void:
			section_index = index
			draft.section = index
			_adapt())
		section_switch.add_child(section)
	section_index = int(draft.get("section", 0))
	add_child(columns)
	if NetworkSession.active:
		_build_room()
	else:
		_build_setup()
	resized.connect(_adapt)
	call_deferred("_adapt")

func _panel(title: String) -> VBoxContainer:
	var frame := OrnatePanel.new()
	frame.size_flags_horizontal = SIZE_EXPAND_FILL
	var style := ART.panel(Color("#071310", 0.95), 10 if compact_page else 18)
	style.border_color = Color(ART.GOLD, 0.85)
	frame.add_theme_stylebox_override("panel", style)
	columns.add_child(frame)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6 if compact_page else 10)
	frame.add_child(box)
	var heading := _label(title.to_upper(), 18 if compact_page else 23, ART.TEXT)
	heading.add_theme_font_override("font", ART.title_font())
	box.add_child(heading)
	box.add_child(RECORDS.Rule.new())
	return box

func _build_setup() -> void:
	var identity_panel := _panel("Seu viajante")
	identity_grid = GridContainer.new()
	identity_grid.name = "OnlineIdentityLayout"
	identity_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	identity_grid.add_theme_constant_override("h_separation", 18)
	identity_grid.add_theme_constant_override("v_separation", 10)
	identity_panel.add_child(identity_grid)
	var showcase := VBoxContainer.new()
	showcase.size_flags_horizontal = SIZE_EXPAND_FILL
	showcase.size_flags_stretch_ratio = 0.8
	identity_grid.add_child(showcase)
	portrait = TravelerPortrait.new()
	portrait.name = "OnlineCharacterPortrait"
	portrait.size_flags_horizontal = SIZE_EXPAND_FILL
	portrait.size_flags_vertical = SIZE_EXPAND_FILL
	showcase.add_child(portrait)
	portrait_caption = _label("", 12, ART.GOLD)
	portrait_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	showcase.add_child(portrait_caption)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 10)
	identity_grid.add_child(identity)
	identity.add_child(_label("Nome na sala", 11))
	var nickname := LineEdit.new()
	nickname.name = "OnlineNickname"
	nickname.text = str(draft.nickname)
	nickname.max_length = 24
	nickname.custom_minimum_size.y = 42 if compact_page else 44
	_style_input(nickname)
	nickname.text_changed.connect(func(value: String) -> void: draft.nickname = value)
	identity.add_child(nickname)
	identity.add_child(_label("Personagem", 11))
	var classes := _select(identity, "OnlineClass")
	for id in ContentCatalog.CLASS_ORDER:
		if SaveManager.is_class_unlocked(id):
			classes.add_item(ContentCatalog.classes[id].display_name)
			classes.set_item_metadata(classes.item_count - 1, id)
			if id == str(draft.class):
				classes.select(classes.item_count - 1)
	draft.class = str(classes.get_item_metadata(classes.selected))
	_update_portrait()
	classes.item_selected.connect(func(index: int) -> void:
		draft.class = str(classes.get_item_metadata(index))
		_update_portrait())
	identity.add_child(_label("Você leva seus equipamentos, talentos e nível. Cada amigo escolhe o próprio personagem.", 12))
	identity.add_child(_label("Porta da sala", 11))
	var port := SpinBox.new()
	port.name = "OnlinePort"
	port.min_value = 1024
	port.max_value = 65535
	port.value = int(draft.port)
	port.value_changed.connect(func(value: float) -> void: draft.port = roundi(value))
	port.custom_minimum_size.y = 42 if compact_page else 44
	_style_input(port.get_line_edit())
	identity.add_child(port)
	var connection := _panel("Jogar com amigos")
	var tabs := TabContainer.new()
	tabs.name = "OnlineModes"
	tabs.size_flags_horizontal = SIZE_EXPAND_FILL
	tabs.add_theme_stylebox_override("panel", ART.panel(Color("#071310", 0.0), 0))
	tabs.tabs_visible = false
	mode_row = GridContainer.new()
	mode_row.name = "OnlineModeButtons"
	mode_row.columns = 2
	mode_row.size_flags_horizontal = SIZE_EXPAND_FILL
	mode_row.add_theme_constant_override("h_separation", 0)
	mode_row.add_theme_constant_override("v_separation", 6)
	connection.add_child(mode_row)
	for index in 2:
		var mode := ModeTab.new()
		mode.name = "OnlineCreateTab" if index == 0 else "OnlineJoinTab"
		mode.caption = "CRIAR SALA" if index == 0 else "ENTRAR NA SALA"
		mode.join_mode = index == 1
		mode.active = int(draft.tab) == index
		mode.pressed.connect(func() -> void: tabs.current_tab = index)
		mode_buttons.append(mode)
		mode_row.add_child(mode)
	connection.add_child(tabs)
	var host := VBoxContainer.new()
	host.name = "Criar sala"
	host.add_theme_constant_override("separation", 10)
	tabs.add_child(host)
	host.add_child(_label("Escolha a expedição e compartilhe seu IP do Radmin.", 12))
	_build_destination(host, false)
	_button(host, "HOSPEDAR SALA", _host, true, "OnlineHost")
	var join := VBoxContainer.new()
	join.name = "Entrar na sala"
	join.add_theme_constant_override("separation", 10)
	tabs.add_child(join)
	join.add_child(_label("O anfitrião escolhe o mapa. Informe o IP mostrado no Radmin dele e use a mesma porta.", 12))
	join.add_child(_label("IP do anfitrião", 11))
	var address := LineEdit.new()
	address.name = "OnlineAddress"
	address.placeholder_text = "26.12.34.56"
	address.text = str(draft.address)
	address.custom_minimum_size.y = 42 if compact_page else 44
	_style_input(address)
	address.text_changed.connect(func(value: String) -> void: draft.address = value)
	join.add_child(address)
	_button(join, "ENTRAR NA SALA", _join, true, "OnlineJoin")
	tabs.current_tab = int(draft.tab)
	tabs.tab_changed.connect(func(index: int) -> void:
		draft.tab = index
		for mode_index in mode_buttons.size():
			mode_buttons[mode_index].active = mode_index == index
			mode_buttons[mode_index].queue_redraw())
	add_child(_label("Todos devem estar na mesma rede do Radmin VPN e usar a mesma versão do jogo. Permita o jogo no Firewall do Windows.", 11))

func _build_room() -> void:
	var roster := _panel("Sala de espera · %d/4" % NetworkSession.players.size())
	roster.name = "OnlineRoster"
	if not NetworkSession.config.has("map"):
		roster.add_child(_label("Conectando ao anfitrião…", 14))
		_button(roster, "CANCELAR", func() -> void: NetworkSession.close("Conexão cancelada."))
		return
	var room_port := int(NetworkSession.config.get("port", NetworkSession.PORT))
	var addresses: PackedStringArray = []
	if NetworkSession.hosting:
		for ip in IP.get_local_addresses():
			if ip.begins_with("26."): addresses.append(ip)
	else:
		if not str(draft.address).is_empty(): addresses.append(str(draft.address))
	var host_address := ", ".join(addresses)
	for id in NetworkSession.players:
		var entry: Dictionary = NetworkSession.players[id]
		var leader := int(id) == 1
		var card := OrnatePanel.new()
		card.name = "OnlineMember" + str(id)
		card.size_flags_horizontal = SIZE_EXPAND_FILL
		var style := ART.panel(Color("#0c1d18", 0.96), 6 if compact_page else 12)
		style.border_color = ART.GOLD if leader else Color("#5c8975")
		style.set_border_width_all(2 if leader else 1)
		card.add_theme_stylebox_override("panel", style)
		roster.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		card.add_child(row)
		var avatar := MemberPortrait.new()
		avatar.name = "OnlineMemberPortrait" + str(id)
		avatar.class_id = str(entry.class)
		avatar.custom_minimum_size = Vector2(42, 60) if compact_page else Vector2(68, 92)
		row.add_child(avatar)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = SIZE_EXPAND_FILL
		copy.add_theme_constant_override("separation", 5)
		row.add_child(copy)
		var title := _label(str(entry.name), 13 if compact_page else 18, ART.TEXT)
		title.add_theme_font_override("font", ART.title_font())
		copy.add_child(title)
		copy.add_child(_label("%s · NÍVEL %d" % [ContentCatalog.classes[str(entry.class)].display_name, int(entry.stats.character_level)], 11, ART.GOLD))
		copy.add_child(_label("ANFITRIÃO · ONLINE" if leader else "ALIADO · ONLINE", 10, ART.GREEN))
		if leader:
			copy.add_child(_label("Porta %d" % room_port, 11, ART.GOLD))
			var address_row := VBoxContainer.new()
			copy.add_child(address_row)
			address_row.add_child(_label("IP do Radmin: " + (host_address if not host_address.is_empty() else "consulte o Radmin VPN"), 11))
			if not host_address.is_empty():
				var share := _button(address_row, "COPIAR IP E PORTA", func() -> void: DisplayServer.clipboard_set("%s:%d" % [host_address, room_port]), false, "OnlineCopyAddress")
				share.custom_minimum_size.y = 30
	if NetworkSession.players.size() < NetworkSession.MAX_PLAYERS:
		var empty := PanelContainer.new()
		empty.name = "OnlineWaitingSlots"
		empty.size_flags_horizontal = SIZE_EXPAND_FILL
		var empty_style := ART.panel(Color("#06110f", 0.85), 14)
		empty_style.border_color = Color("#557769")
		empty.add_theme_stylebox_override("panel", empty_style)
		roster.add_child(empty)
		var copy := VBoxContainer.new()
		copy.add_theme_constant_override("separation", 6)
		empty.add_child(copy)
		for line in [["+", 27, ART.GOLD], ["AGUARDANDO JOGADORES", 12, ART.TEXT], ["%d vaga(s) livre(s). Compartilhe seu IP do Radmin e a porta com seus amigos." % (NetworkSession.MAX_PLAYERS - NetworkSession.players.size()), 11, ART.MUTED]]:
			var label := _label(str(line[0]), int(line[1]), line[2])
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			copy.add_child(label)
	if NetworkSession.players.size() <= 2:
		var scenery := LobbyScenery.new()
		scenery.custom_minimum_size.y = 30 if compact_page else (105 if NetworkSession.players.size() == 1 else 60)
		scenery.size_flags_horizontal = SIZE_EXPAND_FILL
		roster.add_child(scenery)
	_button(roster, "SAIR DA SALA", func() -> void: NetworkSession.close("Você saiu da sala."), false, "OnlineLeave")
	var destination := _panel("Expedição do grupo")
	destination.name = "OnlineGroupDestination"
	var inset := PanelContainer.new()
	inset.size_flags_horizontal = SIZE_EXPAND_FILL
	var inset_style := ART.panel(Color("#091712", 0.95), 16)
	inset_style.border_color = Color("#77896b")
	inset.add_theme_stylebox_override("panel", inset_style)
	destination.add_child(inset)
	var fields := VBoxContainer.new()
	fields.add_theme_constant_override("separation", 6 if compact_page else 12)
	inset.add_child(fields)
	if NetworkSession.hosting:
		draft.map = str(NetworkSession.config.map)
		draft.phase = int(NetworkSession.config.phase)
		draft.tier = int(NetworkSession.config.tier)
		_build_destination(fields, true)
		var start := _button(destination, "INICIAR EXPEDIÇÃO", func() -> void: NetworkSession.start(), true, "OnlineStart")
		start.custom_minimum_size.y = 40 if compact_page else 62
		start.disabled = NetworkSession.players.size() < 2
		if start.disabled:
			destination.add_child(_label("Aguardando pelo menos mais um viajante para iniciar.", 11, ART.GOLD))
	else:
		for field in [["DIFICULDADE", CampaignRules.difficulty_name(int(NetworkSession.config.tier))], ["REGIÃO", ContentCatalog.maps[str(NetworkSession.config.map)].display_name], ["FASE", "%02d · %s" % [int(NetworkSession.config.phase), CampaignRules.PHASE_NAMES[int(NetworkSession.config.phase) - 1]]]]:
			fields.add_child(_label(str(field[0]), 11, ART.GOLD))
			var value_box := PanelContainer.new()
			value_box.add_theme_stylebox_override("panel", ART.panel(Color("#10201b"), 12))
			fields.add_child(value_box)
			value_box.add_child(_label(str(field[1]), 14, ART.TEXT))
		fields.add_child(_label("OBJETIVO", 11, ART.GOLD))
		fields.add_child(_label(CampaignRules.phase_objective(int(NetworkSession.config.phase)), 12, ART.TEXT))
		var waiting := _button(destination, "AGUARDANDO O ANFITRIÃO", func() -> void: pass, false, "OnlineAwaitHost")
		waiting.disabled = true
		waiting.custom_minimum_size.y = 40 if compact_page else 62

func _build_destination(parent: VBoxContainer, connected: bool) -> void:
	parent.add_child(_label("Dificuldade", 11))
	difficulty = _select(parent, "OnlineDifficulty")
	for tier in range(int(SaveManager.data.highest_difficulty) + 1):
		difficulty.add_item(CampaignRules.difficulty_name(tier))
		difficulty.set_item_metadata(tier, tier)
	difficulty.select(clampi(int(draft.tier), 0, difficulty.item_count - 1))
	parent.add_child(_label("Região", 11))
	region = _select(parent, "OnlineRegion")
	parent.add_child(_label("Fase", 11))
	phase = _select(parent, "OnlinePhase")
	parent.add_child(_label("OBJETIVO", 11, ART.GOLD))
	details = _label("", 12, ART.TEXT)
	parent.add_child(details)
	_refresh_regions()
	difficulty.item_selected.connect(func(index: int) -> void:
		draft.tier = index
		_refresh_regions()
		if connected: _apply_destination())
	region.item_selected.connect(func(index: int) -> void:
		draft.map = str(region.get_item_metadata(index))
		draft.phase = 1
		_refresh_phases()
		if connected: _apply_destination())
	phase.item_selected.connect(func(index: int) -> void:
		draft.phase = int(phase.get_item_metadata(index))
		_refresh_details()
		if connected: _apply_destination())

func _refresh_regions() -> void:
	draft.tier = difficulty.selected
	region.clear()
	for id in ContentCatalog.MAP_ORDER:
		if SaveManager.phase_unlocked(id, 1, int(draft.tier)):
			region.add_item(ContentCatalog.maps[id].display_name)
			region.set_item_metadata(region.item_count - 1, id)
			if id == str(draft.map): region.select(region.item_count - 1)
	draft.map = str(region.get_item_metadata(region.selected))
	_refresh_phases()

func _refresh_phases() -> void:
	phase.clear()
	for number in range(1, 11):
		if SaveManager.phase_unlocked(str(draft.map), number, int(draft.tier)):
			phase.add_item("%02d · %s" % [number, CampaignRules.PHASE_NAMES[number - 1]])
			phase.set_item_metadata(phase.item_count - 1, number)
			if number == int(draft.phase): phase.select(phase.item_count - 1)
	draft.phase = int(phase.get_item_metadata(phase.selected))
	_refresh_details()

func _refresh_details() -> void:
	details.text = CampaignRules.phase_objective(int(draft.phase))

func _apply_destination() -> void:
	NetworkSession.set_destination(str(draft.map), int(draft.phase), int(draft.tier))

func _remember() -> void:
	SaveManager.data.settings.online_name = str(draft.nickname)
	SaveManager.data.settings.online_ip = str(draft.address)
	SaveManager.save_game()

func _host() -> void:
	_remember()
	NetworkSession.host(NetworkSession.profile(str(draft.nickname), str(draft.class)), {"map": str(draft.map), "phase": int(draft.phase), "tier": int(draft.tier)}, int(draft.port))

func _join() -> void:
	_remember()
	NetworkSession.join(str(draft.address), NetworkSession.profile(str(draft.nickname), str(draft.class)), int(draft.port))

func _select(parent: Node, node_name: String) -> OptionButton:
	var button := OptionButton.new()
	button.name = node_name
	button.fit_to_longest_item = false
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 42 if compact_page else 44
	ART.apply_button(button)
	parent.add_child(button)
	return button

func _button(parent: Node, value: String, action: Callable, primary: bool = false, node_name: String = "") -> Button:
	var button := HOME.OrnateAction.new()
	button.primary = primary
	button.action_font_size = 13
	if not node_name.is_empty(): button.name = node_name
	button.text = value
	button.custom_minimum_size.y = 42 if compact_page else 48
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _label(value: String, font_size: int = 12, color: Color = ART.MUTED) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", roundi(font_size * clampf(float(SaveManager.data.settings.get("ui_scale", 1)), 0.85, 1.2)))
	return label

func _adapt() -> void:
	if columns != null:
		var narrow := size.x < 760
		columns.columns = 1 if narrow else 2
		section_switch.visible = narrow and columns.get_child_count() == 2
		for index in columns.get_child_count():
			columns.get_child(index).visible = not section_switch.visible or index == section_index
		for index in section_switch.get_child_count():
			section_switch.get_child(index).disabled = index == section_index
	if mode_row != null:
		mode_row.columns = 2 if mode_row.size.x >= 360 else 1
	if header != null:
		header.columns = 2 if size.x >= 650 else 1
	if identity_grid != null:
		identity_grid.columns = 2 if identity_grid.size.x >= 400 else 1
		portrait.custom_minimum_size = Vector2(0, (180 if compact_page else 310) if identity_grid.columns == 2 else (90 if compact_page else 170))
		portrait.queue_redraw()

func _build_header() -> void:
	header = GridContainer.new()
	header.add_theme_constant_override("h_separation", 22)
	header.add_theme_constant_override("v_separation", 10)
	add_child(header)
	var back := HOME.OrnateAction.new()
	back.name = "OnlineBack"
	back.text = "←  VOLTAR"
	back.custom_minimum_size = Vector2(116, 44) if compact_page else Vector2(136, 44)
	back.size_flags_vertical = SIZE_SHRINK_BEGIN
	back.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back)
	var heading := HBoxContainer.new()
	heading.size_flags_horizontal = SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 14)
	header.add_child(heading)
	var emblem := RECORDS.CompassEmblem.new()
	emblem.custom_minimum_size = Vector2(54, 58)
	emblem.visible = not compact_page
	heading.add_child(emblem)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = SIZE_EXPAND_FILL
	heading.add_child(text)
	var title := _label("EXPEDIÇÃO ONLINE", 21 if compact_page else 30, ART.TEXT)
	title.add_theme_font_override("font", ART.title_font())
	text.add_child(title)
	text.add_child(_label("Prepare seu viajante, crie uma sala ou entre com seus amigos.", 13, ART.TEXT))
	add_child(RECORDS.Rule.new())
	var currencies := HFlowContainer.new()
	currencies.add_theme_constant_override("h_separation", 22)
	add_child(currencies)
	for value in ["◇  OURO DE VÉSPERA  %d" % int(SaveManager.data.gold), "◈  CRISTAIS  %d" % int(SaveManager.data.crystals)]:
		var label := _label(value, 12, ART.GOLD)
		label.name = "OnlineCurrency" + str(currencies.get_child_count())
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		currencies.add_child(label)
	if NetworkSession.active:
		var room_badge := _label("SALA: %d   |   EQUIPE %d/%d" % [int(NetworkSession.config.get("port", NetworkSession.PORT)), NetworkSession.players.size(), NetworkSession.MAX_PLAYERS], 12, ART.GOLD)
		room_badge.name = "OnlineRoomBadge"
		room_badge.autowrap_mode = TextServer.AUTOWRAP_OFF
		currencies.add_child(room_badge)
	add_child(RECORDS.Rule.new())

func _update_portrait() -> void:
	portrait.class_id = str(draft.class)
	portrait.queue_redraw()
	portrait_caption.text = "%s · NÍVEL %d" % [ContentCatalog.classes[str(draft.class)].display_name, TalentManager.character_level(str(draft.class))]

func _style_input(input: LineEdit) -> void:
	var style := ART.panel(Color("#0c1b19"), 12)
	style.border_color = Color("#849986")
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	input.add_theme_stylebox_override("normal", style)
	var focused := style.duplicate() as StyleBoxFlat
	focused.border_color = ART.GOLD
	focused.set_border_width_all(2)
	input.add_theme_stylebox_override("focus", focused)
	input.add_theme_color_override("font_color", ART.TEXT)
	input.add_theme_color_override("caret_color", ART.GOLD)
	input.add_theme_font_size_override("font_size", 14)

class TravelerPortrait extends "res://scripts/ui/menu_portrait.gd":
	const FOREST := preload("res://assets/art/home-portal.png")
	func _ready() -> void:
		super._ready()
		clip_contents = true
		resized.connect(queue_redraw)
	func _draw() -> void:
		var extent := FOREST.get_size() * maxf(size.x / FOREST.get_width(), size.y / FOREST.get_height())
		draw_texture_rect(FOREST, Rect2((size - extent) * 0.5, extent), false, Color(0.27, 0.36, 0.31))
		draw_set_transform(Vector2(size.x * 0.10, size.y * 0.06), 0, Vector2(0.8, 0.88))
		super._draw()
		draw_set_transform(Vector2.ZERO)

class OrnatePanel extends PanelContainer:
	func _ready() -> void:
		resized.connect(queue_redraw)
	func _draw() -> void:
		for corner in [Vector2(4, 4), Vector2(size.x - 4, 4), Vector2(4, size.y - 4), size - Vector2(4, 4)]:
			var axis := Vector2(1 if corner.x < size.x * 0.5 else -1, 1 if corner.y < size.y * 0.5 else -1)
			draw_polyline(PackedVector2Array([corner + Vector2(0, axis.y * 20), corner, corner + Vector2(axis.x * 20, 0), corner + axis * 8, corner + Vector2(0, axis.y * 20)]), ART.GOLD, 1, true)

class ModeTab extends Button:
	var caption := "CRIAR SALA"
	var join_mode := false
	var active := false
	var caption_label: Label
	func _ready() -> void:
		custom_minimum_size = Vector2(0, 58)
		size_flags_horizontal = SIZE_EXPAND_FILL
		mouse_default_cursor_shape = CURSOR_POINTING_HAND
		for state in ["normal", "hover", "pressed", "focus"]:
			add_theme_stylebox_override(state, StyleBoxEmpty.new())
		caption_label = Label.new()
		caption_label.text = caption
		caption_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		caption_label.offset_left = 38
		caption_label.offset_right = -8
		caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		caption_label.clip_text = true
		caption_label.mouse_filter = MOUSE_FILTER_IGNORE
		caption_label.add_theme_font_override("font", ART.title_font())
		caption_label.add_theme_font_size_override("font_size", 12)
		add_child(caption_label)
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
		resized.connect(queue_redraw)
	func _draw() -> void:
		var bright := active or is_hovered() or has_focus()
		var color := Color("#f3cf8b") if bright else Color("#a9b5a6")
		caption_label.add_theme_color_override("font_color", color)
		var fill := Color("#1b2a22") if bright else Color("#081512")
		var shape := PackedVector2Array([Vector2(7, 2), Vector2(size.x - 7, 2), Vector2(size.x - 2, 7), Vector2(size.x - 2, size.y - 9), Vector2(size.x - 7, size.y - 4), Vector2(7, size.y - 4), Vector2(2, size.y - 9), Vector2(2, 7)])
		draw_colored_polygon(shape, fill)
		shape.append(shape[0])
		draw_polyline(shape, color, 2 if active else 1, true)
		if active:
			draw_line(Vector2(9, size.y - 5), Vector2(size.x - 9, size.y - 5), color, 2, true)
			draw_colored_polygon(PackedVector2Array([Vector2(size.x * 0.5 - 6, size.y - 4), Vector2(size.x * 0.5 + 6, size.y - 4), Vector2(size.x * 0.5, size.y)]), color)
		var center := Vector2(23, size.y * 0.5 - 1)
		if join_mode:
			draw_rect(Rect2(center + Vector2(-8, -11), Vector2(14, 22)), color, false, 1.8)
			draw_line(center + Vector2(-13, 0), center + Vector2(2, 0), color, 2, true)
			draw_polyline(PackedVector2Array([center + Vector2(-2, -4), center + Vector2(2, 0), center + Vector2(-2, 4)]), color, 2, true)
		else:
			draw_polyline(PackedVector2Array([center + Vector2(-12, -1), center + Vector2(0, -12), center + Vector2(12, -1)]), color, 2, true)
			draw_polyline(PackedVector2Array([center + Vector2(-8, -2), center + Vector2(-8, 10), center + Vector2(-2, 10), center + Vector2(-2, 3), center + Vector2(3, 3), center + Vector2(3, 10), center + Vector2(8, 10), center + Vector2(8, -2)]), color, 2, true)

class MemberPortrait extends "res://scripts/ui/menu_portrait.gd":
	func _ready() -> void:
		super._ready()
		resized.connect(queue_redraw)
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#061410"))
		draw_rect(Rect2(Vector2.ONE, size - Vector2.ONE * 2), ART.GOLD, false, 1)
		draw_set_transform(Vector2(size.x * 0.08, size.y * 0.08), 0, Vector2(0.84, 0.84))
		super._draw()
		draw_set_transform(Vector2.ZERO)

class LobbyScenery extends Control:
	const FOREST := preload("res://assets/art/home-portal.png")
	func _ready() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		clip_contents = true
		resized.connect(queue_redraw)
	func _draw() -> void:
		var crop := Rect2(0, FOREST.get_height() * 0.5, FOREST.get_width(), FOREST.get_height() * 0.45)
		draw_texture_rect_region(FOREST, Rect2(Vector2.ZERO, size), crop, Color(0.6, 0.67, 0.54))
		for index in 12:
			draw_rect(Rect2(0, float(index) * size.y / 12, size.x, size.y / 12 + 1), Color("#071310", 0.60 * (1.0 - float(index) / 11)))
