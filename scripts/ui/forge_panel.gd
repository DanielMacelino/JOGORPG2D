extends VBoxContainer
signal back_requested
const ART := preload("res://scripts/ui/wild_theme.gd")
const HOME := preload("res://scripts/ui/menu/home_screen.gd")
const RECORDS := preload("res://scripts/ui/menu/records_screen.gd")
const CABINET := preload("res://scripts/ui/relics_panel.gd")
const ICON := preload("res://scripts/ui/equipment_icon.gd")
const STATS := preload("res://scripts/data/equipment_expansion.gd")
const CATEGORIES := [["Todas", "all"], ["Armas", "weapons"], ["Armaduras", "armor"], ["Acessórios", "accessories"]]
const SLOTS := [["Todos", "all"], ["Armas", "weapon"], ["Elmos", "helmet"], ["Armaduras", "armor"], ["Botas", "boots"], ["Anéis", "ring"], ["Amuletos", "amulet"]]
const WEAPONS := [["Todas", "all"], ["Espada", "sword"], ["Cajado", "staff"], ["Arco", "bow"], ["Adagas", "daggers"], ["Raízes", "roots"], ["Martelo", "hammer"]]
var draft: Dictionary = {}
var filters: GridContainer
var class_picker: OptionButton
var slot_picker: OptionButton
var rarity_picker: OptionButton
var weapon_picker: OptionButton
var order_picker: OptionButton
var search: LineEdit
var possible: CheckBox
var list: VBoxContainer
var count_label: Label
var page_label: Label
var previous: Button
var next: Button
var matched_recipes: Array[Dictionary] = []
var page_size := 5
var compact := false
var narrow := false
var currencies: HFlowContainer
var categories: GridContainer
var sections: HBoxContainer
var sidebar: PanelContainer
var subtypes: VBoxContainer
var recipe_frame: PanelContainer
var detail_frame: PanelContainer
var details: VBoxContainer
var notice: Label

