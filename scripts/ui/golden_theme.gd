extends Control
class_name GoldenUI

const SHEET_PATH = "res://assets/art/image.png"
var sheet: Texture2D

func _init() -> void:
	sheet = load(SHEET_PATH)

func create_panel(size: Vector2) -> NinePatchRect:
	var panel := NinePatchRect.new()
	panel.texture = sheet
	# Região aproximada do "SLOTS" (painel de fundo) ou "SMALL FRAME"
	# O usuário poderá ajustar isso visualmente no Editor depois.
	panel.region_rect = Rect2(16, 260, 96, 96) 
	panel.patch_margin_left = 12
	panel.patch_margin_right = 12
	panel.patch_margin_top = 12
	panel.patch_margin_bottom = 12
	panel.custom_minimum_size = size
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return panel

func create_button(text: String, size := Vector2(180, 48)) -> TextureButton:
	var btn := TextureButton.new()
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_SCALE
	btn.custom_minimum_size = size
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Usando a região do "BUTTONS" no canto superior direito
	var normal := AtlasTexture.new()
	normal.atlas = sheet
	normal.region = Rect2(630, 25, 140, 32)
	
	var pressed := AtlasTexture.new()
	pressed.atlas = sheet
	pressed.region = Rect2(630, 65, 140, 32) # Botão pressionado / variação marrom
	
	btn.texture_normal = normal
	btn.texture_pressed = pressed
	
	var label := Label.new()
	label.text = text
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#ffffff"))
	label.add_theme_color_override("font_outline_color", Color("#332211"))
	label.add_theme_constant_override("outline_size", 4)
	
	btn.add_child(label)
	return btn

func create_health_bar() -> TextureProgressBar:
	var bar := TextureProgressBar.new()
	bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# "FILL BARS" região central superior
	var bg := AtlasTexture.new()
	bg.atlas = sheet
	bg.region = Rect2(300, 60, 100, 24) # Moldura da barra
	
	var fill := AtlasTexture.new()
	fill.atlas = sheet
	fill.region = Rect2(410, 64, 80, 16) # Preenchimento vermelho/laranja
	
	bar.texture_under = bg
	bar.texture_progress = fill
	bar.value = 75
	bar.texture_progress_offset = Vector2(10, 4) # Ajuste para caber dentro da moldura
	return bar

func create_inventory_slot() -> TextureRect:
	var slot := TextureRect.new()
	slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	var tex := AtlasTexture.new()
	tex.atlas = sheet
	tex.region = Rect2(16, 260, 48, 48) # Região de um slot individual
	
	slot.texture = tex
	return slot

func create_icon(icon_index: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	var tex := AtlasTexture.new()
	tex.atlas = sheet
	# Região de "ROUND BUTTONS AND THEIR ICONS" ou ícones soltos
	tex.region = Rect2(20 + (icon_index * 16), 120, 16, 16)
	
	icon.texture = tex
	return icon
