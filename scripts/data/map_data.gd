extends Resource
class_name MapData

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var theme: StringName = &"forest"
@export var duration: float = 144.0
@export var boss_id: StringName = &"goblin_king"
@export var unlocked_by_default: bool = false
@export var enemy_pool: Array[StringName] = []
@export var elite_id: StringName = &"elite"
@export var difficulty: float = 1.0
@export var stage_index: int = 1
@export var accent: Color = Color("#a5b482")
@export var phase_number: int = 1
@export var difficulty_tier: int = 0
@export var phase_title: String = "Limiar"
@export var encounter: StringName = &"survival"