func _ready() -> void:
	name = "ForgePanel"
	size_flags_horizontal = SIZE_EXPAND_FILL
	var extent := get_viewport_rect().size
	compact = extent.y < 600 or (extent.x < 600 and extent.y < 720)
	narrow = extent.x < 1050 or compact
	page_size = 1 if extent.y < 430 else (2 if narrow else 5)
	for pair in [["class", "all"], ["slot", "all"], ["rarity", "all"], ["query", ""], ["possible", false], ["page", 0], ["category", "all"], ["weapon", "all"], ["order", "power"], ["section", 1], ["selected", ""]]:
		if not draft.has(pair[0]): draft[pair[0]] = pair[1]
	add_theme_constant_override("separation", 4 if compact else 8)
	_header()
	categories = GridContainer.new()
	categories.name = "ForgeCategories"
	categories.columns = 2 if extent.x < 480 else 4
	categories.add_theme_constant_override("h_separation", 6)
	categories.add_theme_constant_override("v_separation", 4)
	add_child(categories)
	for entry in CATEGORIES:
		var button := _button(str(entry[0]), str(entry[1]) == str(draft.category), 30 if compact else 38)
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.name = "ForgeCategory_" + str(entry[1])
		button.pressed.connect(_filter.bind("category", str(entry[1])))
		categories.add_child(button)
	sections = HBoxContainer.new()
	sections.name = "ForgeSections"
	sections.visible = narrow
	add_child(sections)
	for index in 3:
		var button := _button(["FILTROS", "RECEITAS", "DETALHES"][index], false, 30)
		button.action_font_size = 11
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.pressed.connect(_section.bind(index))
		sections.add_child(button)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	add_child(body)
	sidebar = _frame(body, "ForgeSidebar", 8)
	sidebar.custom_minimum_size.x = 0 if narrow else 148
	sidebar.size_flags_horizontal = SIZE_EXPAND_FILL if narrow else SIZE_FILL
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 6)
	sidebar.add_child(side)
	filters = GridContainer.new()
	filters.name = "ForgeFilters"
	filters.columns = (3 if extent.x >= 560 else 2) if narrow else 1
	filters.add_theme_constant_override("h_separation", 8)
	filters.add_theme_constant_override("v_separation", 6)
	side.add_child(filters)
	class_picker = _picker("ForgeClass", "PERSONAGEM", [["Todos", "all"]])
	for id in ContentCatalog.CLASS_ORDER:
		class_picker.add_item(ContentCatalog.classes[id].display_name)
		class_picker.set_item_metadata(class_picker.item_count - 1, str(id))
	_set_picker(class_picker, str(draft.class))
	class_picker.item_selected.connect(func(index: int) -> void: _filter("class", str(class_picker.get_item_metadata(index))))
	slot_picker = _picker("ForgeSlot", "ESPAÇO", SLOTS)
	_set_picker(slot_picker, str(draft.slot))
	slot_picker.item_selected.connect(func(index: int) -> void: _filter("slot", str(slot_picker.get_item_metadata(index))))
	rarity_picker = _picker("ForgeRarity", "RARIDADE", [["Todas", "all"]])
	for id in ItemTiers.ORDER:
		rarity_picker.add_item(ItemTiers.label(id))
		rarity_picker.set_item_metadata(rarity_picker.item_count - 1, id)
	_set_picker(rarity_picker, str(draft.rarity))
	rarity_picker.item_selected.connect(func(index: int) -> void: _filter("rarity", str(rarity_picker.get_item_metadata(index))))
	weapon_picker = _picker("ForgeWeapon", "TIPO DE ARMA", WEAPONS)
	weapon_picker.get_parent().visible = narrow
	_set_picker(weapon_picker, str(draft.weapon))
	weapon_picker.item_selected.connect(func(index: int) -> void: _filter("weapon", str(weapon_picker.get_item_metadata(index))))
	possible = CheckBox.new()
	possible.name = "ForgePossible"
	possible.text = "Só possíveis"
	possible.add_theme_font_size_override("font_size", 11)
	possible.custom_minimum_size.y = 30
	possible.button_pressed = bool(draft.possible)
	possible.tooltip_text = "Receitas com ingredientes, saldo, classe e dificuldade disponíveis."
	possible.toggled.connect(func(value: bool) -> void: _filter("possible", value))
	filters.add_child(possible)
	subtypes = VBoxContainer.new()
	subtypes.name = "ForgeSubtypes"
	subtypes.visible = not narrow
	subtypes.add_theme_constant_override("separation", 4)
	side.add_child(subtypes)
	recipe_frame = _frame(body, "ForgeRecipeFrame", 7)
	recipe_frame.size_flags_stretch_ratio = 0.65
	var recipes := VBoxContainer.new()
	recipes.add_theme_constant_override("separation", 4 if compact else 7)
	recipe_frame.add_child(recipes)
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 8)
	recipes.add_child(tools)
	search = LineEdit.new()
	search.name = "ForgeSearch"
	search.placeholder_text = "Buscar item, família ou região..."
	search.text = str(draft.query)
	search.custom_minimum_size.y = 30 if compact else 36
	search.size_flags_horizontal = SIZE_EXPAND_FILL
	search.add_theme_font_size_override("font_size", 11)
	search.text_changed.connect(func(value: String) -> void: _filter("query", value))
	tools.add_child(search)
	order_picker = OptionButton.new()
	order_picker.name = "ForgeOrder"
	order_picker.fit_to_longest_item = false
	order_picker.custom_minimum_size = Vector2(100 if narrow else 136, 30)
	order_picker.add_theme_font_size_override("font_size", 11)
	for entry in [["Mais poderosos", "power"], ["Menor custo", "cost"], ["Nome", "name"]]:
		order_picker.add_item(str(entry[0]))
		order_picker.set_item_metadata(order_picker.item_count - 1, entry[1])
	_set_picker(order_picker, str(draft.order))
	order_picker.item_selected.connect(func(index: int) -> void: _filter("order", str(order_picker.get_item_metadata(index))))
	tools.add_child(order_picker)
	count_label = _label("", 10 if compact else 11, ART.GOLD)
	recipes.add_child(count_label)
	list = VBoxContainer.new()
	list.name = "ForgeRecipes"
	list.add_theme_constant_override("separation", 5 if compact else 7)
	recipes.add_child(list)
	var pages := HBoxContainer.new()
	pages.alignment = BoxContainer.ALIGNMENT_CENTER
	pages.add_theme_constant_override("separation", 10)
	recipes.add_child(pages)
	previous = _button("←", false, 30)
	previous.name = "ForgePreviousPage"
	previous.pressed.connect(_page.bind(-1))
	pages.add_child(previous)
	page_label = _label("", 12, ART.GOLD)
	page_label.custom_minimum_size.x = 65
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.size_flags_vertical = SIZE_SHRINK_CENTER
	pages.add_child(page_label)
	next = _button("→", false, 30)
	next.name = "ForgeNextPage"
	next.pressed.connect(_page.bind(1))
	pages.add_child(next)
	detail_frame = _frame(body, "ForgeDetails", 8)
	detail_frame.size_flags_stretch_ratio = 0.35
	details = VBoxContainer.new()
	details.add_theme_constant_override("separation", 3 if compact else 6)
	detail_frame.add_child(details)
	notice = _label("Itens raros exigem recursos especiais. Explore para encontrar os ingredientes necessários.", 11, ART.MUTED)
	notice.visible = not compact
	add_child(notice)
	_refresh()

