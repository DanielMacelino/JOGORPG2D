extends Resource
class_name EquipmentData

@export var id: StringName
@export var display_name: String
@export var slot: StringName = &"relic"
@export var class_id: StringName = &""
@export var rarity: StringName = &"common"
@export_multiline var description: String
@export var stat: StringName = &"damage"
@export var stat_amount: float = 0.0
@export var region_id: StringName = &""
@export var bonuses: Dictionary = {}

@export var family_id: StringName = &""
@export var tier_index := 0
@export var required_difficulty := 0
@export var generated := false
