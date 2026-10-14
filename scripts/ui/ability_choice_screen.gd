extends Control
signal selected(id: StringName)
const ART := preload("res://scripts/ui/wild_theme.gd")
const CARD := preload("res://scripts/ui/level_choice_card.gd")
var choices: Array = []
var ranks: Dictionary = {}
var reward_text := ""
var online := false
var grid: GridContainer
var title: Label
var subtitle: Label
var margin: MarginContainer
var header_margin: MarginContainer
var reward_label: Label
var stack: VBoxContainer

func _ready() -> void:
	name = "AbilityChoiceScreen"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 16)
	add_child(margin)
	stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	margin.add_child(stack)
	header_margin = MarginContainer.new()
	stack.add_child(header_margin)
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	header_margin.add_child(header)
	title = _label("A CENTELHA CRESCE", 36, ART.GOLD)
	title.add_theme_font_override("font", ART.title_font())
	header.add_child(title)
	var powers := 0
	for id in ranks:
		var ability: AbilityData = ContentCatalog.abilities.get(str(id))
		if ability != null and ability.active_power and int(ranks[id]) > 0:
			powers += 1
	var hint := "Evolua seu trio ou escolha um passivo." if powers >= 3 else "Escolha até 3 poderes; passivos livres."
	subtitle = _label("PODERES %d/3 · %s%s" % [powers, hint, " Grupo em pausa." if online else ""], 12, ART.MUTED)
	header.add_child(subtitle)
	header.add_child(ChoiceRule.new())
	if not reward_text.is_empty():
		reward_label = _label(reward_text, 14, ART.GOLD)
		header.add_child(reward_label)
	grid = GridContainer.new()
	grid.name = "AbilityChoices"
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = SIZE_EXPAND_FILL
	grid.size_flags_vertical = SIZE_EXPAND_FILL
	stack.add_child(grid)
	for id in choices:
		if maxi(int(ranks.get(StringName(id), 0)), int(ranks.get(str(id), 0))) >= 5:
			continue
		var card := CARD.new()
		card.fit_to_slot = true
		card.configure(ContentCatalog.abilities[str(id)], maxi(int(ranks.get(StringName(id), 0)), int(ranks.get(str(id), 0))))
		card.size_flags_vertical = SIZE_EXPAND_FILL
		card.size_flags_horizontal = SIZE_EXPAND_FILL
		card.pressed.connect(func() -> void: selected.emit(StringName(id)))
		grid.add_child(card)
	if grid.get_child_count() == 0:
		var close := Button.new()
		close.text = "CONTINUAR"
		ART.apply_button(close, true)
		close.pressed.connect(func() -> void: selected.emit(&""))
		grid.add_child(close)
	resized.connect(_adapt)
	call_deferred("_adapt")

func _adapt() -> void:
	if grid == null:
		return
	grid.columns = 3 if size.x >= 760 else 1
	var compact := size.y < 550
	var narrow := size.x < 520
	var wide := size.x >= 1100 and size.y >= 650
	stack.add_theme_constant_override("separation", 24 if wide else 8)
	grid.size_flags_vertical = SIZE_SHRINK_BEGIN if wide else SIZE_EXPAND_FILL
	grid.custom_minimum_size.y = floorf(size.y * 0.65) if wide else 0
	title.add_theme_font_size_override("font_size", 18 if compact else (20 if narrow else (36 if wide else 24)))
	subtitle.add_theme_font_size_override("font_size", 11 if compact or narrow else 12)
	if reward_label != null: reward_label.add_theme_font_size_override("font_size", 11 if compact or narrow else 14)
	header_margin.add_theme_constant_override("margin_left", 250 if wide else 0)
	header_margin.add_theme_constant_override("margin_right", 180 if wide else 0)
	header_margin.add_theme_constant_override("margin_top", 20 if wide else 0)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 10 if compact else (24 if wide else 16))
	margin.add_theme_constant_override("margin_top", 12 if wide else (80 if narrow or (compact and size.x < 820) else 102))

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

class ChoiceRule extends Control:
	func _ready() -> void:
		custom_minimum_size.y = 7
		mouse_filter = MOUSE_FILTER_IGNORE
	func _draw() -> void:
		draw_line(Vector2(0, 3), Vector2(size.x, 3), Color(ART.GOLD, 0.40), 1, true)
		var middle := size.x * 0.5
		draw_polyline(PackedVector2Array([Vector2(middle, 0), Vector2(middle + 4, 3), Vector2(middle, 6), Vector2(middle - 4, 3), Vector2(middle, 0)]), ART.GOLD, 1, true)