func _header() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	var back := _button("←  VOLTAR", false, 32 if compact else 42)
	back.name = "ForgeBack"
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
	var title := _label("FORJA", 23 if compact else 34, ART.GOLD, true)
	title.name = "ForgeTitle"
	_single_line(title)
	titles.add_child(title)
	var subtitle := _label("Transforme os recursos da sua jornada em equipamentos poderosos.", 13, ART.TEXT)
	subtitle.visible = not compact
	titles.add_child(subtitle)
	if not compact: add_child(RECORDS.Rule.new())
	currencies = HFlowContainer.new()
	currencies.add_theme_constant_override("h_separation", 20)
	currencies.add_theme_constant_override("v_separation", 2)
	add_child(currencies)

func _picker(node_name: String, title: String, entries: Array) -> OptionButton:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2)
	filters.add_child(box)
	var caption := _label(title, 10, ART.MUTED)
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	box.add_child(caption)
	var picker := OptionButton.new()
	picker.name = node_name
	picker.fit_to_longest_item = false
	picker.clip_text = true
	picker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	picker.custom_minimum_size.y = 30 if compact else 32
	picker.size_flags_horizontal = SIZE_EXPAND_FILL
	picker.add_theme_font_size_override("font_size", 11)
	for entry in entries:
		picker.add_item(str(entry[0]))
		picker.set_item_metadata(picker.item_count - 1, entry[1])
	box.add_child(picker)
	return picker

func _set_picker(picker: OptionButton, value: String) -> void:
	for index in picker.item_count:
		if str(picker.get_item_metadata(index)) == value: picker.select(index)

func _filter(key: String, value: Variant) -> void:
	draft[key] = value
	draft.page = 0
	if key == "category":
		draft.slot = "all"
		draft.weapon = "all"
		_set_picker(slot_picker, "all")
		_set_picker(weapon_picker, "all")
	if key == "slot": _set_picker(slot_picker, str(value))
	_refresh()

