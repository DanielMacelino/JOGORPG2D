extends Resource
class_name WaveData

@export var wave_number := 1
@export var duration := 32.0
@export var spawn_interval := 1.8
@export_range(0.0, 1.0, 0.01) var elite_chance := 0.0
@export var enemy_pool: Array[StringName] = []
@export var boss_id: StringName = &""
