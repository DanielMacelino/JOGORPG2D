extends VBoxContainer
## Six independent constellations per class, with one graph visible at a time.
signal back_requested
signal class_selected(index: int)
const ART := preload("res://scripts/ui/wild_theme.gd")
const GLYPH := preload("res://scripts/ui/talent_glyph.gd")
const HOME := preload("res://scripts/ui/menu/home_screen.gd")
const RECORDS := preload("res://scripts/ui/menu/records_screen.gd")
var body: HBoxContainer
var canvas: TreeCanvas
var canvas_panel: PanelContainer
var detail_panel: PanelContainer
var class_panel: PanelContainer
var branch_grid: GridContainer
var branch_buttons: Dictionary = {}
var account_label: Label
var progress_label: Label
var progress_bar: ProgressBar
var node_name: Label
var node_branch: Label
var node_description: Label
var node_status: Label
var allocate_button: Button
var refund_button: Button
var detail_toggle: Button
var selected_id := "origin"
var refund_pending := false
var views: Dictionary = {}
var header: GridContainer
var canvas_fit_queued := false
var class_picker: OptionButton
var portrait: Control
var character_stats: Label
var show_details := false

func _ready() -> void:
	name = "TalentScreen"
	size_flags_horizontal = SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 8)
	_build_header()
	branch_grid = GridContainer.new()
	branch_grid.name = "TalentCategories"
	branch_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	branch_grid.add_theme_constant_override("h_separation", 6)
	branch_grid.add_theme_constant_override("v_separation", 6)
	add_child(branch_grid)
	for category in TalentManager.TREE_ORDER:
		var button := CategoryButton.new()
		button.name = "TalentCategory_" + str(category)
		button.category = str(category)
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 48 if get_viewport_rect().size.x < 760 else 56
		button.pressed.connect(select_tree.bind(str(category)))
		branch_grid.add_child(button)
		branch_buttons[category] = button
	body = HBoxContainer.new()
	body.name = "TalentWorkspace"
	body.add_theme_constant_override("separation", 10)
	body.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(body)
	_build_character()
	canvas_panel = PanelContainer.new()
	canvas_panel.name = "TalentGraphFrame"
	canvas_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	canvas_panel.add_theme_stylebox_override("panel", ART.panel(Color("#07130f"), 4))
	body.add_child(canvas_panel)
	canvas = TreeCanvas.new()
	canvas.name = "SelectedTalentTree"
	canvas.editor = self
	canvas.custom_minimum_size = Vector2(0, 380)
	canvas.clip_contents = true
	canvas.mouse_filter = MOUSE_FILTER_STOP
	canvas.focus_mode = FOCUS_ALL
	canvas_panel.add_child(canvas)
	_build_details()
	_build_footer()
	TalentManager.changed.connect(_refresh)
	resized.connect(_layout)
	selected_id = TalentManager.root_id()
	_refresh()
	_layout()
	canvas.fit_tree.call_deferred()

func _build_header() -> void:
	header = GridContainer.new()
	header.add_theme_constant_override("h_separation", 16)
	header.add_theme_constant_override("v_separation", 6)
	add_child(header)
	var back := HOME.OrnateAction.new()
	back.name = "TalentBack"
	back.text = "VOLTAR"
	back.custom_minimum_size = Vector2(112, 38)
	back.size_flags_horizontal = SIZE_SHRINK_BEGIN
	back.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title_box)
	var title := _label("CONSTELAÇÕES", 22 if get_viewport_rect().size.x < 760 else 28, ART.TEXT)
	title.add_theme_font_override("font", ART.title_font())
	title_box.add_child(title)
	title_box.add_child(_label("6 árvores · 193 nós cada", 11, ART.MUTED))
	class_picker = OptionButton.new()
	class_picker.name = "TalentClassPicker"
	class_picker.fit_to_longest_item = false
	class_picker.size_flags_horizontal = SIZE_EXPAND_FILL
	class_picker.custom_minimum_size.y = 36
	for id in ContentCatalog.CLASS_ORDER:
		class_picker.add_item(ContentCatalog.classes[id].display_name + " - Nv %d" % TalentManager.character_level(id))
		class_picker.set_item_disabled(class_picker.item_count - 1, not SaveManager.is_class_unlocked(id))
	class_picker.select(ContentCatalog.CLASS_ORDER.find(TalentManager.class_id))
	class_picker.item_selected.connect(func(index: int) -> void: class_selected.emit(index))
	add_child(class_picker)
	add_child(RECORDS.Rule.new())