func _refresh(keep_selection: bool = false) -> void:
	matched_recipes.clear()
	for recipe in ContentCatalog.forge_recipes:
		var item: EquipmentData = ContentCatalog.equipment.get(str(recipe.result))
		if item == null: continue
		if str(draft.class) != "all" and item.class_id != &"" and str(item.class_id) != str(draft.class): continue
		if str(draft.slot) != "all" and str(item.slot) != str(draft.slot): continue
		if str(draft.rarity) != "all" and str(item.rarity) != str(draft.rarity): continue
		if str(draft.category) == "weapons" and item.slot != &"weapon": continue
		if str(draft.category) == "armor" and str(item.slot) not in ["helmet", "armor", "boots"]: continue
		if str(draft.category) == "accessories" and str(item.slot) not in ["ring", "amulet"]: continue
		if str(draft.weapon) != "all" and (item.slot != &"weapon" or str(ICON.WEAPONS.get(str(item.class_id), "sword")) != str(draft.weapon)): continue
		var haystack := item.display_name + " " + str(item.family_id) + " " + str(item.region_id)
		if ContentCatalog.maps.has(str(item.region_id)): haystack += " " + str(ContentCatalog.maps[str(item.region_id)].display_name)
		if not str(draft.query).is_empty() and not haystack.to_lower().contains(str(draft.query).strip_edges().to_lower()): continue
		if bool(draft.possible) and not SaveManager.can_forge(str(recipe.id)): continue
		matched_recipes.append(recipe)
	matched_recipes.sort_custom(_less)
	if not keep_selection and not matched_recipes.any(func(recipe: Dictionary) -> bool: return str(recipe.id) == str(draft.selected)):
		draft.selected = str(matched_recipes[0].id) if not matched_recipes.is_empty() else ""
	_refresh_header()
	_refresh_subtypes()
	_render()
	_render_details()
	_section(int(draft.section))

func _less(a: Dictionary, b: Dictionary) -> bool:
	var left: EquipmentData = ContentCatalog.equipment[str(a.result)]
	var right: EquipmentData = ContentCatalog.equipment[str(b.result)]
	match str(draft.order):
		"name":
			if left.display_name != right.display_name: return left.display_name.naturalnocasecmp_to(right.display_name) < 0
		"cost":
			if int(a.gold_cost) != int(b.gold_cost): return int(a.gold_cost) < int(b.gold_cost)
			if int(a.crystal_cost) != int(b.crystal_cost): return int(a.crystal_cost) < int(b.crystal_cost)
		_:
			if not is_equal_approx(left.power_score(), right.power_score()): return left.power_score() > right.power_score()
	return str(a.id) < str(b.id)

func _refresh_header() -> void:
	_clear(currencies)
	var copies := 0
	for id in SaveManager.data.equipment: copies += SaveManager.equipment_quantity(str(id))
	for text in ["OURO  %d" % int(SaveManager.data.gold), "CRISTAIS  %d" % int(SaveManager.data.crystals), "ITENS  %d" % copies]:
		var label := _label(text, 11 if compact else 12, ART.GOLD)
		label.name = "ForgeCurrency" + str(currencies.get_child_count())
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		currencies.add_child(label)
	for index in categories.get_child_count():
		var button: Button = categories.get_child(index)
		ART.apply_button(button, str(CATEGORIES[index][1]) == str(draft.category), button.get_theme_font("font"))
		button.add_theme_font_size_override("font_size", 11 if compact else 12)

func _refresh_subtypes() -> void:
	_clear(subtypes)
	if narrow: return
	var entries: Array = WEAPONS if str(draft.category) == "weapons" else SLOTS
	for entry in entries:
		if str(draft.category) == "armor" and str(entry[1]) not in ["all", "helmet", "armor", "boots"]: continue
		if str(draft.category) == "accessories" and str(entry[1]) not in ["all", "ring", "amulet"]: continue
		var key := "weapon" if str(draft.category) == "weapons" else "slot"
		var button := _button(str(entry[0]), str(draft[key]) == str(entry[1]), 30)
		button.name = "ForgeSubtype_" + str(entry[1])
		button.action_font_size = 11
		button.pressed.connect(_filter.bind(key, entry[1]))
		subtypes.add_child(button)

func _page(direction: int) -> void:
	draft.page = int(draft.page) + direction
	_render()

