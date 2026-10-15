extends Control
const PORTRAITS := {
	"warrior": preload("res://assets/art/portraits/warrior.svg"),
	"mage": preload("res://assets/art/portraits/mage.svg"),
	"ranger": preload("res://assets/art/portraits/ranger.svg"),
	"assassin": preload("res://assets/art/portraits/assassin.svg"),
	"druid": preload("res://assets/art/portraits/druid.svg"),
	"paladin": preload("res://assets/art/portraits/paladin.svg")
}
const ANIMATOR := preload("res://scripts/world/character_animator.gd")
var animation_time := 0.0
var class_id := "warrior"
var weapon_id := ""
static func texture_for(owner: String, face: bool = false) -> Texture2D:
	return ANIMATOR.SHEET.atlas(owner, "face" if face else "portrait") if ANIMATOR.SHEET.has_class(owner) else PORTRAITS.get(owner, PORTRAITS.warrior)
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	texture_filter = TEXTURE_FILTER_NEAREST
	set_process(false)
func _draw() -> void:
	var portrait: Texture2D = texture_for(class_id)
	var extent := portrait.get_size() * minf(size.x / portrait.get_width(), size.y / portrait.get_height())
	draw_texture_rect(portrait, Rect2((size - extent) * 0.5, extent), false)
