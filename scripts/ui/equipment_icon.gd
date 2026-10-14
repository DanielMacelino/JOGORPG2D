extends Control
## Shared, hand-drawn equipment art for slots and item rows.
const ART := preload("res://scripts/ui/wild_theme.gd")
const TEXTURES := {
	"sword": preload("res://assets/art/equipment/sword.svg"),
	"hammer": preload("res://assets/art/equipment/hammer.svg"),
	"bow": preload("res://assets/art/equipment/bow.svg"),
	"staff": preload("res://assets/art/equipment/staff.svg"),
	"roots": preload("res://assets/art/equipment/roots.svg"),
	"daggers": preload("res://assets/art/equipment/daggers.svg"),
	"helmet": preload("res://assets/art/equipment/helmet.svg"),
	"armor": preload("res://assets/art/equipment/armor.svg"),
	"boots": preload("res://assets/art/equipment/boots.svg"),
	"ring": preload("res://assets/art/equipment/ring.svg"),
	"amulet": preload("res://assets/art/equipment/amulet.svg")
}
const WEAPONS := {"warrior": "sword", "mage": "staff", "ranger": "bow", "assassin": "daggers", "druid": "roots", "paladin": "hammer"}
var item: EquipmentData
var slot := "weapon"
var class_id := "warrior"
var framed := false
var empty := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var category := str(item.slot) if item != null else slot
	var owner := str(item.class_id) if item != null and item.class_id != &"" else class_id
	var key: String = str(WEAPONS.get(owner, "sword")) if category == "weapon" else category
	var texture: Texture2D = TEXTURES.get(key, TEXTURES.amulet)
	var accent: Color = ART.RARITY_COLORS.get(str(item.rarity), ART.GOLD) if item != null else ART.GOLD
	var bounds := Rect2(Vector2.ONE, size - Vector2.ONE * 2.0)
	if framed:
		draw_style_box(ART.panel(Color("#11241e"), 0), bounds)
		draw_rect(bounds, Color(accent, 0.65), false, 1.0)
		draw_line(Vector2(1, 10), Vector2(1, 1), accent, 2.0, true)
		draw_line(Vector2(1, 1), Vector2(10, 1), accent, 2.0, true)
		draw_line(size - Vector2(10, 1), size - Vector2.ONE, accent, 2.0, true)
		draw_line(size - Vector2.ONE, size - Vector2(1, 10), accent, 2.0, true)
	var side := minf(size.x, size.y) * (0.88 if framed else 0.98)
	var extent := texture.get_size() * (side / maxf(texture.get_width(), texture.get_height()))
	draw_texture_rect(texture, Rect2((size - extent) * 0.5, extent), false, Color(0.8, 0.9, 0.83, 0.55) if empty else Color.WHITE)