func _render() -> void:
	if list == null: return
	_clear(list)
	var pages := maxi(1, ceili(float(matched_recipes.size()) / page_size))
	draft.page = clampi(int(draft.page), 0, pages - 1)
	for index in range(int(draft.page) * page_size, mini(matched_recipes.size(), (int(draft.page) + 1) * page_size)):
		_card(matched_recipes[index])
	count_label.text = "%d receitas · %d por página" % [matched_recipes.size(), page_size]
	page_label.text = "%d / %d" % [int(draft.page) + 1, pages]
	previous.disabled = int(draft.page) == 0
	next.disabled = int(draft.page) >= pages - 1
	if matched_recipes.is_empty(): list.add_child(_label("Nenhuma receita neste filtro. Altere a categoria, classe, raridade ou busca.", 12, ART.MUTED))

func _card(recipe: Dictionary) -> void:
	var item: EquipmentData = ContentCatalog.equipment[str(recipe.result)]
	var color: Color = ART.RARITY_COLORS.get(str(item.rarity), ART.GOLD)
	var card := CABINET.RelicFrame.new()
	card.name = "ForgeRecipe"
	card.set_meta("recipe_id", str(recipe.id))
	card.accent = color
	card.selected = str(draft.selected) == str(recipe.id)
	var style := ART.panel(Color("#061310", 0.96).lerp(Color(color.darkened(0.87), 0.98), 0.5), 6)
	style.border_color = color if card.selected else Color(color, 0.5)
	style.set_border_width_all(2 if card.selected else 1)
	card.add_theme_stylebox_override("panel", style)
	list.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var pick := Button.new()
	pick.name = "InspectRecipe_" + str(recipe.id)
	pick.custom_minimum_size = Vector2(42 if compact else 52, 42 if compact else 52)
	pick.tooltip_text = _tooltip(item)
	for state in ["normal", "hover", "pressed"]: pick.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	pick.pressed.connect(_select_recipe.bind(str(recipe.id), true))
	row.add_child(pick)
	var icon := _icon(item, 42 if compact else 52)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pick.add_child(icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 2)
	copy.size_flags_vertical = SIZE_SHRINK_CENTER
	copy.mouse_filter = MOUSE_FILTER_STOP
	copy.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	copy.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed: _select_recipe(str(recipe.id), true))
	row.add_child(copy)
	var title := _label(item.display_name, 13 if compact else 16, ART.TEXT, true)
	_single_line(title)
	title.tooltip_text = _tooltip(item)
	title.mouse_filter = MOUSE_FILTER_PASS
	copy.add_child(title)
	var owner := _label(ItemTiers.label(str(item.rarity)) + " · " + _owner(item), 10 if compact else 11, color)
	_single_line(owner)
	copy.add_child(owner)
	if not compact:
		var power := _label("Poder %d · %s" % [roundi(item.power_score()), STATS.describe({str(item.stat): item.stat_amount})], 11, ART.TEXT)
		_single_line(power)
		copy.add_child(power)
	var actions := VBoxContainer.new()
	actions.size_flags_vertical = SIZE_SHRINK_CENTER
	actions.add_theme_constant_override("separation", 2)
	row.add_child(actions)
	var price := _label("%d ouro · %d cristais" % [recipe.gold_cost, recipe.crystal_cost], 10, ART.GOLD)
	price.autowrap_mode = TextServer.AUTOWRAP_OFF
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actions.add_child(price)
	var action := _button("Forjar", SaveManager.can_forge(str(recipe.id)), 30 if compact else 32)
	action.name = "ForgeItemAction"
	action.set_meta("recipe_id", str(recipe.id))
	action.disabled = not SaveManager.can_forge(str(recipe.id))
	action.tooltip_text = _requirements(recipe)
	action.pressed.connect(_forge.bind(str(recipe.id)))
	actions.add_child(action)

func _select_recipe(id: String, show_details: bool = false) -> void:
	if ContentCatalog.get_forge_recipe(id).is_empty(): return
	draft.selected = id
	_render()
	_render_details()
	if narrow and show_details: _section(2)

