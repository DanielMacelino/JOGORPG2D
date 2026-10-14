extends RefCounted
## Shared art direction: pine, weathered ivory and copper.
const INK := Color("#111d1c")
const SURFACE := Color("#192724")
const LINE := Color("#566b5c")
const TEXT := Color("#fff2de")
const MUTED := Color("#c2cdbb")
const GOLD := Color("#c6aa72")
const GREEN := Color("#72e8a3")
const RARITY_COLORS := {"common": Color("#e1e8df"), "uncommon": GREEN, "rare": Color("#72cfff"), "epic": Color("#da9aff"), "legendary": Color("#ffd16e"), "demigod": Color("#ff9bd4"), "divine": Color("#fff4b8")}

static func body_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Segoe UI", "Noto Sans", "DejaVu Sans"])
	return font

static func title_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Georgia", "Noto Serif", "DejaVu Serif"])
	return font

static func panel(fill: Color = SURFACE, margin: float = 12.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = LINE
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style

static func apply_button(button: Button, primary: bool = false, custom_font: Font = null) -> void:
	var normal := panel(GOLD if primary else SURFACE, 14)
	normal.border_color = GOLD if primary else LINE
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#d8be89") if primary else Color("#25382e")
	hover.border_color = Color("#d8be89") if primary else Color("#718568")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#aa915f") if primary else Color("#10201b")
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("#18231f")
	disabled.border_color = Color("#2b3932")
	var focus := panel(Color(0, 0, 0, 0), 0)
	focus.border_color = TEXT
	focus.set_border_width_all(2)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var styles := {"normal": normal, "hover": hover, "pressed": pressed, "disabled": disabled, "focus": focus}
		button.add_theme_stylebox_override(state, styles[state])
	button.add_theme_color_override("font_color", INK if primary else TEXT)
	button.add_theme_color_override("font_hover_color", INK if primary else TEXT)
	button.add_theme_color_override("font_pressed_color", INK if primary else TEXT)
	button.add_theme_color_override("font_disabled_color", Color("#829181"))
	button.add_theme_constant_override("outline_size", 0)
	button.add_theme_font_override("font", custom_font if custom_font != null else body_font())
	button.add_theme_font_size_override("font_size", 13)
	button.autowrap_mode = TextServer.AUTOWRAP_OFF
	button.clip_text = false

static func create_theme() -> Theme:
	var result := Theme.new()
	result.default_font = body_font()
	result.default_font_size = 14
	result.set_color("font_color", "Label", TEXT)
	result.set_color("font_color", "CheckButton", TEXT)
	for type in ["PanelContainer", "Panel", "PopupPanel"]:
		result.set_stylebox("panel", type, panel())
	var track := panel(Color("#25362d"), 0)
	track.set_border_width_all(0)
	track.content_margin_left = 3
	track.content_margin_right = 3
	result.set_stylebox("scroll", "VScrollBar", track)
	result.set_stylebox("scroll", "HScrollBar", track)
	var grab := panel(Color("#62775b"), 0)
	grab.set_border_width_all(0)
	result.set_stylebox("grabber", "VScrollBar", grab)
	result.set_stylebox("grabber_highlight", "VScrollBar", grab)
	result.set_stylebox("grabber_pressed", "VScrollBar", grab)
	var slider_track := panel(LINE, 0)
	slider_track.set_border_width_all(0)
	slider_track.content_margin_top = 2
	slider_track.content_margin_bottom = 2
	var slider_fill := slider_track.duplicate() as StyleBoxFlat
	slider_fill.bg_color = GREEN
	result.set_stylebox("slider", "HSlider", slider_track)
	result.set_stylebox("grabber_area", "HSlider", slider_fill)
	result.set_stylebox("grabber_area_highlight", "HSlider", slider_fill)
	result.set_icon("grabber", "HSlider", preload("res://assets/art/icons/slider_thumb.svg"))
	result.set_icon("grabber_highlight", "HSlider", preload("res://assets/art/icons/slider_thumb.svg"))
	result.set_icon("checked", "CheckButton", preload("res://assets/art/icons/switch_on.svg"))
	result.set_icon("unchecked", "CheckButton", preload("res://assets/art/icons/switch_off.svg"))
	result.set_stylebox("normal", "OptionButton", panel(SURFACE, 8))
	result.set_stylebox("hover", "OptionButton", panel(Color("#25382e"), 8))
	result.set_stylebox("pressed", "OptionButton", panel(INK, 8))
	result.set_color("font_color", "OptionButton", TEXT)
	return result

static func clean_text(value: String) -> String:
	value = value.replace("⚔", "†").replace("⚜", "●").replace("⚙", "◎").replace("❄", "✧")
	var replacements := {"🎯": "⌖", "⚒": "◇", "⚱": "◇", "💎": "◇", "💰": "●", "💀": "×", "☠": "×", "❤️": "♥", "💡": "·", "⚡": "ϟ", "✅": "✓", "📋": "·", "🌊": "≈", "🏃": "↗", "⏱️": "◷", "👑": "♜", "💥": "✦", "⚠️": "!", "🛡": "◇", "💨": "↗", "🩸": "♥", "🔥": "△", "🌀": "◎", "⏳": "◷", "💠": "◇", "🌲": "♠", "🌋": "△", "🏰": "♜", "⚰️": "◇"}
	for mark in replacements:
		value = value.replace(mark, replacements[mark])
	var plain := ""
	for index in value.length():
		var code := value.unicode_at(index)
		if code >= 0x1f000 and code <= 0x1faff:
			plain += "◇"
		elif code != 0xfe0f:
			plain += value[index]
	value = plain
	return value.replace("WAVE", "ONDA").replace("wave", "onda")

