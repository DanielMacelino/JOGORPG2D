extends Control
const PORTRAITS := {
	"archer": preload("res://assets/art/enemies/archer.svg"),
	"ash_hound": preload("res://assets/art/enemies/ash_hound.svg"),
	"bat": preload("res://assets/art/enemies/bat.svg"),
	"blood_mage": preload("res://assets/art/enemies/blood_mage.svg"),
	"bloodling": preload("res://assets/art/enemies/bloodling.svg"),
	"bogling": preload("res://assets/art/enemies/bogling.svg"),
	"bone_archer": preload("res://assets/art/enemies/bone_archer.svg"),
	"cinder_imp": preload("res://assets/art/enemies/cinder_imp.svg"),
	"crypt_wisp": preload("res://assets/art/enemies/crypt_wisp.svg"),
	"cult_archer": preload("res://assets/art/enemies/cult_archer.svg"),
	"dark_mage": preload("res://assets/art/enemies/dark_mage.svg"),
	"death_lord": preload("res://assets/art/enemies/death_lord.svg"),
	"dusk_knight": preload("res://assets/art/enemies/dusk_knight.svg"),
	"elite": preload("res://assets/art/enemies/elite.svg"),
	"ember_beetle": preload("res://assets/art/enemies/ember_beetle.svg"),
	"fallen_guard": preload("res://assets/art/enemies/fallen_guard.svg"),
	"fire_witch": preload("res://assets/art/enemies/fire_witch.svg"),
	"frost_brute": preload("res://assets/art/enemies/frost_brute.svg"),
	"frost_guardian": preload("res://assets/art/enemies/frost_guardian.svg"),
	"frost_shaman": preload("res://assets/art/enemies/frost_shaman.svg"),
	"frost_spider": preload("res://assets/art/enemies/frost_spider.svg"),
	"goblin": preload("res://assets/art/enemies/goblin.svg"),
	"goblin_king": preload("res://assets/art/enemies/goblin_king.svg"),
	"ice_archer": preload("res://assets/art/enemies/ice_archer.svg"),
	"ice_slime": preload("res://assets/art/enemies/ice_slime.svg"),
	"lava_lord": preload("res://assets/art/enemies/lava_lord.svg"),
	"mage": preload("res://assets/art/enemies/mage.svg"),
	"mire_queen": preload("res://assets/art/enemies/mire_queen.svg"),
	"mire_titan": preload("res://assets/art/enemies/mire_titan.svg"),
	"mire_toad": preload("res://assets/art/enemies/mire_toad.svg"),
	"molten_knight": preload("res://assets/art/enemies/molten_knight.svg"),
	"obsidian_guard": preload("res://assets/art/enemies/obsidian_guard.svg"),
	"reed_stalker": preload("res://assets/art/enemies/reed_stalker.svg"),
	"skeleton": preload("res://assets/art/enemies/skeleton.svg"),
	"slime": preload("res://assets/art/enemies/slime.svg"),
	"snow_wolf": preload("res://assets/art/enemies/snow_wolf.svg"),
	"spore_shaman": preload("res://assets/art/enemies/spore_shaman.svg"),
	"swamp_leech": preload("res://assets/art/enemies/swamp_leech.svg"),
	"vampire_king": preload("res://assets/art/enemies/vampire_king.svg"),
	"wolf": preload("res://assets/art/enemies/wolf.svg"),
	"zombie": preload("res://assets/art/enemies/zombie.svg")
}
var enemy_id := "goblin"
var known := true
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
func _draw() -> void:
	var texture: Texture2D = PORTRAITS.get(enemy_id, PORTRAITS.goblin)
	var extent := texture.get_size() * minf(size.x / texture.get_width(), size.y / texture.get_height())
	draw_texture_rect(texture, Rect2((size - extent) * 0.5, extent), false, Color.WHITE if known else Color(0.3, 0.4, 0.3, 0.5))