func _render_details() -> void:
	_clear(details)
	var recipe: Dictionary = ContentCatalog.get_forge_recipe(str(draft.selected))
	if recipe.is_empty():
		details.add_child(_label("Escolha uma receita para conferir o equipamento e os materiais necessários.", 13, ART.MUTED))
		return
	var item: EquipmentData = ContentCatalog.equipment[str(recipe.result)]
	var color: Color = ART.RARITY_COLORS.get(str(item.rarity), ART.GOLD)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 10)
	details.add_child(heading)
	heading.add_child(_icon(item, 48 if compact else 82))
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 2)
	heading.add_child(titles)
	var title := _label(item.display_name, 17 if compact else 22, ART.TEXT, true)
	title.name = "ForgeSelectedTitle"
	title.max_lines_visible = 2
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.tooltip_text = _tooltip(item)
	title.mouse_filter = MOUSE_FILTER_PASS
	titles.add_child(title)
	var rarity := _label(ItemTiers.label(str(item.rarity)).to_upper() + " · " + _owner(item), 10 if compact else 11, color)
	rarity.max_lines_visible = 2
	titles.add_child(rarity)
	var stat_frame := _frame(details, "ForgeResultStats", 5)
	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 2)
	stat_frame.add_child(stats)
	var values := item.bonuses.duplicate()
	values[str(item.stat)] = float(values.get(str(item.stat), 0)) + item.stat_amount
	if compact:
		var summary := _label(STATS.describe(values), 11, ART.TEXT)
		summary.max_lines_visible = 3
		summary.tooltip_text = _tooltip(item)
		summary.mouse_filter = MOUSE_FILTER_PASS
		stats.add_child(summary)
	else:
		for key in values: stats.add_child(_label(STATS.describe({key: values[key]}), 12, ART.TEXT))
	if not compact: details.add_child(RECORDS.Rule.new())
	details.add_child(_label("MATERIAIS NECESSÁRIOS", 10 if compact else 12, ART.GOLD, true))
	var ingredients := HBoxContainer.new()
	ingredients.name = "ForgeIngredients"
	ingredients.add_theme_constant_override("separation", 6)
	details.add_child(ingredients)
	for ingredient in recipe.get("ingredients", []):
		var required := int(ingredient.get("qty", 1))
		var owned: int = SaveManager.equipment_quantity(str(ingredient.id))
		var source: EquipmentData = ContentCatalog.equipment.get(str(ingredient.id))
		var box := VBoxContainer.new()
		box.name = "ForgeIngredient_" + str(ingredient.id)
		box.size_flags_horizontal = SIZE_EXPAND_FILL
		box.add_theme_constant_override("separation", 1)
		ingredients.add_child(box)
		if source != null and not compact: box.add_child(_icon(source, 30))
		var count := _label("%d / %d" % [owned, required], 11 if compact else 13, ART.GREEN if owned >= required else Color("#ffa494"))
		count.name = "IngredientQuantity"
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(count)
		var name_label := _label(str(ingredient.get("name", ingredient.id)), 10, ART.MUTED)
		name_label.max_lines_visible = 1 if compact else 2
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.tooltip_text = str(ingredient.get("name", ingredient.id)) + "\n%d disponíveis; %d necessários." % [owned, required]
		name_label.mouse_filter = MOUSE_FILTER_PASS
		box.add_child(name_label)
	var status := _label(_requirements(recipe), 10 if compact else 11, ART.GREEN if SaveManager.can_forge(str(recipe.id)) else Color("#f0c1a1"))
	status.name = "ForgeRequirements"
	status.max_lines_visible = 2
	status.tooltip_text = _requirements(recipe)
	status.mouse_filter = MOUSE_FILTER_PASS
	details.add_child(status)
	var space := Control.new()
	space.size_flags_vertical = SIZE_EXPAND_FILL
	details.add_child(space)
	var cost := _label("Custo: %d ouro + %d cristais" % [recipe.gold_cost, recipe.crystal_cost], 11 if compact else 13, ART.GOLD)
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.add_child(cost)
	var action := _button("FORJAR", true, 30 if compact else 38)
	action.name = "ForgeSelectedAction"
	action.disabled = not SaveManager.can_forge(str(recipe.id))
	action.pressed.connect(_forge.bind(str(recipe.id)))
	details.add_child(action)

