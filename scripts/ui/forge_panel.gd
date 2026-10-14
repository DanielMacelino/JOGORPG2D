extends VBoxContainer
signal back_requested
const ART := preload("res://scripts/ui/wild_theme.gd")
const HOME := preload("res://scripts/ui/menu/home_screen.gd")
const ICON := preload("res://scripts/ui/equipment_icon.gd")
var draft: Dictionary = {}
var filters: GridContainer
var class_picker: OptionButton
var slot_picker: OptionButton
var rarity_picker: OptionButton
var search: LineEdit
var possible: CheckBox
var list: VBoxContainer
var count_label: Label
var page_label: Label
var previous: Button
var next: Button
var matched_recipes: Array[Dictionary] = []
var page_size := 3
var compact := false

func _ready() -> void:
	name = "ForgePanel"
	size_flags_horizontal = SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 8)
	for pair in [["class", "all"], ["slot", "all"], ["rarity", "all"], ["query", ""], ["possible", false], ["page", 0]]:
		if not draft.has(pair[0]): draft[pair[0]] = pair[1]
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 14)
	add_child(heading)
	var back := HOME.OrnateAction.new()
	back.name = "ForgeBack"
	back.text = "VOLTAR"
	back.custom_minimum_size = Vector2(104, 42)
	back.pressed.connect(func() -> void: back_requested.emit())
	heading.add_child(back)
	var title := _label("FORJA", 26, ART.TEXT)
	title.add_theme_font_override("font", ART.title_font())
	heading.add_child(title)
	var currencies := HFlowContainer.new()
	currencies.add_theme_constant_override("h_separation", 18)
	add_child(currencies)
	for text in ["OURO %d" % int(SaveManager.data.gold), "CRISTAIS %d" % int(SaveManager.data.crystals)]:
		var label := _label(text, 12, ART.GOLD)
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		currencies.add_child(label)
	filters = GridContainer.new()
	filters.name = "ForgeFilters"
	filters.size_flags_horizontal = SIZE_EXPAND_FILL
	filters.add_theme_constant_override("h_separation", 8)
	filters.add_theme_constant_override("v_separation", 6)
	add_child(filters)
	class_picker = _picker("ForgeClass", "CLASSE", [["Todos", "all"]])
	for id in ContentCatalog.CLASS_ORDER:
		class_picker.add_item(ContentCatalog.classes[id].display_name)
		class_picker.set_item_metadata(class_picker.item_count - 1, str(id))
	_set_picker(class_picker, str(draft.class))
	class_picker.item_selected.connect(func(index: int) -> void: _filter("class", str(class_picker.get_item_metadata(index))))
	slot_picker = _picker("ForgeSlot", "ESPAÇO", [["Todos", "all"], ["Armas", "weapon"], ["Elmos", "helmet"], ["Armaduras", "armor"], ["Botas", "boots"], ["Anéis", "ring"], ["Amuletos", "amulet"]])
	_set_picker(slot_picker, str(draft.slot))
	slot_picker.item_selected.connect(func(index: int) -> void: _filter("slot", str(slot_picker.get_item_metadata(index))))
	rarity_picker = _picker("ForgeRarity", "TIER", [["Todos", "all"]])
	for id in ItemTiers.ORDER:
		rarity_picker.add_item(ItemTiers.label(id))
		rarity_picker.set_item_metadata(rarity_picker.item_count - 1, id)
	_set_picker(rarity_picker, str(draft.rarity))
	rarity_picker.item_selected.connect(func(index: int) -> void: _filter("rarity", str(rarity_picker.get_item_metadata(index))))
	possible = CheckBox.new()
	possible.name = "ForgePossible"
	possible.custom_minimum_size.y = 44
	possible.text = "Só possíveis"
	possible.tooltip_text = "Exibir apenas receitas com ingredientes, moedas, classe e dificuldade liberados."
	possible.button_pressed = bool(draft.possible)
	possible.size_flags_vertical = SIZE_SHRINK_END
	possible.toggled.connect(func(value: bool) -> void: _filter("possible", value))
	filters.add_child(possible)
	search = LineEdit.new()
	search.name = "ForgeSearch"
	search.placeholder_text = "Buscar equipamento, família ou região"
	search.text = str(draft.query)
	search.custom_minimum_size.y = 40
	search.text_changed.connect(func(value: String) -> void: _filter("query", value))
	add_child(search)
	count_label = _label("", 11, ART.GOLD)
	add_child(count_label)
	list = VBoxContainer.new()
	list.name = "ForgeRecipes"
	list.size_flags_horizontal = SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	add_child(list)
	var pages := HBoxContainer.new()
	pages.add_theme_constant_override("separation", 10)
	add_child(pages)
	previous = _button("ANTERIOR")
	previous.name = "ForgePreviousPage"
	previous.pressed.connect(_page.bind(-1))
	pages.add_child(previous)
	page_label = _label("", 12, ART.GOLD)
	page_label.size_flags_horizontal = SIZE_EXPAND_FILL
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pages.add_child(page_label)
	next = _button("PRÓXIMA")
	next.name = "ForgeNextPage"
	next.pressed.connect(_page.bind(1))
	pages.add_child(next)
	resized.connect(_layout)
	compact = get_viewport_rect().size.x < 520
	_refresh()
	_layout()

func _picker(node_name: String, title: String, entries: Array) -> OptionButton:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)
	filters.add_child(box)
	box.add_child(_label(title, 10, ART.MUTED))
	var picker := OptionButton.new()
	picker.name = node_name
	picker.fit_to_longest_item = false
	picker.clip_text = true
	picker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	picker.custom_minimum_size.y = 40
	picker.size_flags_horizontal = SIZE_EXPAND_FILL
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
	_refresh()
