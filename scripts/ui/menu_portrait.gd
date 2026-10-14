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
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	animation_time += delta
	queue_redraw()
func _draw() -> void:
	var portrait: Texture2D = PORTRAITS.get(class_id, PORTRAITS.warrior)
	var extent := portrait.get_size() * minf(size.x / portrait.get_width(), size.y / portrait.get_height())
	ANIMATOR.draw_character(self, class_id, {"time": animation_time}, Color.WHITE, extent, (size - extent) * 0.5)