func _requirements(recipe: Dictionary) -> String:
	var item: EquipmentData = ContentCatalog.equipment[str(recipe.result)]
	var missing := PackedStringArray()
	if item.generated:
		if not SaveManager.is_class_unlocked(str(item.class_id)): missing.append("Recrute " + _owner(item))
		if item.required_difficulty > int(SaveManager.data.highest_difficulty): missing.append("Dificuldade " + CampaignRules.difficulty_name(item.required_difficulty))
		elif not SaveManager.phase_unlocked(str(item.region_id), 1, item.required_difficulty): missing.append("Desbloqueie a região de origem")
		if SaveManager.data.equipment.has(str(item.id)) or int(SaveManager.data.forge_upgrades.get(str(recipe.id), 0)) > 0: missing.append("Equipamento já criado")
	for ingredient in recipe.get("ingredients", []):
		var have: int = SaveManager.equipment_quantity(str(ingredient.id))
		var need := int(ingredient.get("qty", 1))
		if have < need: missing.append("Falta: %s (%d/%d)" % [ingredient.get("name", ingredient.id), have, need])
	if int(SaveManager.data.gold) < int(recipe.gold_cost): missing.append("Ouro insuficiente")
	if int(SaveManager.data.crystals) < int(recipe.crystal_cost): missing.append("Cristais insuficientes")
	return "Pronto para forjar. Ingredientes não iniciais serão consumidos." if missing.is_empty() else " · ".join(missing)

func _forge(id: String) -> void:
	if not SaveManager.forge_item(id):
		_render_details()
		return
	AudioManager.feedback("talent")
	draft.selected = id
	_refresh(true)
	var recipe: Dictionary = ContentCatalog.get_forge_recipe(id)
	notice.text = str(recipe.get("result_name", "Equipamento")) + " criado e adicionado ao Arsenal."

func _section(index: int) -> void:
	draft.section = clampi(index, 0, 2)
	sidebar.visible = not narrow or index == 0
	recipe_frame.visible = not narrow or index == 1
	detail_frame.visible = not narrow or index == 2
	for child_index in sections.get_child_count(): sections.get_child(child_index).modulate = Color.WHITE if child_index == index else Color("#a1aaa2")

func _owner(item: EquipmentData) -> String:
	return str(ContentCatalog.classes[str(item.class_id)].display_name) if ContentCatalog.classes.has(str(item.class_id)) else "Compartilhado"

func _tooltip(item: EquipmentData) -> String:
	return item.display_name + "\n" + ItemTiers.label(str(item.rarity)) + " · " + _owner(item) + "\n" + item.description + "\nPoder: " + str(roundi(item.power_score()))

func _icon(item: EquipmentData, pixels: float) -> TextureRect:
	var icon := TextureRect.new()
	var key := str(ICON.WEAPONS.get(str(item.class_id), "sword")) if item.slot == &"weapon" else str(item.slot)
	icon.texture = ICON.TEXTURES.get(key, ICON.TEXTURES.amulet)
	icon.custom_minimum_size = Vector2(pixels, pixels)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = MOUSE_FILTER_IGNORE
	return icon

func _frame(parent: Node, node_name: String, margin: float) -> PanelContainer:
	var frame := CABINET.RelicFrame.new()
	frame.name = node_name
	frame.size_flags_horizontal = SIZE_EXPAND_FILL
	var style := ART.panel(Color("#061310", 0.96), margin)
	style.border_color = Color(ART.GOLD, 0.65)
	frame.add_theme_stylebox_override("panel", style)
	parent.add_child(frame)
	return frame

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

func _button(text: String, primary: bool = false, height: float = 32) -> Button:
	var button := HOME.OrnateAction.new()
	button.text = text
	button.primary = primary
	button.action_font_size = 11 if compact else 12
	button.custom_minimum_size.y = height
	return button

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
