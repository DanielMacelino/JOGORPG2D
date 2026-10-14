extends Resource
class_name EnemyData

@export var id: StringName
@export var display_name: String
@export var max_health: float = 30.0
@export var damage: float = 7.0
@export var defense: float = 0.0
@export var speed: float = 60.0
@export var xp: int = 4
@export var gold: int = 1
@export var attack_range: float = 34.0
@export var attack_style: StringName = &"melee"
@export var projectile_color: Color = Color("#c5a070")
@export var art_id: StringName = &""
@export var elite: bool = false
@export var boss: bool = false
@export_multiline var tips: String = ""