func _page(direction: int) -> void:
	draft.page = int(draft.page) + direction
	_render()
func _layout() -> void:
	if filters == null: return
	filters.columns = 4 if size.x >= 760 else 2
	var target_page_size := 2 if get_viewport_rect().size.y < 600 or size.x < 380 else 3
	if page_size != target_page_size:
		page_size = target_page_size
		_render()
	var narrow := size.x < 520
	if compact != narrow:
		compact = narrow
		_render()
func _refresh() -> void:
	matched_recipes.clear()
	var owned := {}
	for id in SaveManager.data.equipment: owned[str(id)] = true
	for recipe in ContentCatalog.forge_recipes:
		var item: EquipmentData = ContentCatalog.equipment.get(str(recipe.result))
		if item == null: continue
		if str(draft.class) != "all" and item.class_id != &"" and str(item.class_id) != str(draft.class): continue
		if str(draft.slot) != "all" and str(item.slot) != str(draft.slot): continue
		if str(draft.rarity) != "all" and str(item.rarity) != str(draft.rarity): continue
		if not str(draft.query).is_empty() and not item.display_name.to_lower().contains(str(draft.query).to_lower()): continue
		if bool(draft.possible):
			var has_ingredients := true
			for ingredient in recipe.ingredients:
				if not owned.has(str(ingredient.id)): has_ingredients = false
			if not has_ingredients or not SaveManager.can_forge(str(recipe.id)): continue
		matched_recipes.append(recipe)
	_render()
func _render() -> void:
	if list == null: return
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	var pages := maxi(1, ceili(float(matched_recipes.size()) / page_size))
	draft.page = clampi(int(draft.page), 0, pages - 1)
	for index in range(int(draft.page) * page_size, mini(matched_recipes.size(), (int(draft.page) + 1) * page_size)):
		_card(matched_recipes[index])
	count_label.text = "%d receitas encontradas - %d por página" % [matched_recipes.size(), page_size]
	page_label.text = "%d / %d" % [int(draft.page) + 1, pages]
	previous.disabled = int(draft.page) == 0
	next.disabled = int(draft.page) >= pages - 1
	if matched_recipes.is_empty(): list.add_child(_label("Nenhuma receita neste filtro. Experimente outro tier, classe ou busca.", 14, ART.MUTED))
func _card(recipe: Dictionary) -> void:
	var item: EquipmentData = ContentCatalog.equipment[str(recipe.result)]
	var card := PanelContainer.new()
	card.name = "ForgeRecipe"
	card.set_meta("recipe_id", str(recipe.id))
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	var style := ART.panel(Color("#0a1914"), 10)
	style.border_color = ART.RARITY_COLORS[str(item.rarity)]
	card.add_theme_stylebox_override("panel", style)
	list.add_child(card)
	var layout := BoxContainer.new()
	layout.vertical = compact
	layout.add_theme_constant_override("separation", 8)
	card.add_child(layout)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	heading.size_flags_horizontal = SIZE_EXPAND_FILL
	layout.add_child(heading)
	var icon := TextureRect.new()
	var art_id: String = ICON.WEAPONS.get(str(item.class_id), "sword") if item.slot == &"weapon" else str(item.slot)
	icon.texture = ICON.TEXTURES.get(art_id, ICON.TEXTURES.amulet)
	icon.custom_minimum_size = Vector2(36, 44)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heading.add_child(icon)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 3)
	heading.add_child(copy)
	var title := _label(item.display_name, 13 if compact else 15, ART.TEXT)
	title.max_lines_visible = 2
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.tooltip_text = item.display_name + "\n" + item.description
	copy.add_child(title)
	var owner: String = ContentCatalog.classes[str(item.class_id)].display_name if item.class_id != &"" else "Compartilhado"
	copy.add_child(_label("%s - %s" % [ItemTiers.label(str(item.rarity)), owner], 10, ART.RARITY_COLORS[str(item.rarity)]))
	var requirements := ""
	if item.generated:
		requirements = "Requer o item %s da mesma família." % ItemTiers.label(ItemTiers.ORDER[item.tier_index - 1])
	else:
		for ing in recipe.ingredients: requirements += str(ing.name) + " "
	var req := _label(requirements, 10, ART.MUTED)
	req.max_lines_visible = 2
	req.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	req.tooltip_text = str(recipe.ingredients)
	copy.add_child(req)
	copy.add_child(_label("%d ouro + %d cristais" % [recipe.gold_cost, recipe.crystal_cost], 11, ART.GOLD))
	var action := _button("Forjar", true)
	action.name = "ForgeItemAction"
	action.set_meta("recipe_id", str(recipe.id))
	action.size_flags_horizontal = SIZE_EXPAND_FILL if compact else SIZE_SHRINK_END
	action.size_flags_vertical = SIZE_SHRINK_CENTER
	action.custom_minimum_size.x = 0 if compact else 110
	action.disabled = not SaveManager.can_forge(str(recipe.id))
	action.tooltip_text = item.description
	if item.generated and SaveManager.data.equipment.has(str(item.id)): action.tooltip_text += "\nVocê já possui este equipamento."
	if item.required_difficulty > int(SaveManager.data.highest_difficulty): action.tooltip_text += "\nRequer dificuldade " + CampaignRules.difficulty_name(item.required_difficulty)
	action.pressed.connect(_forge.bind(str(recipe.id)))
	layout.add_child(action)
func _forge(id: String) -> void:
	if SaveManager.forge_item(id):
		AudioManager.feedback("talent")
		_refresh()
func _label(value: String, pixels: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", pixels)
	label.add_theme_color_override("font_color", color)
	return label
func _button(text: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	ART.apply_button(button, primary)
	return button
