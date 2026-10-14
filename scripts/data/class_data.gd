extends Resource
class_name ClassData

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var accent: Color = Color.WHITE
@export var max_health: float = 100.0
@export var damage: float = 12.0
@export var defense: float = 0.0
@export var speed: float = 210.0
@export var attack_cooldown: float = 0.9
@export var attack_range: float = 240.0
@export var projectile_speed: float = 460.0
@export var attack_style: StringName = &"melee"
@export var threat_priority: float = 1.0
@export var splash_radius: float = 0.0
@export var starting_ability: StringName = &""
@export var starter_weapon: StringName = &""
@export var cost_gold: int = 0
@export var cost_crystals: int = 0
