extends VBoxContainer
signal back_requested
signal interface_changed
const ART := preload("res://scripts/ui/wild_theme.gd")
func _ready() -> void:
	name = "PauseSettings"
	process_mode = PROCESS_MODE_ALWAYS
	add_theme_constant_override("separation", 7)
	var title := Label.new()
	title.text = "CONFIGURAÇÕES"
	title.add_theme_font_override("font", ART.title_font())
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", ART.GOLD)
	add_child(title)
	for entry in [["Volume geral", "master", 0.0, 1.0], ["Música", "music", 0.0, 1.0], ["Efeitos sonoros", "effects", 0.0, 1.0], ["Tamanho da interface", "ui_scale", 0.85, 1.2]]:
		var key := str(entry[1])
		var row := HBoxContainer.new()
		add_child(row)
		var label := Label.new()
		label.text = str(entry[0])
		label.size_flags_horizontal = SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 12)
		row.add_child(label)
		var value := Label.new()
		value.add_theme_font_size_override("font_size", 12)
		value.text = "%d%%" % roundi(float(SaveManager.data.settings[key]) * 100)
		row.add_child(value)
		var slider := HSlider.new()
		slider.name = "PauseSetting_" + key
		slider.min_value = float(entry[2])
		slider.max_value = float(entry[3])
		slider.step = 0.01
		slider.value = float(SaveManager.data.settings[key])
		slider.custom_minimum_size.y = 18
		slider.value_changed.connect(func(amount: float) -> void:
			SaveManager.data.settings[key] = amount
			SaveManager.save_game()
			AudioManager.apply_settings()
			value.text = "%d%%" % roundi(amount * 100)
			if key == "ui_scale": interface_changed.emit())
		add_child(slider)
	var back := Button.new()
	back.name = "PauseSettingsBack"
	back.text = "VOLTAR À PAUSA"
	back.custom_minimum_size.y = 34
	ART.apply_button(back)
	back.pressed.connect(func() -> void: back_requested.emit())
	add_child(back)
