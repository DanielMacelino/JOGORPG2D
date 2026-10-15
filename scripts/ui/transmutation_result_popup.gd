extends CanvasLayer
signal dismiss_requested
const ART := preload("res://scripts/ui/wild_theme.gd")
const ICON := preload("res://scripts/ui/equipment_icon.gd")
var result: Dictionary = {}
var error_label: Label
var fit: Control

func _ready() -> void:
	name = "FusionResultPopup"
	layer = 60
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.005, 0.02, 0.015, 0.82)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	fit = preload("res://scripts/ui/result_viewport.gd").new()
	fit.name = "FusionPopupViewport"
	fit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fit.preferred_width = 700.0
	fit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.name = "FusionResult"
	var style := ART.panel(Color("#091e16"), 16)
	style.border_color = ART.GREEN if bool(result.success) else ART.GOLD
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	fit.content = panel
	add_child(fit)
	fit.modulate.a = 0.0
	create_tween().tween_property(fit, "modulate:a", 1.0, 0.24)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var wager := str(result.get("kind", "fusion")) == "wager"
	if wager:
		column.add_child(_label("PRÊMIO CONQUISTADO" if bool(result.success) else "APOSTA NÃO VENCEU", 23, ART.GREEN if bool(result.success) else ART.GOLD))
		column.add_child(_label("Os sacrifícios se transformaram no equipamento que você escolheu." if bool(result.success) else "Os itens oferecidos foram consumidos. Você recebeu a consolação indicada antes da aposta.", 13, ART.TEXT))
		if bool(result.success): _item(column, str(result.result_id), "ITEM RECEBIDO")
		else:
			var parts: Array[String] = []
			var consolation: Dictionary = result.get("consolation", {})
			if int(consolation.get("gold", 0)) > 0: parts.append("%d OURO" % consolation.gold)
			if int(consolation.get("crystals", 0)) > 0: parts.append("%d CRISTAL(IS)" % consolation.crystals)
			column.add_child(_label("CONSOLAÇÃO · " + " + ".join(parts), 19, ART.GOLD))
			column.add_child(_label("O prêmio desejado não foi obtido. A consolação já foi salva.", 12, ART.MUTED))
	else:
		column.add_child(_label("RARIDADE ELEVADA" if bool(result.success) else "RARIDADE MANTIDA", 23, ART.GREEN if bool(result.success) else ART.GOLD))
		column.add_child(_label("A fusão melhorou a raridade do equipamento." if bool(result.success) else "A raridade não subiu. Você recebeu um item da mesma raridade e avançou seu marco.", 13, ART.TEXT))
		_item(column, str(result.result_id), "ITEM RECEBIDO")
	if not str(result.bonus_id).is_empty():
		_item(column, str(result.bonus_id), "MARCO ATINGIDO · ITEM EXTRA")
	column.add_child(_label("O resultado já foi salvo." if wager else "Os equipamentos já foram salvos no inventário.", 12, ART.MUTED))
	error_label = _label("", 12, Color("#ffb5a8"))
	error_label.hide()
	column.add_child(error_label)
	var close := Button.new()
	close.name = "FusionContinue"
	close.text = "CONTINUAR"
	close.custom_minimum_size.y = 44
	ART.apply_button(close, true)
	close.pressed.connect(func() -> void: dismiss_requested.emit())
	column.add_child(close)
	close.call_deferred("grab_focus")
	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.22)

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", roundi(font_size * clampf(float(SaveManager.data.settings.ui_scale), 0.85, 1.2)))
	label.add_theme_color_override("font_color", color)
	return label

func _item(parent: Node, id: String, heading: String) -> void:
	var item: EquipmentData = ContentCatalog.equipment[id]
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	parent.add_child(box)
	box.add_child(_label(heading, 11, ART.GOLD))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var icon := ICON.new()
	icon.item = item
	icon.framed = true
	icon.custom_minimum_size = Vector2(56, 64)
	row.add_child(icon)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 4)
	row.add_child(details)
	details.add_child(_label(item.display_name, 16, ART.RARITY_COLORS[str(item.rarity)]))
	details.add_child(_label("%s · PODER %.1f" % [ItemTiers.label(str(item.rarity)).to_upper(), item.power_score()], 12, ART.GOLD))
	details.add_child(_label(item.description, 13, ART.TEXT))
	if item.region_id != &"" and ContentCatalog.maps.has(str(item.region_id)):
		details.add_child(_label("Origem: " + ContentCatalog.maps[str(item.region_id)].display_name, 11, ART.MUTED))

func show_error(text: String) -> void:
	error_label.text = text
	error_label.show()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		dismiss_requested.emit()