func _build_character() -> void:
	class_panel = PanelContainer.new()
	class_panel.custom_minimum_size.x = 145
	class_panel.add_theme_stylebox_override("panel", ART.panel(Color("#091812"), 10))
	body.add_child(class_panel)
	var box := VBoxContainer.new()
	class_panel.add_child(box)
	portrait = preload("res://scripts/ui/menu_portrait.gd").new()
	portrait.class_id = TalentManager.class_id
	portrait.custom_minimum_size.y = 210
	portrait.size_flags_horizontal = SIZE_EXPAND_FILL
	box.add_child(portrait)
	var name_label := _label(ContentCatalog.classes[TalentManager.class_id].display_name, 15, ART.GOLD)
	name_label.add_theme_font_override("font", ART.title_font())
	box.add_child(name_label)
	character_stats = _label("", 12, ART.TEXT)
	box.add_child(character_stats)

func _build_details() -> void:
	detail_panel = PanelContainer.new()
	detail_panel.name = "TalentDetails"
	detail_panel.add_theme_stylebox_override("panel", ART.panel(Color("#101e19"), 12))
	body.add_child(detail_panel)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 10)
	detail_panel.add_child(details)
	node_branch = _label("", 11, ART.GOLD)
	details.add_child(node_branch)
	node_name = _label("", 20, ART.TEXT)
	node_name.add_theme_font_override("font", ART.title_font())
	details.add_child(node_name)
	node_description = _label("", 13, ART.TEXT)
	details.add_child(node_description)
	details.add_child(RECORDS.Rule.new())
	node_status = _label("", 11, ART.MUTED)
	node_status.size_flags_vertical = SIZE_EXPAND_FILL
	details.add_child(node_status)
	allocate_button = _button("APRENDER", true)
	allocate_button.name = "TalentAllocate"
	allocate_button.pressed.connect(_allocate_selected)
	details.add_child(allocate_button)

func _build_footer() -> void:
	var footer := HFlowContainer.new()
	footer.add_theme_constant_override("h_separation", 8)
	footer.add_theme_constant_override("v_separation", 6)
	add_child(footer)
	account_label = _label("", 16, ART.GOLD)
	account_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	footer.add_child(account_label)
	for entry in [["-", 0.8], ["+", 1.25]]:
		var button := _button(str(entry[0]))
		button.custom_minimum_size = Vector2(42, 38)
		button.pressed.connect(_zoom.bind(float(entry[1])))
		footer.add_child(button)
	var fit := _button("VER TUDO")
	fit.pressed.connect(canvas.fit_tree)
	footer.add_child(fit)
	detail_toggle = _button("DETALHES")
	detail_toggle.pressed.connect(func() -> void:
		show_details = not show_details
		_layout())
	footer.add_child(detail_toggle)
	refund_button = _button("REDISTRIBUIR ÁRVORE")
	refund_button.pressed.connect(_refund)
	footer.add_child(refund_button)
	progress_label = _label("", 11, ART.MUTED)
	add_child(progress_label)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 5
	progress_bar.show_percentage = false
	progress_bar.add_theme_stylebox_override("background", ART.panel(ART.LINE, 0))
	progress_bar.add_theme_stylebox_override("fill", ART.panel(ART.GOLD, 0))
	add_child(progress_bar)

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", roundi(font_size * clampf(float(SaveManager.data.settings.get("ui_scale", 1)), 0.85, 1.2)))
	return label

