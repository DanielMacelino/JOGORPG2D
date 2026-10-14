extends CanvasLayer

func _ready() -> void:
	# Configurar a cor de fundo apenas para destacar a UI
	var bg := ColorRect.new()
	bg.color = Color("#222222")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var golden_theme = GoldenUI.new()
	
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.add_theme_constant_override("separation", 24)
	add_child(vbox)
	
	# Exemplo 1: Painel (NinePatchRect)
	var panel = golden_theme.create_panel(Vector2(400, 200))
	vbox.add_child(panel)
	
	var panel_vbox = VBoxContainer.new()
	panel_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel_vbox.add_theme_constant_override("separation", 16)
	panel.add_child(panel_vbox)
	
	var label = Label.new()
	label.text = "Exemplo de Golden UI"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#f0d899"))
	panel_vbox.add_child(label)
	
	# Exemplo 2: Barra de Vida (TextureProgressBar)
	var health_bar = golden_theme.create_health_bar()
	health_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel_vbox.add_child(health_bar)
	
	# Exemplo 3: Botões (TextureButton)
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	panel_vbox.add_child(row)
	
	var btn_play = golden_theme.create_button("JOGAR")
	row.add_child(btn_play)
	
	var btn_quit = golden_theme.create_button("SAIR")
	row.add_child(btn_quit)
	
	# Exemplo 4: Grid de Slots de Inventário
	var slot_grid = GridContainer.new()
	slot_grid.columns = 4
	slot_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(slot_grid)
	
	for i in range(8):
		var slot = golden_theme.create_inventory_slot()
		slot_grid.add_child(slot)
		
		# Adicionando um ícone em alguns slots
		if i % 3 == 0:
			var icon = golden_theme.create_icon(i)
			icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
			slot.add_child(icon)