func _button(value: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 38
	ART.apply_button(button, primary)
	return button

func _layout() -> void:
	if body == null: return
	var narrow := size.x < 760
	header.columns = 2 if size.x >= 440 else 1
	branch_grid.columns = 6 if size.x >= 1060 else (3 if size.x >= 440 else 2)
	class_panel.visible = size.x >= 1060
	detail_toggle.visible = narrow
	canvas_panel.visible = not narrow or not show_details
	detail_panel.visible = not narrow or show_details
	detail_panel.custom_minimum_size.x = 0 if narrow else 235
	detail_panel.size_flags_horizontal = SIZE_EXPAND_FILL if narrow else SIZE_FILL
	if not canvas_fit_queued:
		canvas_fit_queued = true
		call_deferred("_fit_canvas_height")
	detail_toggle.text = "VER ÁRVORE" if show_details else "DETALHES"

func _fit_canvas_height() -> void:
	canvas_fit_queued = false
	if not is_inside_tree(): return
	var wrapper := get_parent().get_parent() as Control
	if wrapper == null or wrapper.size.y < 1: return
	var reserved := 0.0
	var visible_count := 0
	for child in get_children():
		if child is Control and child.visible:
			visible_count += 1
			if child != body: reserved += child.get_combined_minimum_size().y
	reserved += maxf(0, visible_count - 1) * get_theme_constant("separation")
	canvas.custom_minimum_size.y = clampf(wrapper.size.y - reserved, 130, 550)

func _refresh() -> void:
	if canvas == null or not is_inside_tree(): return
	if not TalentManager.nodes.has(selected_id): selected_id = TalentManager.root_id()
	account_label.text = "%d PONTOS DISPONÍVEIS" % TalentManager.points()
	progress_label.text = "Nv %d · %d / %d XP · Pontos do personagem" % [TalentManager.character_level(), TalentManager.xp_into_level(), TalentManager.xp_for_next_level()]
	progress_bar.max_value = TalentManager.xp_for_next_level()
	progress_bar.value = TalentManager.xp_into_level()
	for category in branch_buttons:
		var button: CategoryButton = branch_buttons[category]
		button.active = category == TalentManager.tree_id
		button.count = TalentManager.tree_allocated(category) + 1
		button.update_text()
	var node: Dictionary = TalentManager.nodes[selected_id]
	node_name.text = str(node.name)
	node_description.text = str(node.description)
	node_branch.text = "%s - %s" % [TalentManager.BRANCH_NAMES[TalentManager.tree_id].to_upper(), "SUPREMO" if node.keystone else ("TALENTO MAIOR" if node.notable else "PASSIVA")]
	var learned := TalentManager.is_allocated(selected_id)
	var available := TalentManager.can_allocate(selected_id)
	allocate_button.disabled = not available
	allocate_button.text = "APRENDIDO" if learned else "APRENDER - %d PONTO(S)" % int(node.cost)
	if learned:
		node_status.text = "Ativo nas expedições desta classe." if int(node.cost) > 0 else "Escolha um dos caminhos conectados ao centro."
	elif available:
		node_status.text = "Caminho conectado. Este bônus será permanente."
	elif TalentManager.character_level() < int(node.required_level):
		node_status.text = "Requer nível %d do personagem." % int(node.required_level)
	elif TalentManager.points() < int(node.cost):
		node_status.text = "Requer %d ponto(s). Evolua este personagem." % int(node.cost)
	else:
		node_status.text = "Aprenda pelo menos um nó vizinho ligado por uma linha nesta árvore."
	canvas.selected_id = selected_id
	canvas.available_nodes.clear()
	for id in TalentManager.nodes: canvas.available_nodes[id] = TalentManager.can_allocate(id)
	canvas.queue_redraw()
	refund_button.disabled = TalentManager.tree_allocated(TalentManager.tree_id) == 0
	refund_button.text = "CONFIRMAR?" if refund_pending else "REDISTRIBUIR ÁRVORE"
	var actor := SurvivorPlayer.new()
	actor.configure(TalentManager.class_id, {})
	character_stats.text = "NÍVEL %d\n\nVIDA %d\nDANO %d\nATAQUE %.2f/s\nDEFESA %d" % [actor.character_level, roundi(actor.max_health), roundi(actor.damage), 1.0 / actor.attack_cooldown, roundi(actor.defense)]
	actor.free()

func select_tree(category: String) -> void:
	if not TalentManager.TREE_ORDER.has(category): return
	views[TalentManager.tree_id] = {"zoom": canvas.zoom, "pan": canvas.pan, "fit": canvas.fit_mode, "selected": selected_id}
	refund_pending = false
	show_details = false
	TalentManager.set_tree(category)
	var view: Dictionary = views.get(category, {})
	selected_id = str(view.get("selected", TalentManager.root_id()))
	_refresh()
	_layout()
	if view.is_empty() or bool(view.fit): canvas.fit_tree()
	else:
		canvas.zoom = float(view.zoom)
		canvas.pan = view.pan
		canvas.fit_mode = false
		canvas.queue_redraw()

func select_node(id: String) -> void:
	if not TalentManager.nodes.has(id): return
	selected_id = id
	refund_pending = false
	_refresh()
	if size.x < 760:
		show_details = true
		_layout()

func _allocate_selected() -> void:
	if TalentManager.allocate(selected_id): AudioManager.feedback("talent")

func _zoom(factor: float) -> void:
	canvas.zoom_at(canvas.size * 0.5, factor)

func _refund() -> void:
	if not refund_pending:
		refund_pending = true
		refund_button.text = "CONFIRMAR?"
		return
	refund_pending = false
	TalentManager.refund_tree(TalentManager.tree_id)
	select_node(TalentManager.root_id())

class CategoryButton extends Button:
	var category := "general"
	var active := false
	var count := 1
	func _ready() -> void:
		mouse_default_cursor_shape = CURSOR_POINTING_HAND
		add_theme_font_override("font", ART.title_font())
		add_theme_font_size_override("font_size", 11)
		update_text()
	func update_text() -> void:
		text = "%s\n%d / 193" % [TalentManager.BRANCH_NAMES[category].to_upper(), count]
		var accent: Color = TalentManager.BRANCH_COLORS[category]
		var normal := ART.panel(Color("#1b291e") if active else Color("#08140f"), 6)
		normal.content_margin_left = 26
		normal.content_margin_right = 6
		normal.border_color = accent
		normal.set_border_width_all(2 if active else 1)
		add_theme_stylebox_override("normal", normal)
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color("#26372b")
		add_theme_stylebox_override("hover", hover)
		add_theme_stylebox_override("pressed", hover)
		add_theme_color_override("font_color", accent if active else ART.TEXT)
		queue_redraw()

	func _draw() -> void:
		GLYPH.draw(self, category, Vector2(14, size.y * 0.5), 9, TalentManager.BRANCH_COLORS[category])

class TreeCanvas extends Control:
	const PALETTE = preload("res://scripts/ui/wild_theme.gd")
	var editor: Control
	var selected_id := "origin"
	var available_nodes: Dictionary = {}
	var zoom := 0.46
	var pan := Vector2.ZERO
	var dragging := false
	var did_drag := false
	var drag_start := Vector2.ZERO
	var font: Font = PALETTE.body_font()
	var fit_mode := true

	func _ready() -> void:
		resized.connect(_on_resize)

	func _on_resize() -> void:
		if fit_mode:
			fit_tree.call_deferred()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), PALETTE.INK)
		var offset := size * 0.5 + pan
		draw_set_transform(offset, 0.0, Vector2.ONE * zoom)
		for node in TalentManager.nodes.values():
			var position: Vector2 = node.position
			for parent in node.parents:
				if str(node.id) > str(parent):
					continue
				var from: Vector2 = TalentManager.nodes[str(parent)].position
				var learned: bool = TalentManager.is_allocated(str(node.id)) and TalentManager.is_allocated(str(parent))
				var available: bool = TalentManager.is_allocated(str(parent)) or TalentManager.is_allocated(str(node.id))
				var color: Color = PALETTE.GOLD if learned else (Color("#718568") if available else Color("#2b3e35"))
				draw_line(from, position, color, (2.0 if learned else 1.0) / zoom, true)
		for node in TalentManager.nodes.values():
			var position: Vector2 = node.position
			var id := str(node.id)
			var notable: bool = bool(node.notable)
			var radius := maxf(22.0 if bool(node.keystone) else (18.0 if notable else 13.0), (4.5 if notable else 2.6) / zoom)
			if id == TalentManager.root_id():
				radius = maxf(30.0, 13.0 / zoom)
			var learned: bool = TalentManager.is_allocated(id)
			var available: bool = bool(available_nodes.get(id, false))
			var branch_color: Color = TalentManager.BRANCH_COLORS.get(str(node.branch), PALETTE.GOLD)
			var color: Color = PALETTE.GOLD if learned else (branch_color if available else Color("#41584b"))
			draw_circle(position, radius + 3.0 / zoom, PALETTE.INK)
			draw_circle(position, radius, Color("#53492f") if learned else PALETTE.SURFACE)
			draw_arc(position, radius, 0.0, TAU, 32, color, (2.0 if learned else 1.0) / zoom, true)
			if notable:
				draw_arc(position, radius + 4.0 / zoom, 0.0, TAU, 32, color, 1.0 / zoom, true)
			if id == selected_id:
				draw_arc(position, radius + 8.0 / zoom, 0.0, TAU, 32, PALETTE.TEXT, 1.5 / zoom, true)
			if zoom > 0.46 or notable or id == TalentManager.root_id():
				_draw_symbol(position, str(node.branch), color, radius * 0.6)
			elif learned:
				draw_circle(position, radius * 0.35, PALETTE.GOLD)
		draw_set_transform(Vector2.ZERO)
		draw_string(font, Vector2(14, size.y - 15), "%s  |  %d / 193 nos  |  %d%%" % [TalentManager.BRANCH_NAMES[TalentManager.tree_id], TalentManager.tree_allocated(TalentManager.tree_id) + 1, roundi(zoom * 100)], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, PALETTE.MUTED)

	func _draw_symbol(position: Vector2, branch: String, color: Color, radius: float) -> void:
		GLYPH.draw(self, branch, position, radius, color, 1.5 / zoom)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_at(event.position, 1.14)
				accept_event()
			elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_at(event.position, 1.0 / 1.14)
				accept_event()
			elif event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					grab_focus()
					dragging = true
					did_drag = false
					drag_start = event.position
				elif dragging:
					dragging = false
					if not did_drag:
						_select_at(event.position)
				accept_event()
		elif event is InputEventMouseMotion:
			if dragging:
				fit_mode = false
				pan += event.relative
				did_drag = did_drag or event.position.distance_to(drag_start) > 5.0
				queue_redraw()
				accept_event()
			else:
				var hovered := node_at(event.position)
				tooltip_text = "" if hovered.is_empty() else "%s\n%s" % [TalentManager.nodes[hovered].name, TalentManager.nodes[hovered].description]
		elif event is InputEventScreenTouch:
			if event.pressed:
				dragging = true
				did_drag = false
				drag_start = event.position
			elif dragging:
				dragging = false
				if not did_drag:
					_select_at(event.position)
			accept_event()
		elif event is InputEventScreenDrag:
			fit_mode = false
			pan += event.relative
			did_drag = did_drag or event.position.distance_to(drag_start) > 5.0
			queue_redraw()
			accept_event()
		elif event is InputEventMagnifyGesture:
			zoom_at(event.position, event.factor)
			accept_event()
		elif event is InputEventKey and event.pressed:
			match event.keycode:
				KEY_LEFT: pan.x += 75.0
				KEY_RIGHT: pan.x -= 75.0
				KEY_UP: pan.y += 75.0
				KEY_DOWN: pan.y -= 75.0
				KEY_HOME: fit_tree()
			queue_redraw()

	func _select_at(position: Vector2) -> void:
		var id := node_at(position)
		if not id.is_empty():
			editor.call("select_node", id)

	func node_at(screen_position: Vector2) -> String:
		var world := (screen_position - size * 0.5 - pan) / zoom
		var closest := ""
		var distance := INF
		for node in TalentManager.nodes.values():
			var node_position: Vector2 = node.position
			var current := world.distance_to(node_position)
			var radius := maxf(23.0 if bool(node.notable) else 17.0, 12.0 / zoom)
			if str(node.id) == TalentManager.root_id():
				radius = maxf(35.0, 18.0 / zoom)
			if current < radius and current < distance:
				closest = str(node.id)
				distance = current
		return closest

	func zoom_at(position: Vector2, factor: float) -> void:
		fit_mode = false
		var world := (position - size * 0.5 - pan) / zoom
		zoom = clampf(zoom * factor, 0.08, 1.8)
		pan = position - size * 0.5 - world * zoom
		queue_redraw()

	func fit_tree() -> void:
		fit_mode = true
		if size.x < 1.0 or size.y < 1.0:
			return
		var lower := Vector2.ZERO
		var upper := Vector2.ZERO
		for node in TalentManager.nodes.values():
			var position: Vector2 = node.position
			lower.x = minf(lower.x, position.x)
			lower.y = minf(lower.y, position.y)
			upper.x = maxf(upper.x, position.x)
			upper.y = maxf(upper.y, position.y)
		var bounds := upper - lower + Vector2(160, 160)
		zoom = clampf(minf((size.x - 48.0) / bounds.x, (size.y - 48.0) / bounds.y), 0.08, 0.65)
		pan = -(upper + lower) * 0.5 * zoom
		queue_redraw()

	func focus_node(id: String) -> void:
		fit_mode = false
		var node: Dictionary = TalentManager.nodes.get(id, TalentManager.nodes[TalentManager.root_id()])
		zoom = 0.95
		pan = -Vector2(node.position) * zoom
		queue_redraw()
